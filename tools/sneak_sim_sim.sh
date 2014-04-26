#!/bin/sh
SAVED=`pwd`
cd ../sim-sim-js && \
grunt build && \
cd $SAVED && \
rm -rf node_modules/sim-sim-js && \
cp -r ../sim-sim-js/build ./node_modules/sim-sim-js
