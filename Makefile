DOCKER_IMAGE = detour_tester

.PHONY : test

image: Dockerfile
	docker build -t ${DOCKER_IMAGE} .
	touch image

test: image
	docker run --volume="$(shell pwd):/mnt/luarocks:Z" ${DOCKER_IMAGE} /mnt/luarocks/run-in-docker.sh

.PHONY: help
# Ensure init.lua is processed first. Exclude internal helpers from docs.
HELP_LUA_ALL := $(wildcard lua/detour/*.lua)
# Space-separated list of files to exclude from lemmy-help
HELP_EXCLUDE := lua/detour/internal.lua \
                lua/detour/windowing_algorithm.lua \
                lua/detour/config.lua \
                lua/detour/util.lua \
                lua/detour/show_path_in_title.lua
HELP_LUA_SRCS := $(filter-out $(HELP_EXCLUDE),$(HELP_LUA_ALL))
help:
	# Generate help docs via lemmy-help from Lua sources (with excludes)
	@mkdir -p doc
	lemmy-help lua/detour/init.lua $(filter-out lua/detour/init.lua,$(HELP_LUA_SRCS)) > doc/detour.txt
	# Rebuild helptags (optional)
	@nvim --headless -c 'silent! helptags doc' -c 'q' || true
