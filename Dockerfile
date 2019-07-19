FROM jfisherp/ojdk8:211b12

MAINTAINER Jonny Fisher <jonny.fisherp@gmail.com>

COPY localtime /etc/localtime

ENV CATALINA_HOME="/usr/local/tomcat" \
    PATH="/usr/local/tomcat/bin:$PATH" \
    TOMCAT_MAJOR_VERSION=9 \
    TOMCAT_MINOR_VERSION=9.0.22 \
    APACHE_MIRROR="https://archive.apache.org/dist" \
    APR_VERSION=1.7.0 \
    TOMCAT_NATIVE_VERSION=1.2.23 \
    JAVA_HOME=/usr/lib/jvm/default-jvm
RUN mkdir -p "${CATALINA_HOME}"
WORKDIR $CATALINA_HOME

RUN set -x \
  && apk --no-cache add --virtual build-dependencies wget ca-certificates tar alpine-sdk gnupg \
  && update-ca-certificates \
  && wget -q --no-check-certificate "${APACHE_MIRROR}/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_MINOR_VERSION}/bin/apache-tomcat-${TOMCAT_MINOR_VERSION}.tar.gz" \
  && wget -q --no-check-certificate "${APACHE_MIRROR}/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_MINOR_VERSION}/bin/apache-tomcat-${TOMCAT_MINOR_VERSION}.tar.gz.asc" \
  && tar -xf "apache-tomcat-${TOMCAT_MINOR_VERSION}.tar.gz" --strip-components=1 \
  && rm bin/*.bat \
  && rm "apache-tomcat-${TOMCAT_MINOR_VERSION}.tar.gz" \
  && cd /tmp \
  && wget -q --no-check-certificate "${APACHE_MIRROR}/tomcat/tomcat-connectors/native/${TOMCAT_NATIVE_VERSION}/source/tomcat-native-${TOMCAT_NATIVE_VERSION}-src.tar.gz" \
  && wget -q --no-check-certificate "${APACHE_MIRROR}/apr/apr-${APR_VERSION}.tar.gz" \
  && tar -xf "apr-${APR_VERSION}.tar.gz" && cd "apr-${APR_VERSION}" && ./configure && make && make install \
  && cd /tmp && tar -xf "tomcat-native-${TOMCAT_NATIVE_VERSION}-src.tar.gz" && cd "tomcat-native-${TOMCAT_NATIVE_VERSION}-src/native" \
  && ./configure --with-apr="/usr/local/apr/bin" --with-java-home="$JAVA_HOME" --with-ssl=no --prefix="$CATALINA_HOME" \
  && make && make install \
  && ln -sv "${CATALINA_HOME}/lib/libtcnative-1.so" "/usr/lib/" && ln -sv "/lib/libz.so.1" "/usr/lib/libz.so.1" \
  && sed -i 's/SSLEngine="on"/SSLEngine="off"/g' "${CATALINA_HOME}/conf/server.xml" \
  && apk del --purge build-dependencies \
  && addgroup -S tomcat -g 1001 \
  && adduser -S tomcat -u 1001 -G tomcat \
  && chown -R tomcat:tomcat ${CATALINA_HOME} \
  && cd ${CATALINA_HOME} \
  && rm -rf /tmp/* /var/cache/apk/* ${CATALINA_HOME}/BUILDING.txt ${CATALINA_HOME}/CONTRIBUTING.md ${CATALINA_HOME}/LICENSE ${CATALINA_HOME}/NOTICE ${CATALINA_HOME}/README.md ${CATALINA_HOME}/RELEASE-NOTES ${CATALINA_HOME}/RUNNING.txt ${CATALINA_HOME}/apache-tomcat-${TOMCAT_MINOR_VERSION}.tar.gz.asc


USER tomcat
EXPOSE 8080
#CMD ["/usr/local/tomcat/bin/catalina.sh", "start"]
#CMD ["catalina.sh", "start"]
CMD catalina.sh start && tail -f logs/catalina.out
