#!/bin/bash
mkdir ./temp
mojo package mist -I ./external -o ./temp/mist.mojopkg

echo -e "Building binaries for all examples...\n"
mojo build examples/hello_world/hello_world.mojo -o temp/hello_world
mojo build tests/test_renderers.mojo -o temp/renderers
mojo build tests/test_profiles.mojo -o temp/profiles

echo -e "Executing examples...\n"
cd temp
./hello_world
./renderers
./profiles

cd ..
rm -R ./temp
