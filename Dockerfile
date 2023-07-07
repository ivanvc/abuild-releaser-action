FROM alpinelinux/build-base:latest
ENTRYPOINT ["/entrypoint.sh"]
USER root
COPY entrypoint.sh /entrypoint.sh
