DOCKER_IMAGE = detour_tester

.PHONY : test

image: Dockerfile
	docker build -t ${DOCKER_IMAGE} .
	touch image

test: image
	docker run --volume="$(shell pwd):/mnt/luarocks:Z" ${DOCKER_IMAGE} /mnt/luarocks/run-in-docker.sh
