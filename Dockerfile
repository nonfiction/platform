FROM traefik:v2.4.8
RUN apk -u add openssh-client
RUN mkdir -p /root/.ssh && ln -s /run/secrets/root_private_key /root/.ssh/id_rsa
RUN echo "src=/run/secrets/root_private_key;dest=/root/.ssh/id_rsa;while :;do [ -f $dest ]&&break;[ -f $src ]&&cp $src $dest&&chmod 400 $dest;sleep 1;done" >> /entrypoint.sh
