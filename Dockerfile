FROM traefik:v2.4.8
RUN apk -u add openssh-client && mkdir -p /root/.ssh
RUN echo 'cd /root/.ssh && while :;do [ -f id_rsa ]&&break;[ -f /run/secrets/root_private_key ]&&cp /run/secrets/root_private_key id_rsa&&chmod 400 id_rsa;sleep 1;done' >> /entrypoint.sh
