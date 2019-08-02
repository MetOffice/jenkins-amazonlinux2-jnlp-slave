FROM pwbsladek/jenkins-amazonlinux2-jnlp-slave-base:latest

SHELL ["/bin/bash", "-c"]

ARG BUILD_DATE
ARG VCS_REF
ARG SCHEMA_VERSION

ARG JAVA_OPTS
ARG EXTRA_GOLANG=1.11.3
ARG EXTRA_DOCKER=18.06.1
ARG EXTRA_EPEL=7.11
ARG EXTRA_PHP=7.3.3
ARG MAVEN_VERSION=3.6.0
ARG PYTHON_DEFAULT_VERSION=3.6.8
ARG PHP_DEFAULT_VERSION=7.0.31
ARG GO_DEFAULT_VERSION=1.12.3
ARG NODE_DEFAULT_VERSION=10.15.3
ARG NODE_OLD_LTS_VERSION=8.15.1
ARG CORRETTO_RPM=java-11-amazon-corretto-devel-11.0.2.9-3.x86_64.rpm
ARG NUXEO_VERSION=release-10.10-HF10

LABEL maintainer="Paul Sladek" \
  org.label-schema.name="Jenkins Amazon Linux 2 JNLP slave" \
  org.label-schema.description="Jenkins Amazon Linux 2 JNLP slave" \
  org.label-schema.usage="/README.md" \
  org.label-schema.url="https://github.com/pbsladek/jenkins-amazonlinux2-jnlp-slave" \
  org.label-schema.vcs-url="git@github.com:pbsladek/jenkins-amazonlinux2-jnlp-slave.git" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.schema-version=$SCHEMA_VERSION

ENV JAVA_CORRETTO_8_PATH /usr/lib/jvm/java-1.8.0-amazon-corretto.x86_64/jre/bin/java
ENV JAVAC_CORRETTO_8_PATH /usr/lib/jvm/java-1.8.0-amazon-corretto.x86_64/bin/javac
ENV JAVA_CORRETTO_11_PATH /usr/lib/jvm/java-11-amazon-corretto/bin/java
ENV JAVAC_CORRETTO_11_PATH /usr/lib/jvm/java-11-amazon-corretto/bin/javac

ENV NODE_ENV_PATH $HOME/.nodenv/shims:$HOME/.nodenv/bin
ENV GO_ENV_PATH $HOME/.goenv/bin
ENV PY_ENV_PATH $HOME/.pyenv/plugins/pyenv-virtualenv/shims:$HOME/.pyenv/shims:$HOME/.pyenv/bin
ENV PHP_ENV_PATH $HOME/.phpenv/shims:$HOME/.phpenv/bin:$HOME/.composer/vendor/bin
ENV TOOLS_ENV_PATH /opt/maven/bin
ENV DEFAULT_PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PATH ${NODE_ENV_PATH}:${GO_ENV_PATH}:${PY_ENV_PATH}:${PHP_ENV_PATH}:${TOOLS_ENV_PATH}:${DEFAULT_PATH}

ENV JAVA_OPTS "-Dfile.encoding=UTF-8 \
  -Dorg.apache.commons.jelly.tags.fmt.timeZone=America/Los_Angeles ${JAVA_OPTS:-}"

USER root

RUN export PATH=$PATH
RUN export MAVEN_OPTS="-Xss50M -Xmx4000M -XX:+CMSClassUnloadingEnabled"

# Required for builds
RUN amazon-linux-extras enable epel=$EXTRA_EPEL docker=$EXTRA_DOCKER golang1.11=$EXTRA_GOLANG && \
  yum clean metadata && \
  yum install -y epel-release && \
  yum -y update && \
  yum -y install automake \
  bzip2 \
  bzip2-devel \
  docker \
  gcc \
  git \
  golang \
  jq \
  kernel-devel \
  make \
  openssl-devel  \
  readline-devel \
  sqlite \
  sqlite-devel \
  sudo \
  tar \
  tk-devel \
  wget \
  zlib-devel

# Required for PHP
RUN amazon-linux-extras enable php7.3=$EXTRA_PHP && \
  yum clean metadata && \
  yum -y install bison \
  composer \
  dpkg-dev \
  dpkg-devel \
  gcc-c++ \
  file \
  libcurl-devel \
  libffi-devel  \
  libicu-devel \
  libjpeg-devel \
  libmcrypt-devel \
  libpng-devel \
  libtidy-devel \
  libxml2-devel \
  libxslt-devel \
  libzip-devel \
  php-cli \
  php-pdo \
  php-fpm \
  php-json \
  php-mysqlnd \
  re2c \
  which

