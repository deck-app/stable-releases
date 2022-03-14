#!/bin/sh
set +x
echo "Running apt update, installing dependencies"
sudo apt update
pkgs='apt-transport-https ca-certificates curl gnupg lsb-release'
if ! dpkg -s $pkgs >/dev/null 2>&1; then
  sudo apt-get install -y $pkgs
fi
#Docker 
# Uninstall old version
pkgs='docker docker-engine docker.io containerd runc'
if ! dpkg -s $pkgs >/dev/null 2>&1; then
  sudo apt-get remove -y $pkgs
fi
sudo apt update
lsb_dist="$(. /etc/os-release && echo "$ID")"
DOWNLOAD_URL="https://download.docker.com"
dist_version=`lsb_release -c | awk '{print $2}'`
curl -fsSL $DOWNLOAD_URL/linux/$lsb_dist/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
echo "Running apt update, installing dependencies"
sudo apt update
pkgs='docker-ce docker-ce-cli containerd.io'
if ! dpkg -s $pkgs >/dev/null 2>&1; then
  sudo apt-get install -y $pkgs
fi
sudo usermod -aG docker $USER
sudo sysctl enable docker
echo "Staring docker";
sudo loginctl enable-linger $(whoami)
echo "sudo chmod 666 /var/run/docker.sock";
sudo chmod 666 /var/run/docker.sock
printf '\nDocker installed successfully\n\n'

printf '\nDECK installation start.....\n\n'
pkgs='deck'
version=$(curl https://get-deck.com/latest.version)
arch=`dpkg --print-architecture`
if ! dpkg -s $pkgs >/dev/null 2>&1; then
wget https://github.com/sfx101/deck/releases/download/$version/DECK-$version-$arch.deb
sudo dpkg -i DECK-$version-$arch.deb
fi
printf '\nDECK installed successfully\n\n'

printf 'Waiting for Docker-composer installation start .... \n\n'
compose=$(wget --quiet --output-document=- https://api.github.com/repos/docker/compose/releases/latest | grep --perl-regexp --only-matching '"tag_name": "\K.*?(?=")')
if [ ! -f /usr/local/bin/docker-compose ]; then
sudo curl -L "https://github.com/docker/compose/releases/download/$compose/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
else
if [ "$compose" -gt `docker-compose --version | awk '{print $4}'` ]
then
echo "Your Docker-compose Older Version, Upgrade Docker-compose"
sudo curl -L "https://github.com/docker/compose/releases/download/$compose/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
fi
fi
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
