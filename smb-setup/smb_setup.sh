#!/bin/bash
set -e

install_samba() {
    pacman -Sy --noconfirm samba
    systemctl enable smb nmb
    systemctl start smb nmb
}

backup_smb_conf() {
    cp /etc/samba/smb.conf "/etc/samba/smb.conf.bak.$(date +%s)"
}

create_groups() {
    groupadd -f full_smb
    groupadd -f read_smb
}

add_smb_user() {
    while true; do
        read -r -p "Add SMB user? (y/n): " add_user
        [ "$add_user" != "y" ] && break

        read -r -p "Enter SMB username: " smb_user
        id "$smb_user" &>/dev/null || useradd -M "$smb_user"
        smbpasswd -a "$smb_user"

        echo "Assign to groups:"
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
                    echo "Invalid directory path. Try again."
                fi
                ;;
            exit) echo "Aborting share creation."; return;;
            *) echo "Invalid input.";;
        esac
    done

    group_rw="${share}_rw"
    group_ro="${share}_ro"

    mkdir -p "$share_dir"
    groupadd -f "$group_rw"
    groupadd -f "$group_ro"

    chown -R root:"$group_rw" "$share_dir"
    chmod -R 770 "$share_dir"

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
EOL

    systemctl restart smb nmb
    echo "Share $share created."

    while true; do
        read -r -p "Add SMB user to $share? (y/n): " add_user
        [ "$add_user" != "y" ] && break

        read -r -p "Enter SMB username: " smb_user
        id "$smb_user" &>/dev/null || useradd -M "$smb_user"
        smbpasswd -a "$smb_user"

        read -r -p "Access level? (rw/ro): " access
        if [ "$access" == "rw" ]; then
            usermod -aG "$group_rw" "$smb_user"
        else
            usermod -aG "$group_ro" "$smb_user"
        fi
    done
}

main() {
    echo "Starting SMB setup..."

    install_samba
    create_groups
    create_share
    add_smb_user

    echo "SMB setup complete."
}

main
