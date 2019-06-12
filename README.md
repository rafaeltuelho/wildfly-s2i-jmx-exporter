# Openshift s2i wildfly extension
This is an extension of the [Openshift S2I Image for Wildfly](https://github.com/openshift-s2i/s2i-wildfly) which exposes JMX metrics through Jolokia and Prometheus JMX Exporter.

This extension adds to the `openshift/wildfly-160-centos7` base image:

* An [Agent Bond](https://github.com/fabric8io/agent-bond) agent with [Jolokia](http://www.jolokia.org) and Prometheus' [jmx_exporter](https://github.com/prometheus/jmx_exporter). The agent is installed as `/opt/agent-bond/agent-bond.jar`. See below for configuration options.

## Testing this s2i extension

### Building the image

> if you need to change the wildfly version you want to use, change the `FROM` instruction on `Dockefile`

```
docker build -t rafaeltuelho/wildfly-90-jmx-exporter .
```

### Testing the s2i

> make sure you have [s2i](https://github.com/openshift/source-to-image/releases) installed

```
s2i build git://github.com/openshift/openshift-jee-sample rafaeltuelho/wildfly-90-jmx-exporter wildflytest
```

### Run your container

```
docker run -it -p 8080:8080 -p 9779:9779 -p 8778:8778 wildflytest
```

Now you can test the jmx endpoints exposed by Jolokia and JMX-exporter agents:

 * Sample WebApp: http://localhost:8080
 * Prometheus jmx metrics: http://localhost:9779/metrics
 * Jolokia jmx metrics: http://localhost:8778/jolokia

### Testing using Prometheus and Grafana
> make sure you have [docker-compose](https://docs.docker.com/compose/install/) installed

```
docker-compose up
```

 * Prometheus: http://localhost:9090
 * Grafana: http://localhost:3000 (login: `admin/admin`)
 > you will have to add Prometheus Datasource (`http://localhost:9090`, browser auth)

### Using this extension on openshift

 * push this image directly to your openshift registry or to any public/private registry
 * use the `oc new-app` pointing to the created imagestream inside your project

## Agent Bond

In order to enable Jolokia for your application you should use the output of `run-java-options.sh` in your startup scripts to include it in for the Java startup options.

For example, the following snippet can be added to a script starting up your Java application

    # ...
    export JAVA_OPTIONS="$JAVA_OPTIONS $(/opt/run-java-options.sh)"
    # .... use JAVA_OPTIONS when starting your app, e.g. as Wildfly does

The following versions and defaults are used:

* [Jolokia](http://www.jolokia.org) : version **1.6.1** and port **8778**
* [jmx_exporter](https://github.com/prometheus/jmx_exporter): version **0.3.1** and port **9779**

You can influence the behaviour of `run-java-options.sh` by setting various environment variables:

### Agent-Bond Options

Agent bond itself can be influenced with the following environment variables: 

* **AB_OFF** : If set disables activation of agent-bond (i.e. echos an empty value). By default, agent-bond is enabled.
* **AB_ENABLED** : Comma separated list of sub-agents enabled. Currently allowed values are `jolokia` and `jmx_exporter`. 
  By default both are enabled.


#### Jolokia configuration

* **AB_JOLOKIA_CONFIG** : If set uses this file (including path) as Jolokia JVM agent properties (as described 
  in Jolokia's [reference manual](http://www.jolokia.org/reference/html/agents.html#agents-jvm)).
  By default this is `/opt/jolokia/jolokia.properties`.
* **AB_JOLOKIA_HOST** : Host address to bind to (Default: `0.0.0.0`)
* **AB_JOLOKIA_PORT** : Port to use (Default: `8778`)
* **AB_JOLOKIA_USER** : User for authentication. By default authentication is switched off.
* **AB_JOLOKIA_HTTPS** : Switch on secure communication with https. By default self signed server certificates are generated
  if no `serverCert` configuration is given in `AB_JOLOKIA_OPTS`
* **AB_JOLOKIA_PASSWORD** : Password for authentication. By default authentication is switched off.
* **AB_JOLOKIA_ID** : Agent ID to use (`$HOSTNAME` by default, which is the container id)
* **AB_JOLOKIA_OPTS**  : Additional options to be appended to the agent opts. They should be given in the format 
  "key=value,key=value,..."

Some options for integration in various environments:

* **AB_JOLOKIA_AUTH_OPENSHIFT** : Switch on client authentication for OpenShift TLS communication. The value of this 
  parameter can be a relative distinguished name which must be contained in a presented client certificate. Enabling this
  parameter will automatically switch Jolokia into https communication mode. The default CA cert is set to 
  `/var/run/secrets/kubernetes.io/serviceaccount/ca.crt` 
  
#### jmx_exporter configuration

* **AB_JMX_EXPORTER_OPTS** : Configuration to use for `jmx_exporter` (in the format `<port>:<path to config>`)
* **AB_JMX_EXPORTER_PORT** : Port to use for the JMX Exporter. Default: `9779`
* **AB_JMX_EXPORTER_CONFIG** : Path to configuration to use for `jmx_exporter`: Default: `/opt/agent-bond/jmx_exporter_config.json`

