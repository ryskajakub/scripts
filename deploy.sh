#!/bin/bash

#&npm run clean && npm run build && npm run webpack && npm pack

TARS=`ls -lah scripts-*.tgz | wc -l`

if [ $TARS -eq 1 ] ; then
  cp -R ~/debian/* scripts-1.0.0-1/
  mkdir -p scripts-1.0.0-1/var/www/scripts
  tar -C scripts-1.0.0-1/var/www/scripts -xvzf scripts-*.tgz
else
  echo "Didn't found one tgz to copy"
fi
