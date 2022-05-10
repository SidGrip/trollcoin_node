#!/bin/bash

## THIS IS INTENDED ONLY TO BE USED ON UBUNTU 14.04.6 - OTHER VERSIONS MAY NOT WORK ##
## RUN 'bash ./TrollCoin-2.0_Ubuntu-14.04.6_Auto.sh' TO EXECUTE IT ##
## EVERYTHING IS RUN AS USER ENTER SUDO PASS WHEN PROMPTED ##
## THIS WILL AUTOMATICALLY GRAB ALL DEPENDENCIES - INCLUDING GIT - AND DOWNLOAD/COMPILE THE QT WALLET ##
## THIS WILL CREATE A CONFIG FILE & GIVE THE OPTION TO DOWNLOAD BOOTSTRAP ##
## THIS WILL PLACE A SHORTCUT IN YOUR APPLICATIONS ##

FTP='https://bootstrap.specminer.com/Trollcoin'
USER=$(whoami)
USERDIR=$(eval echo ~$USER)
STRAP='bootstrap.dat'
CONF='trollcoin.conf'
DIR='.trollcoin'
NAME='TrollCoin'
RPC_PORT='17000'
P2P_PORT='15000'
UYellow='\033[4;33m'
NC='\033[0m'

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec &> >(tee setup.log) 2>&1
# Everything below will go to the file 'setup.log':

function troll_install() {
echo "Updating apt repository listings..."
sleep 3
sudo su - <<EOF
apt-get update -y
echo "Installing dependencies + Git..."
sleep 3
apt-get install make libqt5webkit5-dev libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools qtcreator libprotobuf-dev protobuf-compiler build-essential libboost-dev libboost-all-dev libboost-system-dev libboost-filesystem-dev libboost-program-options-dev libboost-thread-dev libssl-dev libdb++-dev libstdc++6 libminiupnpc-dev libevent-dev libcurl4-openssl-dev git libpng-dev qrencode libqrencode-dev git -y
EOF
mkdir $USERDIR/$DIR
echo "Getting TrollCoin-2.0 source..."
sleep 3
git clone https://github.com/TrollCoin2/TrollCoin-2.0.git

cd ~/TrollCoin-2.0/
echo "Starting build procedure..."
sleep 3
qmake -qt=qt5 "USE_QRCODE=1" "USE_UPNP=1"
make
mv $NAME $USERDIR/$DIR
}

function troll_config() {
#Create Config File
echo -e "Creating TrollCoin config file"
# Get list of curent active nodes from chainz block explorer sort and save to var
NODES=$(curl -s https://chainz.cryptoid.info/troll/api.dws?q=nodes)
PEERS=$(grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' <<< "$NODES" | sed -e 's/^/addnode=/')
# Generate Random RPC User/Pass for Config File
RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $USERDIR/$DIR/$CONF
maxconnections=25
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcport=$RPC_PORT
port=$P2P_PORT
$PEERS
EOF
}

function bootstrap() {
#Option to download Bootstrap
progressfilt ()
{
    local flag=false c count cr=$'\r' nl=$'\n'
    while IFS='' read -d '' -rn 1 c
    do
        if $flag
        then
            printf '%s' "$c"
        else
            if [[ $c != $cr && $c != $nl ]]
            then
                count=0
            else
                ((count++))
                if ((count > 1))
                then
                    flag=true
                fi
            fi
        fi
    done
}
clear
while true; do
    read -p "Download $NAME $STRAP? (Y or N)" yn
    case $yn in
        [Yy]* ) wget --progress=bar:force -O $USERDIR/$DIR/$STRAP $FTP/$STRAP 2>&1 | progressfilt; break;;
        [Nn]* ) echo You must like waiting a long time for shit to sync; break;;
        * ) echo "Please answer yes or no.";;
    esac
done
clear
}

function troll_cut() {
#Create .desktop app to launch trollcoin
echo -e "Creating $NAME Desktop Applicatoin Shortcut"
wget -O $USERDIR/$DIR/trollcoin.png $FTP/trollcoin.png >/dev/null 2>&1
clear
cat << EOF > $USERDIR/.local/share/applications/TrollCoin.desktop
[Desktop Entry]
Name=TrollCoin
Version=v2.1
Icon=$USERDIR/$DIR/trollcoin.png
Exec=$USERDIR/$DIR/TrollCoin
Terminal=false
Type=Application
Categories=Applicatoin
Keywords=TrollCoin
EOF
sudo chmod +x $USERDIR/.local/share/applications/TrollCoin.desktop
sudo update-desktop-database
rm -r -f $USERDIR/TrollCoin-2.0
clear
echo -e "TrollCoin wallet is ready for use! Search you applications for ${UYellow}TrollCoin${NC}"
}

function setup_node() {
  troll_install
  troll_config
  bootstrap
  troll_cut
}

##### Main #####
clear
setup_node
