FROM jboss/wildfly:14.0.1.Final

LABEL vendor="evicertia"
LABEL maintainer="pablo@evicertia.com"
LABEL description="PrimeKey SignServer"
LABEL version="5.2.0"

ENV SIGNSERVER_MAJOR 5
ENV SIGNSERVER_MINOR 2
ENV SIGNSERVER_FILE signserver-ce-5.2.0.Final-bin.zip
ENV SIGNSERVER_SHA256 5d9b8cec5d0e8ae23587060f701ba5b470fb625cb5787f4e0ac53d6224bbf06f
ENV SIGNSERVER_HOME /opt/signserver
ENV APPSRV_HOME /opt/jboss/wildfly

USER root

# Install base stuff..
RUN yum -y install openssl ca-certificates redhat-lsb-core yum-priorities ant

# Install signserver binaries..
RUN cd /opt \
	&& curl -LO https://sourceforge.net/projects/signserver/files/signserver/$SIGNSERVER_MAJOR.$SIGNSERVER_MINOR/$SIGNSERVER_FILE \
	&& sha256sum $SIGNSERVER_FILE | grep $SIGNSERVER_SHA256 \
	&& unzip $SIGNSERVER_FILE \
	&& rm $SIGNSERVER_FILE \
	&& mv signserver-ce-* signserver

# Setup deployment settings..
RUN cd $SIGNSERVER_HOME/conf \
	&& cp signserver_deploy.properties.sample signserver_deploy.properties \
	&& sed -i'' -re 's/^#(database.name=nodb)/\1/g' signserver_deploy.properties \
	&& sed -i'' -re 's|^#(database.nodb.location)=.*|\1=/data/db|g' signserver_deploy.properties \
	&& sed -i'' -re 's/^(#)?(validationws.enabled)=.*/\2=true/g' signserver_deploy.properties \
	&& sed -i'' -re 's/^(#)?(module.statusproperties.enabled)=.*/\2=true/g' signserver_deploy.properties \
	&& sed -i'' -re 's/^(#)?(module.signerstatusreport.enabled)=.*/\2=true/g' signserver_deploy.properties \
	&& sed -i'' -re 's/^(#)?(healthcheck.authorizedips)=.*/\2=ANY/g' signserver_deploy.properties

# Deploy signserver to appsrv..
RUN $SIGNSERVER_HOME/bin/ant deploy

# Deploy custom wildfly configuration..
COPY files/standalone.xml /opt/jboss/wildfly/standalone/configuration/standalone.xml

# Install utimaco pkcs11 driver & support files
RUN mkdir -p /opt/utimaco/lib64 /opt/utimaco/p11
ADD files/libcs_pkcs11* /opt/utimaco/p11/
RUN \
	ln -s libcs_pkcs11_R2.so /opt/utimaco/p11/libcs2_pkcs11.so && \
	ln -s libcs_pkcs11_R2.so /opt/utimaco/p11/libcs2_pkcs11r2.so && \
	ln -s libcs_pkcs11_R3.so /opt/utimaco/p11/libcs2_pkcs11r3.so && \
	echo /opt/utimaco/lib64 > /etc/ld.so.conf.d/utimaco-pkcs11.conf && \
	ldconfig

RUN mkdir -p /opt/{etc,bin}
ADD files/main.sh /opt/bin/
RUN chmod u+x /opt/bin/*

RUN yum clean all

ENV SIGNSERVER_NODEID=
ENV CRYPTOSERVER=3001@127.0.0.1
ENV CS_AUTH_KEYS=/data/hsm.keys
ENV CS_PKCS11_LOGLEVEL=
ENV CS_PKCS11_KEEPALIVE=
ENV CS_PKCS11_MULTISESSION=
ENV CS_PKCS11_SLOTCOUNT=

EXPOSE 8080
EXPOSE 8009
VOLUME /data
WORKDIR /data

ENTRYPOINT ["/opt/bin/main.sh"]
