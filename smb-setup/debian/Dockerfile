FROM debian:latest

RUN apt update -y && \
    apt install -y samba acl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY smb_maintenance.sh smb_setup.sh /app/

RUN chmod +x /app/*.sh

EXPOSE 139 445

CMD ["bash", "-c", "/usr/sbin/nmbd --debug-stdout --no-process-group --log-stdout & /usr/sbin/smbd --debug-stdout --no-process-group --log-stdout && wait -n"]

