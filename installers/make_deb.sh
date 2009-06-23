#!/bin/sh
# Debian/Ubuntu package builder

# Configure control folder and file
mkdir -p ./build/tmp/prey
cp -r DEBIAN ./build/tmp/prey/

mkdir -p ./build/tmp/prey/usr/share/prey

cp ../prey.sh ./build/tmp/prey/usr/share/prey/
cp ../config ./build/tmp/prey/usr/share/prey/
cp -r ../lang ./build/tmp/prey/usr/share/prey/
cp -r ../platform ./build/tmp/prey/usr/share/prey/
cp -r ../modules ./build/tmp/prey/usr/share/prey/

# Make the deb package
dpkg-deb -b ./build/tmp/prey ./build

mv build/*.deb .
# Remove temporary directory
rm -rf ./build

