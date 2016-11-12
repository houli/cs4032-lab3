#!/bin/bash
if hash bundle 2>/dev/null; then
    bundle install
else
    echo "Please install bundler(https://bundler.io) with `gem install bundler` and run this script again"
fi
