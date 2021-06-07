FROM traefik:v2.4.8
RUN apk -u add openssh-client
RUN mkdir -p /root/.ssh && ln -s /run/secrets/root_private_key /root/.ssh/id_rsa
