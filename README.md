# MovableType => Hugo migration tool

This scripts will convert a Movable Type 3.x blog to a Hugo-powered site.

There are two scripts included:

* a script to migrate posts from a SQLite MT-schema DB;
* HTML pages statically burned to disk by MT.

**Note:** this README is still incomplete... The scripts are work in progress, they work more or less OK, but still need work. I migrated my own blog with them, you can see it at [www.simplicidade.org](https://www.simplicidade.org).


## Install ##

If you have Docker, the easiest way to use this script is with the image already available on Docker hub.

See usage with Docker below.

If you want to install the app locally, the easiest way is with Carton. It will install all the dependencies in a `local/` directory, and you can run them with `carton exec`.

If you don't have `cpanm`, you can get it by following these quick instructions:

    cd ~/bin
    curl -L https://cpanmin.us/ -o cpanm
    chmod +x cpanm


## Usage ##

On the root of your Hugo site, run:

    movable_type2hugo.pl

WIP...
