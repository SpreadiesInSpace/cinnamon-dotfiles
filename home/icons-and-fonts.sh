#!/bin/bash

mkdir tmp
git clone https://github.com/SpreadiesInSpace/cinnamon-extras tmp
rm -rf tmp/.git
cp -npr tmp/.* .
rm -rf tmp/
