#!/bin/bash

# Copy plugins
mkdir -p ~/.local/share/gedit/plugins/
cp -vnpr gedit/ ~/.local/share/

# Copy schemas
sudo cp -vnpr schemas/* /usr/share/glib-2.0/schemas/

# Compile Schemas
sudo glib-compile-schemas /usr/share/glib-2.0/schemas/

