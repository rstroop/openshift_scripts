#FROM x-pvd1rhnsat02.internal.secureworkslab.com:5555/jenkins:docker
FROM jenkins:docker

ENV http_proxy 172.18.65.114:3128
ENV https_proxy 172.18.65.114:3128
ENV no_proxy .secureworks.net,.secureworks.com,.secureworkslab.com,.secureworkslab.net,.google.internal
USER root

RUN update-ca-trust enable && for a in {3,4}; do curl -sk https://catool.internal.secureworks.net/public/cas/${a}.cer -o /etc/pki/ca-trust/source/anchors/${a}.cer; done && update-ca-trust extract

ADD oc /bin/oc
ADD plugins /opt/openshift/configuration/plugins
ADD jobs /opt/openshift/configuration/jobs
ADD org.jenkinsci.plugins.dockerbuildstep.DockerBuilder.xml /opt/openshift/configuration/org.jenkinsci.plugins.dockerbuildstep.DockerBuilder.xml

