#!/bin/sh
git push origin master
git push github master
jekyll build
scp -r _site/* root@www.mysys.top:/var/www/www.mysys.top