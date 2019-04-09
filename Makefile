ROOT:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
IMAGE_NAME:=pwbsladek/jenkins-amazonlinux2-jnlp-slave:latest

BUILD_DATE:=$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
VCS_REF:=$(shell git log --pretty=format:'%h' -n 1)
SCHEMA_VERSION=0.0.1

build:
	docker build -t ${IMAGE_NAME} \
	--build-arg BUILD_DATE=${BUILD_DATE} \
	--build-arg VCS_REF=${VCS_REF} \
	--build-arg SCHEMA_VERSION=${SCHEMA_VERSION} .
