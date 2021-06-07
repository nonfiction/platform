FROM traefik:v2.4.8
RUN apk -u add openssh-client
RUN mkdir -p /root/.ssh
RUN sed '$d' /entrypoint.sh
RUN echo 'while :; do' >> /entrypoint.sh
RUN echo '[ -f /root/.ssh/id_rsa ] && break' >> /entrypoint.sh
RUN echo '[ -f /run/secrets/root_private_key ] && cp /run/secrets/root_private_key /root/.ssh/id_rsa && chmod 400 /root/.ssh/id_rsa' >> /entrypoint.sh
RUN echo 'sleep 1' >> /entrypoint.sh
RUN echo 'done' >> /entrypoint.sh
RUN echo 'exec "$@"' >> /entrypoint.sh
