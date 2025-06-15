#!/bin/bash
set -e

backup_smb_conf() {
    cp /etc/samba/smb.conf "/etc/samba/smb.conf.bak.$(date +%s)"
}

delete_share() {
    while true; do
        read -r -p "Enter share name to delete: " share
        grep -q "^\[$share\]" /etc/samba/smb.conf || { echo "Share not found."; return; }

        read -r -p "Confirm delete share $share? This will remove smb.conf entry, groups, and directory (y/n): " confirm
        [ "$confirm" != "y" ] && return

        share_dir="/srv/samba/$share"

        read -r -p "Delete share directory? (y/n): " del_dir
        if [ "$del_dir" == "y" ]; then
            read -r -p "Enter share directory path to delete or press enter for $share_dir: " dir_path
            dir_path=${dir_path:-$share_dir}
            rm -rf "$dir_path"
            echo "Deleted directory $dir_path"
        fi

        backup_smb_conf
        sed -i "/^\[$share\]/,/^$/d" /etc/samba/smb.conf

        group_rw="${share}_rw"
        group_ro="${share}_ro"
        groupdel "$group_rw" 2>/dev/null || true
        groupdel "$group_ro" 2>/dev/null || true

        systemctl restart smb nmb
        echo "Share $share deleted."
        break
    done
}

add_smb_user() {
    while true; do
        read -r -p "Enter SMB username to add: " smb_user
        id "$smb_user" &>/dev/null || useradd -M "$smb_user"
        smbpasswd -a "$smb_user"

        read -r -p "Add $smb_user to which share groups? (comma-separated share names, or 'exit'): " shares
        [ "$shares" == "exit" ] && break

        IFS=',' read -ra share_list <<< "$shares"
        for share in "${share_list[@]}"; do
            share=$(echo "$share" | xargs)
            group_rw="${share}_rw"
            group_ro="${share}_ro"

            for g in "$group_rw" "$group_ro"; do
                if getent group "$g" > /dev/null; then
                    read -r -p "Add $smb_user to group $g? (y/n): " yn
                    if [ "$yn" == "y" ]; then
                        usermod -aG "$g" "$smb_user"
                        echo "Added $smb_user to $g"
                    fi
                else
                    echo "Group $g does not exist."
                fi
            done
        done
    done
}

remove_smb_user() {
    while true; do
        read -r -p "Enter SMB username to remove (or 'exit' to quit): " smb_user
        [ "$smb_user" == "exit" ] && break
        id "$smb_user" &>/dev/null || { echo "User $smb_user does not exist."; continue; }

        read -r -p "Remove SMB user $smb_user completely? (y/n): " complete
        if [ "$complete" == "y" ]; then
            userdel "$smb_user"
            smbpasswd -x "$smb_user"
            echo "User $smb_user deleted."
            continue
        fi

        read -r -p "Remove from specific share groups? (y/n): " spec
        if [ "$spec" == "y" ]; then
            read -r -p "Enter share names (comma-separated): " shares
            IFS=',' read -ra share_list <<< "$shares"
            for share in "${share_list[@]}"; do
                share=$(echo "$share" | xargs)
                for g in "${share}_rw" "${share}_ro"; do
                    if getent group "$g" > /dev/null; then
                        gpasswd -d "$smb_user" "$g" && echo "Removed $smb_user from $g"
                    else
                        echo "Group $g does not exist."
                    fi
                done
            done
        fi
    done
}

create_share() {
    while true; do
        read -r -p "Enter share name: " share
        share_dir="/srv/samba/$share"

        while true; do
            read -r -p "Use default path $share_dir? (y/n/exit): " use_default
            case $use_default in
                y) break ;;
                n)
                    read -r -p "Enter full custom directory path: " custom_dir
                    if [ -d "$custom_dir" ] || mkdir -p "$custom_dir"; then
                        share_dir="$custom_dir"
                        break
                    else
                        echo "Invalid directory path. Try again."
                    fi
                    ;;
                exit) return ;;
                *) echo "Invalid input." ;;
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
        if grep -q "^\[$share\]" /etc/samba/smb.conf; then
            echo "Share $share already exists in smb.conf"
        else
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
        fi

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
        break
    done
}

menu() {
    while true; do
        echo "SMB Maintenance Menu:"
        echo "1) Create Share"
        echo "2) Delete Share"
        echo "3) Add SMB User"
        echo "4) Remove SMB User"
        echo "5) Exit"
        read -r -p "Select option: " opt
        case $opt in
            1) create_share ;;
            2) delete_share ;;
            3) add_smb_user ;;
            4) remove_smb_user ;;
            5) exit 0 ;;
            *) echo "Invalid option." ;;
        esac
    done
}

menu
