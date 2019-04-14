FROM centos:6.10
LABEL version="3.4.1evi"
LABEL description="PrimeKey SignServer"
LABEL maintainer="pablo@evicertia.com"

#ENV JAVA_HOME=/opt/jre1.8.0_181

WORKDIR /data

RUN yum -y install openssl ca-certificates redhat-lsb-core epel-release
RUN yum -y install java-1.6.0-openjdk java-1.6.0-openjdk-devel
RUN yum -y install yum-priorities

ADD files/jpackage.repo /etc/yum.repos.d/
ADD files/jpackage.gpgkey /etc/pki/rpm-gpg/RPM-GPG-KEY-jpackage

RUN yum -y --enablerepo=jpackage install glassfish-javamail jbossas-5.1.0-30.jpp6

RUN mkdir -p /opt/{etc,bin}
#ADD files/main.sh /opt/bin/
#RUN chmod u+x /opt/bin/*

RUN yum clean all

VOLUME /data

#ENTRYPOINT ["/opt/bin/main.sh"]
