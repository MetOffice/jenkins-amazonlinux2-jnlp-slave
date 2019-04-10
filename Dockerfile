FROM pwbsladek/jenkins-amazonlinux2-jnlp-slave-base:latest

ARG BUILD_DATE
ARG VCS_REF
ARG SCHEMA_VERSION

LABEL maintainer="Paul Sladek" \
  org.label-schema.name="Jenkins Amazon Linux 2 JNLP slave" \
  org.label-schema.description="Jenkins Amazon Linux 2 JNLP slave" \
  org.label-schema.usage="/README.md" \
  org.label-schema.url="https://github.com/pbsladek/jenkins-amazonlinux2-jnlp-slave" \
  org.label-schema.vcs-url="git@github.com:pbsladek/jenkins-amazonlinux2-jnlp-slave.git" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.schema-version=$SCHEMA_VERSION

# Use alternatives to switch between java versions
# alternatives --set java $JAVA_CORRETTO_8_PATH
ENV JAVA_CORRETTO_8_PATH /usr/lib/jvm/java-1.8.0-amazon-corretto.x86_64/jre/bin/java
ENV JAVA_CORRETTO_11_PATH /usr/lib/jvm/java-11-amazon-corretto/bin/java

USER root

# Required for builds
RUN amazon-linux-extras enable epel docker && \
  yum clean metadata && \
  yum install -y epel-release docker && \
  yum -y update && \
  yum -y install automake \
  bzip2 \
  bzip2-devel \
  gcc \
  git \
  jq \
  kernel-devel \
  make \
  openssl-devel  \
  readline-devel \
  sqlite \
  sqlite-devel \
  tar \
  tk-devel \
  zlib-devel

# Required for PHP
RUN yum -y install bison \
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
  re2c \
  which

# Java, Install corretto 11 but default to corretto8
RUN curl -O https://d3pxv6yz143wms.cloudfront.net/11.0.2.9.3/java-11-amazon-corretto-devel-11.0.2.9-3.x86_64.rpm && \
  yum -y localinstall java-11-amazon-corretto-devel-11.0.2.9-3.x86_64.rpm && \
  yum -y install maven && \
  alternatives --set java $JAVA_CORRETTO_8_PATH

# PHP with phpenv
RUN git clone git://github.com/phpenv/phpenv.git ~/.phpenv && \
  echo 'export PATH="$HOME/.phpenv/bin:$PATH"' >> ~/.bashrc && \
  echo 'eval "$(phpenv init -)"' >> ~/.bashrc && \
  source ~/.bashrc && \
  git clone https://github.com/php-build/php-build $(phpenv root)/plugins/php-build && \
  phpenv install 7.0.31 && \
  phpenv install 7.3.4 && \
  phpenv global 7.3.4 && \
  phpenv rehash

# Python with pyenv
RUN curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash && \
  echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bashrc && \
  echo 'eval "$(pyenv init -)"' >> ~/.bashrc && \
  echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc && \
  source ~/.bashrc && \
  pyenv install 2.7.15 && \
  pyenv install 3.6.8 && \
  pyenv global 3.6.8 && \
  pip install --upgrade pip && \
  pyenv rehash && \
  pip install awscli

# Node with nodenv
RUN git clone https://github.com/nodenv/nodenv.git ~/.nodenv && \
  echo 'export PATH="$HOME/.nodenv/bin:$PATH"' >> ~/.bashrc && \
  echo 'eval "$(nodenv init -)"' >> ~/.bashrc && \
  source ~/.bashrc && \
  mkdir -p "$(nodenv root)"/plugins && \
  git clone https://github.com/nodenv/node-build.git "$(nodenv root)"/plugins/node-build && \
  nodenv install 8.15.1 && \
  nodenv install 10.15.3 && \
  nodenv global 10.15.3 && \
  nodenv rehash && \
  npm install -g yarn

# Cleanup
RUN rm -rf /tmp/* && yum clean all && rm -rf /var/cache/yum

USER jenkins

COPY jenkins-slave /usr/local/bin/jenkins-slave

ENTRYPOINT ["jenkins-slave"]