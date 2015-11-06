FROM openshift3/ruby-20-rhel7

ENV http_proxy=http://squid.internal.secureworks.net:3128
ENV https_proxy=http://squid.internal.secureworks.net:3128

USER root

RUN yum -y install ca-certificates

RUN curl -sk https://catool.internal.secureworks.net/public/cas/3.cer >> /etc/pki/tls/certs/ca-bundle.crt RUN curl -sk https://catool.internal.secureworks.net/public/cas/4.cer >> /etc/pki/tls/certs/ca-bundle.crt
