#!/bin/bash

check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo "Please run as root"
        exit 1
    fi
}

install_packages() {
    echo "Updating package lists..."
    pacman -Sy

    echo "Installing required packages..."
    pacman -S --noconfirm openssh samba ufw
}

configure_ssh() {
    echo "Configuring SSH server..."
    
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    
    ufw allow ssh
    
    systemctl enable sshd
    systemctl restart sshd
}

get_directories() {
    local dirs=()
    while true; do
        read -p "Enter directory path to share (or 'done' to finish): " dir
        
        if [ "$dir" = "done" ]; then
            break
        fi
        
        if [ ! -d "$dir" ]; then
            read -p "Directory doesn't exist. Create it? (y/n): " create
            if [ "$create" = "y" ]; then
                mkdir -p "$dir"
                chmod 755 "$dir"
            else
                continue
            fi
        fi
        
        dirs+=("$dir")
    done
    echo "${dirs[@]}"
}

configure_samba() {
    local directories=("$@")
    local samba_password
    
    if [ -f /etc/samba/smb.conf ]; then
        cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
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
    
    read -s -p "Enter password for Samba shares: " samba_password
    echo
    read -s -p "Confirm password: " samba_password_confirm
    echo
    
    if [ "$samba_password" != "$samba_password_confirm" ]; then
        echo "Passwords do not match!"
        exit 1
    fi
    
    smbuser="smbuser"
    useradd -M -s /sbin/nologin "$smbuser"
    echo -e "$samba_password\n$samba_password" | smbpasswd -a "$smbuser"
    
    for dir in "${directories[@]}"; do
        share_name=$(basename "$dir")
        cat >> /etc/samba/smb.conf << EOF

[$share_name]
path = $dir
valid users = $smbuser
read only = no
browsable = yes
create mask = 0644
directory mask = 0755
force user = $smbuser
force group = $smbuser
EOF
        
        chown "$smbuser":"$smbuser" "$dir"
        chmod 755 "$dir"
    done
    
    mkdir -p /var/lib/samba/usershares
    
    ufw allow samba
    
    systemctl enable smb nmb
    systemctl restart smb nmb
}

setup_firewall() {
    echo "Setting up firewall..."
    systemctl enable ufw
    ufw default deny incoming
    ufw default allow outgoing
    ufw enable
}

main() {
    check_root
    
    echo "=== SSH and Samba Server Setup for Arch Linux ==="
    
    install_packages
    
    configure_ssh
    
    echo "Please specify directories to share via Samba"
    directories=($(get_directories))
    
    if [ ${#directories[@]} -eq 0 ]; then
        echo "No directories specified. Exiting..."
        exit 1
    fi
    
    configure_samba "${directories[@]}"
    
    setup_firewall
    
    echo "Setup completed successfully!"
    echo "SSH server is running and configured"
    echo "Samba shares have been created for the following directories:"
    printf '%s\n' "${directories[@]}"
    echo
    echo "Important notes:"
    echo "1. SSH is accessible on port 22"
    echo "2. Samba shares are accessible using the username 'smbuser'"
    echo "3. Use the password you provided during setup to access Samba shares"
    echo "4. The firewall is configured to allow both SSH and Samba access"
}

main
