#!/bin/bash

cd
mkdir -p essproj
cd essproj
git clone https://www.github.com/event-formation-unit
mkdir -p event-formation-unit/build
cd event-formation-unit/build
conan install --build=missing --build=boost_system --build=boost_filesystem --build=flatbuffers ..
cmake ..
make
