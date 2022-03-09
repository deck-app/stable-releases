#!/bin/sh
#Set up the required package
echo "Running apt update, installing dependencies"
sudo apt update
pkgs='curl uidmap apt-transport-https ca-certificates gnupg lsb-release docker.io neofetch docker-compose docker-ce docker-ce-cli containerd.io'
if ! dpkg -s $pkgs >/dev/null 2>&1; then
  sudo apt-get install -y $pkgs
fi
pkgs='deck'
version=$(curl https://get-deck.com/latest.version)
arch=`dpkg --print-architecture`
if ! dpkg -s $pkgs >/dev/null 2>&1; then
  wget https://github.com/sfx101/deck/releases/download/$version/DECK-$version-$arch.deb
  sudo dpkg -i DECK-$version-$arch.deb
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
sudo wget https://raw.githubusercontent.com/deck-app/multipass-install/master/override.conf
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo cp override.conf /etc/systemd/system/docker.service.d/override.conf
compose=$(wget --quiet --output-document=- https://api.github.com/repos/docker/compose/releases/latest | grep --perl-regexp --only-matching '"tag_name": "\K.*?(?=")')
sudo curl -L "https://github.com/docker/compose/releases/download/$compose/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo rm -rf override.conf
sudo setcap 'cap_net_bind_service=+eip' /opt/DECK/deck
sudo sh -c "echo '/opt/DECK/' >> /etc/ld.so.conf.d/deck.conf"
sudo ldconfig
systemctl --user start docker
systemctl --user enable docker
# clear
# neofetch
echo "Reloading systemd manager configuration ...";
sudo systemctl daemon-reload
sudo systemctl restart docker.service
echo "Installation has finished";