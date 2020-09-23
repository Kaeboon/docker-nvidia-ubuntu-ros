#!/usr/bin/env bash
# This script starts the docker container

# Requirement:
# - docker
# - nvidia-docker2
# - x server

# Allowing container to connect to x server (for gazebo)
XAUTH=/tmp/.docker.xauth
if [ ! -f $XAUTH ]
then
    xauth_list=$(xauth nlist $DISPLAY)
    xauth_list=$(sed -e 's/^..../ffff/' <<< "$xauth_list")
    if [ ! -z "$xauth_list" ]
    then
        echo "$xauth_list" | xauth -f $XAUTH nmerge -
    else
        touch $XAUTH
    fi
    chmod a+r $XAUTH
fi

# Prevent executing "docker run" when xauth failed.
if [ ! -f $XAUTH ]
then
  echo "[$XAUTH] was not properly created. Exiting..."
  exit 1
fi

# Obatin docker-ce version for comparison (strip leading info for version number)
DOCKER_VER=$(dpkg-query -f='${Version}' --show docker-ce | sed 's/[0-9]://')
if dpkg --compare-versions 19.03 gt "$DOCKER_VER"
then
    echo "Docker version is less than 19.03, using nvidia-docker2 runtime"
    if ! dpkg --list | grep nvidia-docker2
    then
        echo "Please either update docker-ce to a version greater than 19.03 or install nvidia-docker2"
	exit 1
    fi
    DOCKER_OPTS="--runtime=nvidia"
else
    DOCKER_OPTS="--gpus all"
fi

# Start docker container
echo -e "Starting container image ubuntu18.04:nvros"
read -p "Container name: " CONTAINERNAME

docker run -it \
  -d \
  -e DISPLAY \
  -e QT_X11_NO_MITSHM=1 \
  -e XAUTHORITY=$XAUTH \
  -v "$XAUTH:$XAUTH" \
  -v "/tmp/.X11-unix:/tmp/.X11-unix" \
  -v "/etc/localtime:/etc/localtime:ro" \
  -v "/dev/input:/dev/input" \
  -v $(pwd)/..:/home/developer/docker_mount \
  --network host \
  --privileged \
  --security-opt seccomp=unconfined \
  --name $CONTAINERNAME \
  --cap-add=SYS_PTRACE \
  $DOCKER_OPTS \
  ubuntu18.04:nvros