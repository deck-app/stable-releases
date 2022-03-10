#!/bin/sh
#Set up the required package
echo "Running apt update, installing dependencies"
sudo apt update
pkgs='curl uidmap apt-transport-https ca-certificates gnupg lsb-release docker.io docker-compose'
if ! dpkg -s $pkgs >/dev/null 2>&1; then
  sudo apt-get install -y $pkgs
fi
pkgs='deck'
version='4.0.0'
arch='amd64'
if ! dpkg -s $pkgs >/dev/null 2>&1; then
  wget https://github.com/deck-app/stable-releases/releases/download/v4.0.0/DECK-$version-linux-$arch.deb
  sudo dpkg -i DECK-$version-linux-$arch.deb
fi
export PATH=/home/$USER/bin:$PATH
export DOCKER_HOST=unix:///run/user/$USER/docker.sock
#List the versions available in your repo
apt-cache madison docker-ce
sudo usermod -aG docker $USER

echo "Staring docker";
sudo loginctl enable-linger $(whoami)
echo "sudo chmod 666 /var/run/docker.sock";
sudo chmod 666 /var/run/docker.sock
compose=$(wget --quiet --output-document=- https://api.github.com/repos/docker/compose/releases/latest | grep --perl-regexp --only-matching '"tag_name": "\K.*?(?=")')
sudo curl -L "https://github.com/docker/compose/releases/download/$compose/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo rm -rf override.conf
sudo setcap 'cap_net_bind_service=+eip' /opt/DECK/deck
sudo sh -c "echo '/opt/DECK/' >> /etc/ld.so.conf.d/deck.conf"
sudo ldconfig
# clear
# neofetch
echo "Reloading systemd manager configuration ...";
sudo systemctl daemon-reload
sudo systemctl restart docker.service
sudo setfacl -m user:$USER:rw /var/run/docker.sock
echo "Installation has finished";
