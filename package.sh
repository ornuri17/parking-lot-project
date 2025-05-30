#!/bin/bash

# Clean up any existing package
rm -f app.tar.gz

# Create a temporary directory
mkdir -p .tmp_package/src

# Copy necessary files
cp -r src/* .tmp_package/src/
cp package.json .tmp_package/
cp package-lock.json .tmp_package/
cp tsconfig.json .tmp_package/

# Create tarball
cd .tmp_package
tar -czf ../app.tar.gz .
cd ..

# Clean up
rm -rf .tmp_package 