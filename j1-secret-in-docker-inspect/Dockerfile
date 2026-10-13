FROM postgres:16-alpine

# The password is passed in at build time so the image is ready to run.
ARG DB_PASSWORD
ENV PGPASSWORD=${DB_PASSWORD}

COPY check.sh /usr/local/bin/check.sh
RUN chmod +x /usr/local/bin/check.sh

CMD ["/usr/local/bin/check.sh"]
