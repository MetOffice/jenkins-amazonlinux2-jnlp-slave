FROM pwbsladek/jenkins-amazonlinux2-jnlp-slave-base:latest

SHELL ["/bin/bash", "-c"]

ARG BUILD_DATE
ARG VCS_REF
ARG SCHEMA_VERSION

ARG PYTHON_DEFAULT_VERSION=3.7

LABEL maintainer="Paul Sladek" \
  org.label-schema.name="Jenkins Amazon Linux 2 JNLP slave" \
  org.label-schema.description="Jenkins Amazon Linux 2 JNLP slave" \
  org.label-schema.usage="/README.md" \
  org.label-schema.url="https://github.com/pbsladek/jenkins-amazonlinux2-jnlp-slave" \
  org.label-schema.vcs-url="git@github.com:pbsladek/jenkins-amazonlinux2-jnlp-slave.git" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.schema-version=$SCHEMA_VERSION

ENV PY_ENV_PATH $HOME/.pyenv/plugins/pyenv-virtualenv/shims:$HOME/.pyenv/shims:$HOME/.pyenv/bin
ENV DEFAULT_PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PATH ${PY_ENV_PATH}:${DEFAULT_PATH}

USER root

RUN export PATH=$PATH

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
  zlib-devel \
  libffi-devel

# Python with pyenv
RUN curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash && \
  echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> $HOME/.bash_profile && \
  echo 'eval "$(pyenv init - --no-rehash)"' >> $HOME/.bash_profile && \
  echo 'eval "$(pyenv virtualenv-init -)"' >> $HOME/.bash_profile && \
  source $HOME/.bash_profile && \
  pyenv install $PYTHON_DEFAULT_VERSION && \
  pyenv global $PYTHON_DEFAULT_VERSION && \
  pip install --no-cache-dir --upgrade pip && \
  pyenv rehash && \
  pip install --no-cache-dir awscli



# Allow jenkins user to change versions
RUN chown -R jenkins:jenkins $HOME/.pyenv && \
  echo '%jenkins ALL=(root) NOPASSWD:/usr/sbin/alternatives' >> /etc/sudoers

USER jenkins

RUN export PATH=$PATH
RUN export LC_ALL=C.UTF-8
RUN export LANG=C.UTF-8

COPY jenkins-slave /usr/local/bin/jenkins-slave

ENTRYPOINT ["jenkins-slave"]