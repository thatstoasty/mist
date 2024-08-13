#!/bin/bash
mkdir ./tmp
mojo package mist -o ./tmp/mist.mojopkg

echo -e "Building binaries for all examples...\n"
mojo build examples/hello_world.mojo -o tmp/hello_world
mojo build examples/profiles.mojo -o tmp/profiles

echo -e "Executing examples...\n"
cd tmp
./hello_world
./profiles

cd ..
rm -R ./tmp
