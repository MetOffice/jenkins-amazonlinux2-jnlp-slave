Jenkins Amazon Linux JNLP slave
===

[![Docker Stars](https://img.shields.io/docker/stars/pwbsladek/jenkins-amazonlinux2-jnlp-slave.svg)](https://hub.docker.com/r/pwbsladek/jenkins-amazonlinux2-jnlp-slave)
[![Docker Pulls](https://img.shields.io/docker/pulls/pwbsladek/jenkins-amazonlinux2-jnlp-slave.svg)](https://hub.docker.com/r/pwbsladek/jenkins-amazonlinux2-jnlp-slave)
[![Docker Automated build](https://img.shields.io/docker/automated/pwbsladek/jenkins-amazonlinux2-jnlp-slave.svg)](https://hub.docker.com/r/pwbsladek/jenkins-amazonlinux2-jnlp-slave)

## Description

Based on [jenkins/slave/ Dockerfile](https://hub.docker.com/r/jenkins/slave/dockerfile) and 
[jenkins/jnlp-slave/ Dockerfile](https://hub.docker.com/r/jenkins/jnlp-slave/dockerfile).

It seeks to maintain a general jenkins slave build image that has a number of common languages and build tools already installed. Languages are installed using version managers. If a specific version is needed at build time, you can use the specific env manager to utilize that version.

## Supported

### Java
- [Corretto 8](https://aws.amazon.com/corretto/) (OpenJDK Java 8) - Default
- [Corretto 11](https://aws.amazon.com/corretto/)(OpenJDK Java 11)
- [Maven 3.6.0](https://maven.apache.org/)
- Use [alternatives](https://linux.die.net/man/8/alternatives) to switch versions
  - alternatives --set java $JAVA_CORRETTO_8_PATH
  - alternatives --set javac $JAVAC_CORRETTO_8_PATH
  - alternatives --set java $JAVA_CORRETTO_11_PATH
  - alternatives --set javac $JAVAC_CORRETTO_11_PATH
  - `sudo alternatives --set java $JAVA_CORRETTO_8_PATH`
  - `sudo alternatives --set javac $JAVAC_CORRETTO_8_PATH`
  - `sudo alternatives --set java $JAVA_CORRETTO_11_PATH`
  - `sudo alternatives --set javac $JAVAC_CORRETTO_11_PATH`
  - JAVA_HOME will correctly point to the new version since it points to `/usr/lib/jvm/java`

### Node
- [Node Dubnium 10.15.3](https://nodejs.org/ko/blog/release/v10.15.3/) - Default
- [Node Carbon 8.15.1](https://nodejs.org/en/blog/release/v8.15.1/)
- [NPM](https://www.npmjs.com/)
- [Yarn](https://yarnpkg.com/)
- [nodenv](https://github.com/nodenv/nodenv)
  
### Python
- [Python 3.6.8](https://www.python.org/downloads/release/python-368/) - Default
- [Python 2.7.14](https://www.python.org/downloads/release/python-2714/) - System
- [pip](https://pypi.org/project/pip/)
- [pyenv](https://github.com/pyenv/pyenv)

### Golang
- [Golang 1.12.3](https://golang.org/doc/go1.12) - Default
- [Golang 1.11.8](https://golang.org/doc/go1.11)
- [goenv](https://github.com/syndbg/goenv)

### PHP
- [PHP 7.0.31](https://www.php.net/releases/7_0_31.php) - Default
- [PHP 7.3.3](https://www.php.net/releases/7_3_3.php) - System
- [Composer](https://getcomposer.org/)
- [phpenv](https://github.com/phpenv/phpenv)
  
### Tools

- [docker](https://www.docker.com/) (18.06.1-ce)
- [awscli](https://docs.aws.amazon.com/cli/latest/reference/) (aws-cli/1.16.140 Python/3.6.8 Linux/4.9.125-linuxkit botocore/1.12.130)
- [jq](https://stedolan.github.io/jq/) (jq-1.5)

## Running

To run a Docker container

    docker run pwbsladek/jenkins-amazonlinux2-jnlp-slave -url http://jenkins-server:port <secret> <agent name>

To run a Docker container with [Work Directory](https://github.com/jenkinsci/remoting/blob/master/docs/workDir.md):

    docker run pwbsladek/jenkins-amazonlinux2-jnlp-slave -url http://jenkins-server:port -workDir=/home/jenkins/agent <secret> <agent name>

Optional environment variables:

* `JENKINS_URL`: url for the Jenkins server, can be used as a replacement to `-url` option, or to set alternate jenkins URL
* `JENKINS_TUNNEL`: (`HOST:PORT`) connect to this agent host and port instead of Jenkins server, assuming this one do route TCP traffic to Jenkins master. Useful when when Jenkins runs behind a load balancer, reverse proxy, etc.
* `JENKINS_SECRET`: agent secret, if not set as an argument
* `JENKINS_AGENT_NAME`: agent name, if not set as an argument
* `JENKINS_AGENT_WORKDIR`: agent work directory, if not set by optional parameter `-workDir`

## Configuration specifics

### Enabled JNLP protocols

By default, the [JNLP3-connect](https://github.com/jenkinsci/remoting/blob/master/docs/protocols.md#jnlp3-connect) is disabled due to the known stability and scalability issues.
You can enable this protocol on your own risk using the 
`JNLP_PROTOCOL_OPTS=-Dorg.jenkinsci.remoting.engine.JnlpProtocol3.disabled=false` property (the protocol should be enabled on the master side as well).

In Jenkins versions starting from `2.27` there is a [JNLP4-connect](https://github.com/jenkinsci/remoting/blob/master/docs/protocols.md#jnlp4-connect) protocol. 
If you use Jenkins `2.32.x LTS`, it is recommended to enable the protocol on your instance.

### Amazon ECS

Make sure your ECS container agent is [updated](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-update.html) before running. Older versions do not properly handle the entryPoint parameter. See the [entryPoint](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definitions) definition for more information.