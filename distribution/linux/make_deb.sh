#!/bin/sh
# Debian Package Builder, by Tomas Pollak

version="0.3.1"

if [ `whoami` != 'root' ]; then
	echo 'Since we need to set up root permissions you need to run this as root. A simple "sudo" will do. :)'
	exit
fi

cwd=`pwd`

while [ ! -f prey.sh ]; do
	cd ..
done

basedir=`pwd`
cd $cwd

# Remove temporary directory and .DEBs
rm -rf ./build
rm *.deb 2> /dev/null
rm *.zip 2> /dev/null

# Configure control folder and file
mkdir -p ./build/tmp/prey
cp -r DEBIAN ./build/tmp/prey/

# copying the base dir stuff
mkdir -p ./build/tmp/prey/usr/share/prey
cp $basedir/prey.sh ./build/tmp/prey/usr/share/prey/
cp $basedir/config ./build/tmp/prey/usr/share/prey/
cp $basedir/configure.py ./build/tmp/prey/usr/share/prey/
cp -r $basedir/lib ./build/tmp/prey/usr/share/prey/
cp -r $basedir/lang ./build/tmp/prey/usr/share/prey/
cp -r $basedir/platform ./build/tmp/prey/usr/share/prey/
cp -r $basedir/pixmaps ./build/tmp/prey/usr/share/prey/

# add available modules
mkdir -p ./build/tmp/prey/usr/share/prey/modules
cp -r $basedir/modules/alert ./build/tmp/prey/usr/share/prey/modules
# cp -r $basedir/modules/geo ./build/tmp/prey/usr/share/prey/modules
cp -r $basedir/modules/network ./build/tmp/prey/usr/share/prey/modules
cp -r $basedir/modules/session ./build/tmp/prey/usr/share/prey/modules
cp -r $basedir/modules/webcam ./build/tmp/prey/usr/share/prey/modules

# remove unneeded files
rm -f `find build/tmp/prey/usr/share/prey -name "*~"`
rm -f `find build/tmp/prey/usr/share/prey -name "windows"`
rm -f `find build/tmp/prey/usr/share/prey -name "*.exe"`
rm -f `find build/tmp/prey/usr/share/prey -name "*.dll"`

cp $basedir/CHANGELOG ./build/tmp/prey/usr/share/prey/
cp $basedir/LICENSE ./build/tmp/prey/usr/share/prey/
cp $basedir/README ./build/tmp/prey/usr/share/prey/

cp -r build/tmp/prey/usr/share/prey .
zip -9 -r prey-$version-linux.zip prey -x \*darwin* 1> /dev/null
echo "Built Linux .zip package in prey-$version-linux.zip"
zip -9 -r prey-$version-darwin.zip prey -x \*linux* -x \*configure.py 1> /dev/null
echo "Built Darwin .zip package in prey-$version-darwin.zip"
rm -r prey

# lets copy the config shortcut
mkdir -p ./build/tmp/prey/usr/share/applications
cp prey-config.desktop ./build/tmp/prey/usr/share/applications

sudo chown root.root ./build/tmp/prey/usr/share/prey -R

# Make the deb package
dpkg-deb -b ./build/tmp/prey ./build

mv build/*.deb .
# Remove temporary directory
sudo rm -rf ./build
