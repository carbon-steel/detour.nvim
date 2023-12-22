DOCKER_IMAGE = detour_tester

build:
	docker build -t ${DOCKER_IMAGE} .

test:
	docker run --volume="$(shell pwd):/mnt/luarocks:Z" ${DOCKER_IMAGE} /mnt/luarocks/run-in-docker.sh
