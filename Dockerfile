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

#RUN sed -i 's|<constructor><parameter><inject bean="BootstrapProfileFactory" property="attachmentStoreRoot" /></parameter></constructor>|<constructor><parameter class="java.io.File"><inject bean="BootstrapProfileFactory" property="attachmentStoreRoot" /></parameter></constructor>|g'  /var/lib/jbossas/server/default/conf/bootstrap/profile.xml
RUN sed -ri 's|<parameter>(<inject bean="BootstrapProfileFactory" property="attachmentStoreRoot" />)|<parameter class="java.io.File">\1|g' /var/lib/jbossas/server/default/conf/bootstrap/profile.xml

# Install signserver packages from netway-extras

ADD files/netway-extras.repo /etc/yum.repos.d/

RUN yum -y --enablerepo=netway-extras \
	install signserver-client-3.4.1evi-2958.21.noarch signserver-server-3.4.1evi-2958.21.noarch
RUN ln -s /opt/signserver/lib/signserver.ear \
	  /var/lib/jbossas/server/default/deploy/signserver.ear
ADD files/signserver-ds.xml /var/lib/jbossas/server/default/deploy/signserver-ds.xml
ADD files/signserver.settings /etc/sysconfig/signserver

# Install utimaco pkcs11 driver & support files

RUN mkdir -p /opt/utimaco/lib64 /opt/utimaco/p11
ADD files/libcs_pkcs11* /opt/utimaco/p11/
ADD files/libgcc_s.so.1 files/libstdc++.so.6.0.22 /opt/utimaco/lib64/
RUN \
	ln -s libcs_pkcs11_R2.so /opt/utimaco/p11/libcs2_pkcs11.so && \
	ln -s libstdc++.so.6.0.22 /opt/utimaco/lib64/libstdc++.so.6 && \
	echo /opt/utimaco/lib64 > /etc/ld.so.conf.d/utimaco-pkcs11.conf && \
	ldconfig

RUN mkdir -p /opt/{etc,bin}
ADD files/main.sh /opt/bin/
RUN chmod u+x /opt/bin/*

RUN yum clean all

#COPY files/signserver.war files/signserver.ear /opt/signserver/lib/

VOLUME /data

#ENV JAVA_HOME=/opt/jre1.8.0_181
ENV JAVA_OPTS=
ENV SIGNSERVER_NODEID=
ENV CRYPTOSERVER=3001@127.0.0.1
ENV CS_AUTH_KEYS=/data/hsm.keys
ENV CS_PKCS11_LOGLEVEL=
ENV CS_PKCS11_KEEPALIVE=

EXPOSE 8080
EXPOSE 8009

ENTRYPOINT ["/opt/bin/main.sh"]
