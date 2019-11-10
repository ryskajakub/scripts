#!/bin/bash

npm install && npm run build && npm run webpack && npm pack
TARS=`ls -lah scripts-*.tgz | wc -l`

if [ $TARS -eq 1 ] ; then
  mkdir -p scripts-1.0.0-1/var/www/scripts
  cp -R debian/* scripts-1.0.0-1/
  tar -C scripts-1.0.0-1/var/www/scripts -xvzf scripts-*.tgz
  sudo chown -R root:wheel scripts-1.0.0-1
  dpkg-deb --build scripts-1.0.0-1
  scp scripts-1.0.0-1.deb coub@ryskajakub.name:~
  ssh coub@ryskajakub.name 'sudo dpkg -i ~/scripts-1.0.0-1.deb && cd /var/www/scripts/package && sudo npm install --only=production && sudo systemctl daemon-reload && sudo systemctl restart scripts'
  sudo rm -rf scripts-*
else
  echo "Didn't found one tgz to copy"
fi
