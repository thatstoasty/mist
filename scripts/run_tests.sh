#!/bin/bash

TEMP_DIR=~/tmp
CURRENT_DIR=$(pwd)
mkdir -p $TEMP_DIR

echo -e "Building mist package and copying tests."
./scripts/build.sh package
mv mist.mojopkg $TEMP_DIR
cp -R test/ $TEMP_DIR

echo -e "\nBuilding binaries for all examples."
cd $TEMP_DIR
mojo test .
cd $CURRENT_DIR

echo -e "Cleaning up the test directory."
rm -R $TEMP_DIR
