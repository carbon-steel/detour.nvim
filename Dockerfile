FROM alpine:3.22

ENV LUA_MAJOR_VERSION 5.1
ENV LUA_MINOR_VERSION 5
ENV LUA_VERSION ${LUA_MAJOR_VERSION}.${LUA_MINOR_VERSION}

# Dependencies
RUN apk update && apk add --update make tar unzip gcc openssl-dev readline-dev curl libc-dev
RUN apk add wget # Needed due to https://github.com/luarocks/luarocks/issues/952

RUN curl -L http://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz | tar xzf -
WORKDIR /lua-$LUA_VERSION

# build lua
RUN make linux test
RUN make install

WORKDIR /

# lua env
ENV WITH_LUA /usr/local/
ENV LUA_LIB /usr/local/lib/lua
ENV LUA_INCLUDE /usr/local/include


RUN rm /lua-$LUA_VERSION -rf

ENV LUAROCKS_VERSION 3.9.2
ENV LUAROCKS_INSTALL luarocks-$LUAROCKS_VERSION
ENV TMP_LOC /tmp/luarocks

# Build Luarocks
RUN curl -OL \
    https://luarocks.org/releases/${LUAROCKS_INSTALL}.tar.gz

RUN tar xzf $LUAROCKS_INSTALL.tar.gz && \
    mv $LUAROCKS_INSTALL $TMP_LOC && \
    rm $LUAROCKS_INSTALL.tar.gz


WORKDIR $TMP_LOC

RUN ./configure \
  --with-lua=$WITH_LUA \
  --with-lua-include=$LUA_INCLUDE \
  --with-lua-lib=$LUA_LIB

RUN make build

RUN make install

WORKDIR /

RUN rm $TMP_LOC -rf

WORKDIR /mnt/luarocks

RUN apk add 'neovim=0.11.1-r1'
ENV BUSTED_VERSION 2.1.2-3
RUN luarocks install busted $BUSTED_VERSION
