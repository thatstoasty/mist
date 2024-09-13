#!/bin/bash

TEMP_DIR=~/tmp
PACKAGE_NAME=mist
mkdir -p $TEMP_DIR

echo "[INFO] Building $PACKAGE_NAME package and example binaries."
cp -a examples/. $TEMP_DIR
magic run mojo package src/$PACKAGE_NAME -o $TEMP_DIR/$PACKAGE_NAME.mojopkg
magic run mojo build $TEMP_DIR/hello_world.mojo -o $TEMP_DIR/hello_world
magic run mojo build $TEMP_DIR/profiles.mojo -o $TEMP_DIR/profiles

echo "[INFO] Running examples..."
$TEMP_DIR/hello_world
$TEMP_DIR/profiles

echo "[INFO] Cleaning up the example directory."
rm -R $TEMP_DIR
