#!/bin/bash

# Update last install date in repository README.

# run and execute from configuration scripts (not to be invoked directly): $ curl -L v-u.cc/report | sh

echo '==> Updating Last install date in the repo'
cd /home/${LUSER}
$AS /usr/bin/git clone git@github.com:pisarenko-net/arch-bootstrapper.git arch-bootstrapper-update
cd /home/${LUSER}/arch-bootstrapper-update
TODAY=`date +%Y-%m-%d`
$AS sed -i "s/${README_ENTRY} Last Installed.*/${README_ENTRY} Last Installed **${TODAY}**/" README.md
$AS /usr/bin/git add .
$AS /usr/bin/git commit -m "successful ${README_ENTRY} install"
$AS /usr/bin/git push
/usr/bin/rm -rf /home/${LUSER}/arch-bootstrapper-update
