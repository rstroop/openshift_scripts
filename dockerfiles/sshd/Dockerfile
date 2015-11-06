FROM ubuntu:14.04

ENV http_proxy=http://squid.internal.secureworks.net:3128
ENV https_proxy=http://squid.internal.secureworks.net:3128

# USER root

# RUN yum -y install ca-certificates

# RUN curl -sk https://catool.internal.secureworks.net/public/cas/3.cer >> /etc/pki/tls/certs/ca-bundle.crt RUN curl -sk https://catool.internal.secureworks.net/public/cas/4.cer >> /etc/pki/tls/certs/ca-bundle.crt

RUN apt-get update && apt-get install -y openssh-server 
RUN mkdir /var/run/sshd
RUN echo 'root:screencast' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
