#!/bin/bash

TEMP_DIR=~/tmp
CURRENT_DIR=$(pwd)
mkdir -p $TEMP_DIR

echo -e "Building mist package and copying tests."
./scripts/build.sh package
mv mist.mojopkg $TEMP_DIR
mv gojo.mojopkg $TEMP_DIR
mv hue.mojopkg $TEMP_DIR
cp -R tests/ $TEMP_DIR/tests/

echo -e "\nBuilding binaries for all examples."
cd $TEMP_DIR
pytest tests
cd $CURRENT_DIR

echo -e "Cleaning up the test directory."
rm -R $TEMP_DIR
