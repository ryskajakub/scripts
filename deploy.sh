#!/bin/bash

npm install && npm run build && npm run webpack && npm pack
TARS=`ls -lah scripts-*.tgz | wc -l`

if [ $TARS -eq 1 ] ; then
  mkdir -p scripts-1.0.0-1/var/www/scripts
  cp -R debian/* scripts-1.0.0-1/
  tar -C scripts-1.0.0-1/var/www/scripts -xvzf scripts-*.tgz
  dpkg-deb --build scripts-1.0.0-1
  sudo dpkg -i scripts-1.0.0-1.deb
  rm -rf scripts-*
else
  echo "Didn't found one tgz to copy"
fi
