FROM openshift/wildfly-90-centos7

ENV WILDFLY_HOME /wildfly

USER root
# Agent bond including Jolokia and jmx_exporter
ADD run-java-options.sh /opt/
RUN mkdir -p /opt/agent-bond \
 && curl http://central.maven.org/maven2/io/fabric8/agent-bond-agent/1.2.0/agent-bond-agent-1.2.0.jar \
          -o /opt/agent-bond/agent-bond.jar \
 && chmod 444 /opt/agent-bond/agent-bond.jar \
 && chmod 755 /opt/run-java-options.sh
ADD jmx_exporter_config.yml /opt/agent-bond/

# Fixes for Wildfly logging (see also https://issues.jboss.org/browse/WFLY-895) & agent bond options
ENV JBOSS_MODULES_SYSTEM_PKGS org.jboss.byteman,org.jboss.logmanager
RUN LOGMANAGER_JAR_FILE=$(find $WILDFLY_HOME -name "jboss-logmanager*.jar") \
 && echo 'JAVA_OPTS="${JAVA_OPTS} -Djava.util.logging.manager=org.jboss.logmanager.LogManager -Xbootclasspath/a:'"${LOGMANAGER_JAR_FILE}"'"' >> ${WILDFLY_HOME}/bin/standalone.conf \
 && echo 'JAVA_OPTS="${JAVA_OPTS} $(/opt/run-java-options.sh)"' >> ${WILDFLY_HOME}/bin/standalone.conf

USER default
EXPOSE 8080 8778 9779