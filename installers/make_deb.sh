#!/bin/sh
# Debian Package Builder, by Tomas Pollak

# Remove temporary directory
rm -rf ./build
rm *.deb 2> /dev/null

# Configure control folder and file

mkdir -p ./build/tmp/prey
cp -r DEBIAN ./build/tmp/prey/

mkdir -p ./build/tmp/prey/usr/share/prey
cp ../prey.sh ./build/tmp/prey/usr/share/prey/
cp ../config ./build/tmp/prey/usr/share/prey/
cp ../configure.py ./build/tmp/prey/usr/share/prey/
cp -r ../lang ./build/tmp/prey/usr/share/prey/
cp -r ../platform ./build/tmp/prey/usr/share/prey/
cp -r ../modules ./build/tmp/prey/usr/share/prey/
cp -r ../pixmaps ./build/tmp/prey/usr/share/prey/

cp ../CHANGELOG ./build/tmp/prey/usr/share/prey/
cp ../LICENSE ./build/tmp/prey/usr/share/prey/
cp ../README ./build/tmp/prey/usr/share/prey/

# lets copy the config shortcut
mkdir -p ./build/tmp/prey/usr/share/applications
cp prey-config.desktop ./build/tmp/prey/usr/share/applications

# Make the deb package
dpkg-deb -b ./build/tmp/prey ./build

mv build/*.deb .
# Remove temporary directory
rm -rf ./build

