# MovableType => Hugo migration tool

This script will convert a SQLite DB from a Movable Type 3.x blog to a Hugo-powered site.

## Install ##

If you have Docker, the easiest way to use this script is with the image already available on Docker hub.

See usage with Docker below.

If you want to install the app locally, run `cpanm App::MovableType2Hugo`. It will install the command and all the dependencies.

If you don't have `cpanm`, you can get it by following these quick instructions:

    cd ~/bin
    curl -L https://cpanmin.us/ -o cpanm
    chmod +x cpanm


## Usage ##

On the root of your Hugo site, run:

    movable_type2hugo.pl

WIP...
