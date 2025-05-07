#!/bin/bash

set -euo pipefail

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit 1
    fi
}

install_packages() {
    echo "Updating package lists and installing required packages..."
    pacman -Syu --noconfirm
    pacman -S --noconfirm openssh samba ufw

    if ! command -v sshd &> /dev/null || ! command -v smbd &> /dev/null || ! command -v ufw &> /dev/null; then
        echo "Required packages did not install correctly. Exiting."
        exit 1
    fi
}

configure_ssh() {
    echo "Configuring SSH server..."

    if [ ! -f /etc/ssh/sshd_config ]; then
        echo "Error: SSH server configuration file not found!"
        exit 1
    fi

    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

    # Disable root login with password, allow password authentication for other users
    sed -i 's/^#*PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config

    ufw allow ssh

    systemctl enable sshd
    systemctl restart sshd
    echo "SSH server configured and restarted."
}

get_directories() {
    local dirs=()
    echo "Enter directory paths to share via Samba (type 'done' to finish):"
    while true; do
        read -rp "Share directory path: " dir

        if [ "$dir" = "done" ]; then
            break
        fi

        if [ ! -d "$dir" ]; then
            read -rp "Directory '$dir' doesn't exist. Create it? (y/n): " create
            if [[ "$create" =~ ^[Yy]$ ]]; then
                mkdir -p "$dir"
                chmod 755 "$dir"
                echo "Created directory: $dir"
            else
                echo "Skipping directory: $dir"
                continue
            fi
        fi

        # Check if directory creation was successful if it was attempted
        if [ -d "$dir" ]; then
            dirs+=("$dir")
        else
             echo "Failed to create directory: $dir. Skipping."
        fi
    done
    echo "${dirs[@]}"
}

configure_samba() {
    local directories=("$@")
    local samba_password
    local samba_password_confirm

    echo "Configuring Samba server..."

    if [ -f /etc/samba/smb.conf ]; then
        cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
        echo "Backed up existing smb.conf to smb.conf.backup"
    fi

    cat > /etc/samba/smb.conf << EOF
[global]
workgroup = WORKGROUP
server string = Samba Server
security = user
map to guest = never
encrypt passwords = true
log file = /var/log/samba/%m.log
max log size = 50
logging = file
dns proxy = no
EOF

    echo "Set password for the Samba user ('smbuser'). This is separate from system user passwords."
    while true; do
        read -s -rp "Enter Samba password: " samba_password
        echo
        read -s -rp "Confirm Samba password: " samba_password_confirm
        echo

        if [ "$samba_password" = "$samba_password_confirm" ]; then
            break
        else
            echo "Passwords do not match. Please try again."
        fi
    done

    local smbuser="smbuser"
    if ! id "$smbuser" &> /dev/null; then
        useradd -M -s /sbin/nologin "$smbuser"
        echo "Created system user '$smbuser' for Samba."
    else
        echo "System user '$smbuser' already exists."
    fi

    # Set the Samba password for the user
    echo -e "$samba_password\n$samba_password" | smbpasswd -a "$smbuser"
    if [ $? -eq 0 ]; then
        echo "Samba password set for user '$smbuser'."
    else
        echo "Error setting Samba password for user '$smbuser'. Exiting."
        exit 1
    fi

    for dir in "${directories[@]}"; do
        local share_name=$(basename "$dir")
        # Sanitize share name
        share_name=$(echo "$share_name" | sed 's/[^a-zA-Z0-9_-]/_/g')
        if [ -z "$share_name" ]; then
             share_name="shared_$(date +%s)" # Fallback name if basename is empty or sanitization fails
        fi

        cat >> /etc/samba/smb.conf << EOF

[$share_name]
path = $dir
valid users = $smbuser
read only = no
browsable = yes
create mask = 0664
directory mask = 0775
force user = $smbuser
force group = $smbuser
EOF
        echo "Added share [$share_name] for directory $dir to smb.conf"

        # Ensure correct ownership and permissions for the Samba user
        chown -R "$smbuser":"$smbuser" "$dir"
        chmod -R 775 "$dir"
        echo "Set ownership and permissions for $dir"
    done

    # This directory is for user shares, not needed for this config but doesn't hurt
    # mkdir -p /var/lib/samba/usershares

    ufw allow samba

    systemctl enable smb nmb
    systemctl restart smb nmb
    echo "Samba server configured and restarted."
}

setup_firewall() {
    echo "Setting up firewall (UFW)..."
    systemctl enable ufw
    ufw default deny incoming
    ufw default allow outgoing
    ufw enable
    echo "Firewall enabled. Default incoming: deny, Default outgoing: allow."
}

main() {
    check_root

    echo "=== SSH and Samba Server Setup for Arch Linux ==="

    install_packages

    configure_ssh

    echo "--- Samba Share Configuration ---"
    directories=($(get_directories))

    if [ ${#directories[@]} -eq 0 ]; then
        echo "No directories specified for Samba shares. Skipping Samba configuration."
    else
        configure_samba "${directories[@]}"
    fi

    setup_firewall

    echo "Setup completed successfully!"
    echo "SSH server is running and configured."
    if [ ${#directories[@]} -gt 0 ]; then
        echo "Samba shares have been created for the following directories:"
        printf ' - %s\n' "${directories[@]}"
        echo
        echo "Important notes:"
        echo "1. SSH is accessible on port 22."
        echo "2. Samba shares are accessible using the username 'smbuser'."
        echo "3. Use the Samba password you provided during setup to access shares."
        echo "4. The firewall (UFW) is configured to allow SSH and Samba access."
    else
        echo "Samba configuration was skipped as no directories were specified."
        echo
        echo "Important notes:"
        echo "1. SSH is accessible on port 22."
        echo "2. The firewall (UFW) is configured to allow SSH access."
    fi

    echo "================================================"
}

main

exit 0
