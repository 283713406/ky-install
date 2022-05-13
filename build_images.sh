#!/bin/bash -xe
MACHINE=`uname -m`

if [ ! ${ARCH} ]; then
  if [ "${MACHINE}" == "x86_64" ]; then
    ARCH=amd64
  elif [ "${MACHINE}" == "aarch64" ]; then
    ARCH=arm64
  else
    echo "Unknown machine" && exit 1
  fi
fi

REGISTRY_PATH="kcc/images/${ARCH}"

IMAGE_PREFIX="registry.kylincloud.org/"$REGISTRY_PATH

IMAGE=$IMAGE_PREFIX/"ky-installer:v3.1.1"

docker login -u wangqiwei -p Kylin123. $CI_REGISTRY

#proxy-set.sh

if [ "${ARCH}" == "arm64" ]; then

sed -i 's/istio-1.6.10-linux-amd64.tar.gz/istio-1.6.10-linux-arm64.tar.gz/g' roles/ky-istio/tasks/main.yaml

fi

docker build --build-arg ARCH="${ARCH}" -f Dockerfile.complete -t $IMAGE .

#proxy-unset.sh

docker push $IMAGE

exit 0
