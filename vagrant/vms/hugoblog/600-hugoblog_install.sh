# install hugo
/usr/bin/pacman -S --noconfirm hugo

# check out repository
echo '==> Checking out repository'
cd /home/${LUSER}
$AS /usr/bin/git clone git@github.com:drseergio/drseergio.github.com.git hugoblog
cd /home/${LUSER}/hugoblog
$AS git checkout source
$AS git worktree add -B master public origin/master
