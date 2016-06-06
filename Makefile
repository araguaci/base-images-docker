DEBIAN_SUITE=jessie
DEBIAN_MIRROR=http://gce_debian_mirror.storage.googleapis.com/
DOCKER_REPO=google/debian
ROOTFS_TAR=google-debian-${DEBIAN_SUITE}.tar.bz2

# Builder image configuration
BUILDER_ID=google/debian-builder
BUILDER_NAME=builder
DOCKER_VERSION=1.11.2


.PHONY: docker-image builder clean

all: docker-image

docker-image: ${ROOTFS_TAR}
	docker build -t ${DOCKER_REPO}:${DEBIAN_SUITE} .

${ROOTFS_TAR}: builder
	@# Ensure an old builder isn't sitting around
	docker rm --volumes $(BUILDER_NAME) || true
	@# We need to run the builder in privileged mode so it can run
	@# chroot as part of debootstrap
	docker run \
		--name $(BUILDER_NAME) \
		-it \
		--privileged \
		--volume /var/$(DEBIAN_SUITE) \
		$(BUILDER_ID) \
			-d /var/$(DEBIAN_SUITE) \
			--compression bz2 \
			debootstrap \
			--variant=minbase \
			$(DEBIAN_SUITE) \
			$(DEBIAN_MIRROR)
	docker cp builder:/var/$(DEBIAN_SUITE)/rootfs.tar.bz2 $@
	docker rm --volumes $(BUILDER_NAME)

clean:
	rm -f ${ROOTFS_TAR}
	docker rm --volumes $(BUILDER_NAME) || true
	docker rmi $(BUILDER_ID) || true

builder:  ## Create a builder image for easy generation of base images
	cd builder && docker build \
		-t $(BUILDER_ID) \
		--build-arg DOCKER_VERSION=$(DOCKER_VERSION) \
		--file builder.Dockerfile .
