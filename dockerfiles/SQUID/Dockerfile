FROM rhel7:latest
MAINTAINER rolsen@secureworks.com

EXPOSE 3128

RUN update-ca-trust enable && for a in {3,4}; do curl -sk https://catool.internal.secureworks.net/public/cas/${a}.cer -o /etc/pki/ca-trust/source/anchors/${a}.cer; done && update-ca-trust extract
RUN yum -y update && yum -y install squid && yum clean all

ADD ./squid.conf /etc/squid/squid.conf
ADD ./squid.sh /etc/squid.sh

ENV SQUIDCONF /etc/squid/squid.conf
ENV OSENET 10.17.0.0/16
ENV DOCKERNET 172.18.0.0/16
ENV DOCKERBRIDGE 172.17.0.0/16
ENV UPSTREAM squid.internal.secureworks.net

CMD /etc/squid.sh
