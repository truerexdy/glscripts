FROM debian:latest

RUN apt-get update -y && \
    apt-get install -y samba acl && \
    rm -rf /var/lib/apt/lists/*

COPY share_conf.txt next_steps.txt /app/

RUN mkdir /app/nas/

WORKDIR /app/

EXPOSE 139 445

CMD bash -c "/usr/sbin/nmbd --foreground & /usr/sbin/smbd --foreground & wait -n"
