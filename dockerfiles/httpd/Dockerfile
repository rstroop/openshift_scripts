FROM rhel7

ENV http_proxy=http://squid.internal.secureworks.net:3128
ENV https_proxy=http://squid.internal.secureworks.net:3128

USER root

RUN yum -y install ca-certificates

RUN curl certs

RUN yum -y update && yum -y install httpd
RUN echo "Hello World" > /var/www/html/index.html

EXPOSE 80

CMD /usr/sbin/apachectl -DFOREGROUND
