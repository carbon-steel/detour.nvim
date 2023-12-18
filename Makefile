DOCKER_IMAGE = detour_tester

build:
	docker build -t ${DOCKER_IMAGE} .

test:
	docker run --platform=linux/amd64 --entrypoint=/bin/sh -i --volume="$(shell pwd):/data:Z" ${DOCKER_IMAGE}