# Install Rundeck cli
RUN wget https://bintray.com/rundeck/rundeck-rpm/rpm -O bintray.repo && \
  mv bintray.repo /etc/yum.repos.d/ && \
  sed -i.bak s/^gpgcheck=0/gpgcheck=1/ /etc/yum.repos.d/bintray.repo && \
  echo "gpgkey=http://rundeck.org/keys/BUILD-GPG-KEY-Rundeck.org.key" >> /etc/yum.repos.d/bintray.repo && \
  yum -y install rundeck-cli

# Java, Install corretto 11 but default to corretto8
RUN curl -O https://d3pxv6yz143wms.cloudfront.net/11.0.2.9.3/$CORRETTO_RPM && \
  yum -y localinstall $CORRETTO_RPM && \
  alternatives --set java $JAVA_CORRETTO_8_PATH && \
  alternatives --set javac $JAVAC_CORRETTO_8_PATH && \
  wget https://www-us.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz -P /tmp && \
  tar xf /tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz -C /opt && \
  ln -s /opt/apache-maven-$MAVEN_VERSION /opt/maven

# Goland with goenv
RUN git clone https://github.com/syndbg/goenv.git $HOME/.goenv && \
  echo 'export PATH="$HOME/.goenv/bin:$PATH"' >> $HOME/.bash_profile && \
  echo 'eval "$(goenv init -)"' >> ~/.bash_profile && \
  echo 'export PATH="$GOROOT/bin:$PATH"' >> $HOME/.bash_profile && \
  echo 'export PATH="$GOPATH/bin:$PATH"' >> $HOME/.bash_profile && \
  source $HOME/.bash_profile && \
  goenv install $GO_DEFAULT_VERSION && \
  goenv global $GO_DEFAULT_VERSION && \
  goenv rehash

# Python with pyenv
RUN curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash && \
  echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> $HOME/.bash_profile && \
  echo 'eval "$(pyenv init - --no-rehash)"' >> $HOME/.bash_profile && \
  echo 'eval "$(pyenv virtualenv-init -)"' >> $HOME/.bash_profile && \
  source $HOME/.bash_profile && \
  pyenv install $PYTHON_DEFAULT_VERSION && \
  pyenv global $PYTHON_DEFAULT_VERSION && \
  pip install --upgrade pip && \
  pyenv rehash && \
  pip install awscli

# Node with nodenv
RUN git clone https://github.com/nodenv/nodenv.git $HOME/.nodenv && \
  echo 'export PATH="$HOME/.nodenv/bin:$PATH"' >> $HOME/.bash_profile && \
  echo 'eval "$(nodenv init -)"' >> $HOME/.bash_profile && \
  source $HOME/.bash_profile && \
  mkdir -p "$(nodenv root)"/plugins && \
  git clone https://github.com/nodenv/node-build.git "$(nodenv root)"/plugins/node-build && \
  nodenv install $NODE_OLD_LTS_VERSION && \
  nodenv install $NODE_DEFAULT_VERSION && \
  nodenv global $NODE_DEFAULT_VERSION && \
  nodenv rehash && \
  node --version && \
  # --unsafe-perm for tmp workaround on polymer-cli issues
  npm install -g yarn gulp grunt grunt-cli polymer-cli bower yo --unsafe-perm

# PHP with phpenv
RUN git clone git://github.com/phpenv/phpenv.git $HOME/.phpenv && \
  echo 'export PATH="$HOME/.phpenv/bin:$PATH"' >> $HOME/.bash_profile && \
  echo 'eval "$(phpenv init -)"' >> $HOME/.bash_profile && \
  source $HOME/.bash_profile && \
  git clone https://github.com/php-build/php-build $(phpenv root)/plugins/php-build && \
  phpenv install $PHP_DEFAULT_VERSION && \
  phpenv global $PHP_DEFAULT_VERSION && \
  phpenv rehash

# Cleanup
RUN rm -rf /tmp/* && \
  yum clean all && \
  rm -rf /var/cache/yum && \
  rm -rf $CORRETTO_RPM

# Allow jenkins user to change versions
RUN chown -R jenkins:jenkins $HOME/.nodenv $HOME/.npm $HOME/.goenv $HOME/.pyenv $HOME/.phpenv $HOME/.config && \
  echo '%jenkins ALL=(root) NOPASSWD:/usr/sbin/alternatives' >> /etc/sudoers

USER jenkins

RUN export PATH=$PATH

# Init maven nuxeo cache to reduce build times
RUN git clone https://github.com/nuxeo/nuxeo && \
  cd nuxeo && git checkout $NUXEO_VERSION && \
  mvn install -DskipTests && \
  cd .. && rm -rf nuxeo

COPY jenkins-slave /usr/local/bin/jenkins-slave

ENTRYPOINT ["jenkins-slave"]