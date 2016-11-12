#!/bin/bash
if hash bundle 2>/dev/null; then
    bundle exec ruby app.rb "$@"
else
    echo "Please install bundler(https://bundler.io) with `gem install bundler` and run this script again"
fi
