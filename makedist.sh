#!/bin/bash

LASTCHANGE=`svnversion .`
CURRENTVERSION=`grep "version = \"" src/colloquy.lua | sed -e's/   version = \"//' -e's/\.\!\!\!\",//'`

make dist-clean
svn export . /tmp/colloquy-$CURRENTVERSION.$LASTCHANGE
sed -i 's/\!\!\!/'"$LASTCHANGE"'/' /tmp/colloquy-$CURRENTVERSION.$LASTCHANGE/src/colloquy.lua
rm -f /tmp/colloquy-$CURRENTVERSION.$LASTCHANGE/makedist.sh
svn log . > /tmp/colloquy-$CURRENTVERSION.$LASTCHANGE/docs/CHANGES
pushd /tmp
tar c colloquy-$CURRENTVERSION.$LASTCHANGE/ | taranon | bzip2 > colloquy-$CURRENTVERSION.$LASTCHANGE.tar.bz2
popd
mv /tmp/colloquy-$CURRENTVERSION.$LASTCHANGE.tar.bz2 ..
rm -rf /tmp/colloquy-$CURRENTVERSION.$LASTCHANGE
