FROM centos:6.10
LABEL version="3.4.1evi"
LABEL description="PrimeKey SignServer"
LABEL maintainer="pablo@evicertia.com"
LABEL vendor="evicertia"

WORKDIR /data

# Install base stuff..

RUN yum -y install openssl ca-certificates redhat-lsb-core epel-release yum-priorities
RUN yum -y install java-1.6.0-openjdk java-1.6.0-openjdk-devel

# Install jboss (from jpackage)

ADD files/jpackage.repo /etc/yum.repos.d/
ADD files/jpackage.gpgkey /etc/pki/rpm-gpg/RPM-GPG-KEY-jpackage

RUN yum -y --enablerepo=jpackage install glassfish-javamail jbossas-5.1.0-30.jpp6

ADD files/server.xml /var/lib/jbossas/server/default/deploy/jbossweb.sar/server.xml

# Install signserver packages from netway-extras

ADD files/netway-extras.repo /etc/yum.repos.d/

RUN yum -y --enablerepo=netway-extras \
	install signserver-client-3.4.1evi-2945.17.noarch signserver-server-3.4.1evi-2945.17.noarch
RUN ln -s /opt/signserver/lib/signserver.ear \
	  /var/lib/jbossas/server/default/deploy/signserver.ear
ADD files/signserver-ds.xml /var/lib/jbossas/server/default/deploy/signserver-ds.xml
ADD files/signserver.settings /etc/sysconfig/signserver

RUN mkdir -p /opt/{etc,bin}
ADD files/main.sh /opt/bin/
RUN chmod u+x /opt/bin/*

RUN yum clean all

VOLUME /data

#ENV JAVA_HOME=/opt/jre1.8.0_181
ENV JAVA_OPTS=
ENV SIGNSERVER_NODEID=

EXPOSE 8080
EXPOSE 8009

ENTRYPOINT ["/opt/bin/main.sh"]
