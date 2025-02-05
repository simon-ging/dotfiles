#!/usr/bin/env bash

# create .tar.zst archives

# https://linuxnightly.com/how-to-use-zstandard-compression-on-linux-with-commands/
# We recommend using the default level of 3 or a level in the range from 6 to 9
# for a reasonable tradeoff between compression speed and compressed data size.
# Reserve levels 20 and greater for cases where size is most important and
# compression speed is not a concern.
alias tarzstd="tar --zstd -cvf"
alias tarzstd9="tar -I \'zstd -9\' -cvf"
alias tarzstd19="tar -I \'zstd -19\' -cvf"
alias tarzstd22="tar -I \'zstd --ultra -22\' -cvf"
alias tarzstdf="tar -I \'zstd --fast=1\' -cvf"
alias tarzstdf9="tar -I \'zstd --fast=9\' -cvf"
# seems, there is no limit on how high --fast can go
# but at somepoint it just doesn't compress anymore
