#!/bin/bash

node node_modules/webpack/bin/webpack.js -w &
npm run watch

# kill_all() {
#   kill -9 $BS
#   kill -9 $WEBPACK
# }
# 
# trap kill_all SIGINT SIGTERM
# 
