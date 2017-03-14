FROM nginx:stable
MAINTAINER Jeffrey Jen <yihungjen@gmail.com>

# Install wget and install/updates certificates
RUN apt-get update \
 && apt-get install -y -q --no-install-recommends \
    ca-certificates \
    wget \
 && apt-get clean \
 && rm -r /var/lib/apt/lists/*

# Configure Nginx and apply fix for very long server names
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && sed -i 's/^http {/&\n    server_names_hash_bucket_size 128;/g' /etc/nginx/nginx.conf

# Install Forego
ADD https://github.com/jwilder/forego/releases/download/v0.16.1/forego /usr/local/bin/forego
RUN chmod u+x /usr/local/bin/forego

ENV FOREGO_VERSION 0.16.1

# Install Confd
ADD https://github.com/kelseyhightower/confd/releases/download/v0.14.0/confd-0.14.0-linux-amd64 /usr/local/bin/confd
RUN chmod u+x /usr/local/bin/confd

ENV CONFD_VERSION 0.14.0

# Setup placeholder for confd target
RUN touch /etc/nginx/proxy.conf /etc/nginx/default.conf

COPY confd-vhost/ /app/confd-vhost/
COPY confd-by-path/ /app/confd-by-path/
COPY Procfile /app/
WORKDIR /app/

VOLUME /etc/nginx/certs

ENV DEVOPS_COND_DIR=confd-vhost \
  DEVOPS_CONFIG_ROOT=devops \
  DEVOPS_CONFD_ARGS="-watch -backend etcd -node http://localhost:2379"

CMD ["forego", "start", "-r"]
