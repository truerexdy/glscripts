#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
# Exit if any command in a pipeline fails.
# Treat unset variables as an error.
set -euo pipefail

# Function to check if the script is run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "This script must be run as root."
        exit 1
    fi
}

# Function to get and validate the directory path
get_directory_path() {
    local dir=""
    while true; do
        read -rp "Enter the full path of the directory to share: " dir

        if [ -z "$dir" ]; then
            echo "Directory path cannot be empty."
            continue
        fi

        # Resolve potential symlinks and get absolute path
        local resolved_dir
        resolved_dir=$(realpath -q "$dir" || echo "$dir")

        if [ ! -d "$resolved_dir" ]; then
            read -rp "Directory '$resolved_dir' doesn't exist. Create it? (y/n): " create
            if [[ "$create" =~ ^[Yy]$ ]]; then
                mkdir -p "$resolved_dir"
                if [ $? -eq 0 ]; then
                    chmod 775 "$resolved_dir" # Set appropriate permissions
                    echo "Created directory: $resolved_dir"
                    dir="$resolved_dir" # Use the resolved path
                    break
                else
                    echo "Failed to create directory: $resolved_dir. Please check permissions."
                    continue
                fi
            else
                echo "Directory '$resolved_dir' does not exist and was not created. Cannot share."
                exit 1
            fi
        else
             dir="$resolved_dir" # Use the resolved path if it exists
             break
        fi
    done
    echo "$dir" # Output the validated and resolved directory path
}

# Function to add the share to smb.conf
add_samba_share() {
    local dir="$1"
    local smbuser="smbuser" # Assuming the Samba user is 'smbuser' as per the initial script

    echo "Adding share for directory: $dir"

    if [ ! -f /etc/samba/smb.conf ]; then
        echo "Error: Samba configuration file /etc/samba/smb.conf not found."
        echo "Please run the initial setup script first."
        exit 1
    fi

    local share_name=$(basename "$dir")
    # Sanitize share name
    share_name=$(echo "$share_name" | sed 's/[^a-zA-Z0-9_-]/_/g')
    if [ -z "$share_name" ]; then
         share_name="shared_$(date +%s)" # Fallback name if basename is empty or sanitization fails
         echo "Warning: Could not determine a valid share name from directory. Using '$share_name'."
    fi

    # Check if a share with this name already exists (basic check)
    if grep -q "\[$share_name\]" /etc/samba/smb.conf; then
        echo "Error: A Samba share named '$share_name' already exists."
        echo "Please choose a different directory or manually edit /etc/samba/smb.conf."
        exit 1
    fi

    # Append the new share configuration block
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

    echo "Added share [$share_name] to /etc/samba/smb.conf"

    # Ensure correct ownership and permissions for the Samba user
    if id "$smbuser" &> /dev/null; then
        chown -R "$smbuser":"$smbuser" "$dir"
        chmod -R 775 "$dir"
        echo "Set ownership and permissions for $dir to user '$smbuser'."
    else
        echo "Warning: Samba user '$smbuser' not found. Skipping ownership/permissions change."
        echo "You may need to manually set ownership and permissions for '$dir'."
    fi

    echo "Restarting Samba services..."
    systemctl restart smb nmb
    echo "Samba services restarted."
    echo "New share [$share_name] for directory '$dir' should now be accessible."
}

# Main execution
main() {
    check_root

    echo "=== Add New Samba Share ==="

    local directory_to_share
    directory_to_share=$(get_directory_path)

    add_samba_share "$directory_to_share"

    echo "Process completed."
}

main

exit 0
