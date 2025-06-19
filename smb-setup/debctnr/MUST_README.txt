IMPORTANT
MUST CREATE A NAMED VOLUME BEFORE MOUNTING IT, BLIND MOUNT IS NOT SAFE AND DATA LOSS CAN OCCUR

1. Add users with this
    sudo useradd username
    sudo smbpasswd -a username

2. Add users to smbshare group
    sudo groupadd sambashare
    sudo usermod -a -G sambashare user

3. Give permission to dir 
    sudo chown nobody:sambashare /app/nas/share_name
    sudo chmod 2775 /app/nas/share_name

Command to create container
docker run -it --name temp -p 139:139 -p 445:445 -v nas_volume:/app/nas/ -v ./configs/:/app/config/ mysmb

THE ./config containing the config of the required shares must be mounted to /app/config/and the dirs for shares must be created.
