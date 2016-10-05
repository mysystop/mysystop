#!/bin/sh
jekyll build
scp -r _site/* root@www.mysys.top:/var/www/www.mysys.top