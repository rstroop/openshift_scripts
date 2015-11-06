FROM registry

ENV http_proxy http://squid.internal.secureworks.net:3128
ENV https_proxy http://squid.internal.secureworks.net:3128
ENV no_proxy '.secureworks.net,.secureworks.com,.secureworkslab.com,.secureworkslab.net,.internal'

ADD ca-bundle.crt /usr/local/share/ca-certificates/ca-bundle.crt
RUN update-ca-certificates
