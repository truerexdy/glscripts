#!/bin/bash
set -e

install_samba() {
    apt update -y
    apt install -y samba acl

    systemctl enable smbd nmbd
    systemctl start smbd nmbd
}

backup_smb_conf() {
    cp /etc/samba/smb.conf "/etc/samba/smb.conf.bak.$(date +%s)"
}

create_groups() {
    getent group full_smb || groupadd full_smb
    getent group read_smb || groupadd read_smb
}

add_smb_user() {
    while true; do
        read -r -p "Add SMB user? (y/n): " add_user
        [ "$add_user" != "y" ] && break

        read -r -p "Enter SMB username: " smb_user
        
        if ! id "$smb_user" &>/dev/null; then
            adduser --system --no-create-home --shell /usr/sbin/nologin "$smb_user"
        fi

        smbpasswd -a "$smb_user"

        read -r -p "Full access? (y/n): " full_access
        if [ "$full_access" == "y" ]; then
            usermod -aG full_smb "$smb_user"
        else
            usermod -aG read_smb "$smb_user"
        fi
    done
}

create_share() {
    read -r -p "Enter share name: " share

    local share_dir
    while true; do
        read -r -p "Use default path /srv/samba/$share? (y/n/exit): " use_default
        case $use_default in
            y) share_dir="/srv/samba/$share"; break;;
            n)
                read -r -p "Enter full custom directory path: " custom_dir
                if [ -d "$custom_dir" ] || mkdir -p "$custom_dir"; then
                    share_dir="$custom_dir"
                    break
                else
                    echo "Invalid directory path or unable to create. Try again."
                fi
                ;;
            exit) echo "Aborting share creation."; return;;
            *) echo "Invalid input. Please enter y, n, or exit.";;
        esac
    done

    local group_rw="${share}_rw"
    local group_ro="${share}_ro"

    mkdir -p "$share_dir"
    
    getent group "$group_rw" || groupadd "$group_rw"
    getent group "$group_ro" || groupadd "$group_ro"

    chown -R root:"$group_rw" "$share_dir"
    chmod -R 2770 "$share_dir"

    setfacl -m g:"$group_ro":rx "$share_dir"
    setfacl -R -m g:"$group_ro":rx "$share_dir"

    backup_smb_conf

    cat <<EOL >> /etc/samba/smb.conf

[$share]
path = $share_dir
browseable = yes
writable = yes
valid users = @${group_rw} @${group_ro}
read only = no
write list = @${group_rw}
force group = ${group_rw}
create mask = 0660
directory mask = 0770
EOL

    systemctl restart smbd nmbd
    echo "Share '$share' created and configured."

    while true; do
        read -r -p "Add SMB user to '$share' share? (y/n): " add_user_to_share
        [ "$add_user_to_share" != "y" ] && break

        read -r -p "Enter SMB username to add to this share: " smb_user_to_add
        
        if ! id "$smb_user_to_add" &>/dev/null; then
            adduser --system --no-create-home --shell /usr/sbin/nologin "$smb_user_to_add"
            smbpasswd -a "$smb_user_to_add"
        fi

        read -r -p "Access level for '$smb_user_to_add' (rw/ro) for share '$share': " access_level
        if [ "$access_level" == "rw" ]; then
            usermod -aG "$group_rw" "$smb_user_to_add"
        elif [ "$access_level" == "ro" ]; then
            usermod -aG "$group_ro" "$smb_user_to_add"
        else
            echo "Invalid access level. Skipping user addition to share."
        fi
    done
}

main() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root. Please use sudo."
        exit 1
    fi

    install_samba
    create_groups
    create_share

    echo "SMB setup complete."
    echo "Please ensure your firewall (e.g., UFW) allows Samba traffic (ports 139, 445)."
}

main
