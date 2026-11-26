set -eu
install -d -m 0755 /etc/sudoers.d
printf '%s\n' '@@USER@@ ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/90-lab-user
chmod 0440 /etc/sudoers.d/90-lab-user
visudo -cf /etc/sudoers.d/90-lab-user
chown -R @@USER@@:@@USER@@ /home/@@USER@@/.ssh
restorecon -RF /home/@@USER@@/.ssh
systemctl enable serial-getty@ttyS0.service
