#!/bin/bash
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo "Please run as root"
        exit 1
    fi
}
install_packages() {
    echo "Updating package lists..."
    apt-get update

    echo "Installing required packages..."
    apt-get install -y openssh-server samba ufw
}
configure_ssh() {
    echo "Configuring SSH server..."
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    ufw allow ssh
    systemctl restart ssh
    systemctl enable ssh
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
    cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
    cat > /etc/samba/smb.conf << EOF
[global]
workgroup = WORKGROUP
server string = Samba Server
security = user
map to guest = never
encrypt passwords = true
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
EOF
        chown "$smbuser":"$smbuser" "$dir"
        chmod 755 "$dir"
    done
    ufw allow samba
    systemctl restart smbd nmbd
    systemctl enable smbd nmbd
}
main() {
    check_root
    echo "=== SSH and Samba Server Setup ==="
    install_packages
    configure_ssh
    echo "Please specify directories to share via Samba"
    directories=($(get_directories))
    if [ ${#directories[@]} -eq 0 ]; then
        echo "No directories specified. Exiting..."
        exit 1
    fi
    configure_samba "${directories[@]}"
    echo "Setup completed successfully!"
    echo "SSH server is running and configured"
    echo "Samba shares have been created for the following directories:"
    printf '%s\n' "${directories[@]}"
    echo "Please ensure your firewall (ufw) is enabled: 'ufw enable'"
}
main
