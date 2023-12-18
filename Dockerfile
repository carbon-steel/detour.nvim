# Base image which includes busted.
# Only available platform.
FROM --platform=linux/amd64 ghcr.io/lunarmodules/busted:v2.2.0 AS busted

FROM --platform=linux/amd64 alpine:3.18 AS final

COPY --from=busted /usr/local /usr/local

ENV WITH_LUA /usr/local/
ENV LUA_LIBDIR /usr/local/lib/lua
ENV LUA_INCDIR /usr/local/include

ENV LUA_MAJOR_VERSION 5.4
ENV LUA_MINOR_VERSION 4
ENV LUA_VERSION ${LUA_MAJOR_VERSION}.${LUA_MINOR_VERSION}

RUN apk add 'neovim>0.9'

WORKDIR /data
ENTRYPOINT ['run-in-docker.sh']
