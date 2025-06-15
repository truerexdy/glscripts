#!/bin/bash
set -euo pipefail

SYSTEMD_DIR=/etc/systemd/system

function list_automounts() {
    echo "Existing SMB automounts:"
    systemctl list-unit-files --type=automount | grep '\.automount' | grep -E 'mnt-.+\.automount' || echo "No SMB automounts found."
    echo
}

function sanitize_name() {
    local mp="$1"
    mp="${mp#/}"
    mp="${mp//\//-}"
    echo "$mp"
}

function enable_automount() {
    read -r -p "SMB server (e.g. 192.168.1.10): " server
    read -r -p "SMB share name (e.g. share): " share
    read -r -p "Local mount point (full path, e.g. /mnt/share): " mount_point
    if [[ ! "$mount_point" =~ ^/ ]]; then
        echo "Mount point must be an absolute path"
        return
    fi
    read -r -p "SMB username: " smb_user
    read -r -s -p "SMB password: " smb_pass
    echo
    read -r -p "Local user to own mounted files: " local_user
    read -r -p "Local group to own mounted files: " local_group

    if ! id "$local_user" &>/dev/null; then
        echo "Local user does not exist."
        return
    fi
    if ! getent group "$local_group" &>/dev/null; then
        echo "Local group does not exist."
        return
    fi

    local uid gid unit_name
    uid=$(id -u "$local_user")
    gid=$(getent group "$local_group" | cut -d: -f3)

    unit_name="mnt-$(sanitize_name "$mount_point")"
    local mount_unit="$unit_name.mount"
    local automount_unit="$unit_name.automount"
    local credentials_file="/root/.smbcredentials_${unit_name}"

    mkdir -p "$mount_point"
    chmod 755 "$mount_point"

    cat > "$credentials_file" <<EOF
username=$smb_user
password=$smb_pass
EOF
    chmod 600 "$credentials_file"

    cat > "$SYSTEMD_DIR/$mount_unit" <<EOF
[Unit]
Description=Mount SMB Share //$server/$share
After=network-online.target
Wants=network-online.target

[Mount]
What=//$server/$share
Where=$mount_point
Type=cifs
Options=credentials=$credentials_file,uid=$uid,gid=$gid,file_mode=0664,dir_mode=0775,_netdev

[Install]
WantedBy=multi-user.target
EOF

    cat > "$SYSTEMD_DIR/$automount_unit" <<EOF
[Unit]
Description=Automount SMB Share //$server/$share

[Automount]
Where=$mount_point

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now "$automount_unit"

    echo "Automount enabled for //$server/$share at $mount_point"
}

function disable_automount() {
    read -r -p "Enter mount point to disable automount (full path, e.g. /mnt/share): " mount_point
    if [[ ! "$mount_point" =~ ^/ ]]; then
        echo "Mount point must be an absolute path"
        return
    fi

    local unit_name
    unit_name="mnt-$(sanitize_name "$mount_point")"
    local mount_unit="$unit_name.mount"
    local automount_unit="$unit_name.automount"
    local credentials_file="/root/.smbcredentials_${unit_name}"

    if systemctl is-active --quiet "$automount_unit"; then
        systemctl stop "$automount_unit"
    fi
    systemctl disable "$automount_unit" || true
    systemctl daemon-reload

    rm -f "$SYSTEMD_DIR/$mount_unit" "$SYSTEMD_DIR/$automount_unit" "$credentials_file"

    echo "Automount and mount units for $mount_point removed."
}

while true; do
    cat <<EOF
SMB Automount Manager
1) Show existing SMB automount shares
2) Enable/add automount to a share
3) Disable/remove automount from a share
4) Exit
EOF
    read -r -p "Select option: " opt
    case $opt in
        1) list_automounts ;;
        2) enable_automount ;;
        3) disable_automount ;;
        4) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
    echo
done
