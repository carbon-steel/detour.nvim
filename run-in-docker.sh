#!/bin/sh
nvim -u NONE \
  -c "lua local k,l,_=pcall(require,'luarocks.loader') _=k and l.add_context('busted','$BUSTED_VERSION')" \
  -l "/usr/local/lib/luarocks/rocks-5.1/busted/$BUSTED_VERSION/bin/busted" .
