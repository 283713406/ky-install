.PHONY:  ci clean

REPO?=kylinclouddev/ks-installer
TAG:=$(shell git rev-parse --abbrev-ref HEAD)-dev
ARCH:=$(shell uname -m)

ifeq ($(ARCH),aarch64)
        TASK_ARCH:=arm64
endif

ifeq ($(ARCH), x86_64)
        TASK_ARCH:=amd64
endif

build:
	docker build . --file Dockerfile --tag $(REPO):$(TAG)

push:
	docker push $(REPO):$(TAG)

all: build push

ci:
	mkdir -p /tmp/dind-cache
	docker login registry.kylincloud.org
	gitlab-runner exec docker local_build_$(TASK_ARCH) --docker-volumes /tmp/dind-cache/:/var/lib/docker/ --docker-volumes ~/.docker:/root/.docker --docker-privileged --cache-dir=/tmp/gitlab-cache --docker-cache-dir=/tmp/gitlab-cache  --docker-volumes=/tmp/gitlab-cache
