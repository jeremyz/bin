#! /bin/sh

BINF=pvpn

wget -O $BINF https://raw.githubusercontent.com/ProtonVPN/protonvpn-cli/master/protonvpn-cli.sh
chmod +x $BINF
sudo mv $BINF /usr/bin
sudo pvpn -init
sudo pvpn -c
echo "STATUS"
sudo pvpn -status
xdg-open https://ipleak.net
