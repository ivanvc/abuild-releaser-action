FROM alpinelinux/build-base:latest
ENTRYPOINT ["/entrypoint.sh"]
USER root
COPY --from=ivan/tpl:latest /bin/tpl .
COPY entrypoint.sh index.html.tpl /
