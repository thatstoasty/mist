#!/bin/bash
mkdir -p tmp

echo -e "Building mist package and copying tests."
./scripts/build.sh package
mv mist.mojopkg tmp/
cp -R tests/ tmp/tests/

echo -e "\nBuilding binaries for all examples."
pytest tmp/tests

echo -e "Cleaning up the test directory."
rm -R tmp
