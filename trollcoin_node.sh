#!/bin/bash
FTP='ftp://78.141.243.202'
USER=$(whoami)
USERDIR=$(eval echo ~$user)
STRAP='bootstrap.dat'
COIN_PATH='/usr/local/bin'

#TrollCoin
TROLL_DAEMON='https://github.com/SidGrip/trollcoin_node/releases/download/v2.1/trollcoind'
TROLL_TMP_FOLDER=$(mktemp -d)
TROLL_CONFIG_FILE='trollcoin.conf'
TROLL_CONFIGFOLDER='.trollcoin'
TROLL_COIN_DAEMON='trollcoind'
TROLL_COIN_NAME='Trollcoin'
TROLL_RPC_PORT='17000'
TROLL_COIN_PORT='15000'
TROLL_PEERS=$(curl -s$ $FTP/$TROLL_COIN_NAME/$PEERS)

BBlue='\033[1;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
WHITE='\033[1;97m'
YELLOW='\033[0;93m'
NC='\033[0m'

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec &> >(tee setup.log) 2>&1
# Everything below will go to the file 'setup.log':

function checks() {
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi
}

function prepare_system() {
echo -e "Preparing to install ${YELLOW}$TROLL_COIN_NAME ${NC}Node."
apt-get update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
apt install -y software-properties-common >/dev/null 2>&1
echo -e "${WHITE}Thanks for Supporting ${YELLOW}$TROLL_COIN_NAME"
apt-add-repository -y ppa:bitcoin/bitcoin >/dev/null 2>&1
echo -e "${GREEN}Installing required packages, it may take some time to finish.${NC}"
apt-get update >/dev/null 2>&1
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" libdb4.8-dev libdb4.8++-dev libdb5.3++ libminiupnpc-dev libboost-all-dev >/dev/null 2>&1
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt -y install software-properties-common"
    echo "apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "apt-get update"
    echo "apt install -y libdb4.8-dev libdb4.8++-dev libdb5.3++ libminiupnpc-dev libboost-all-dev"
 exit 1
fi
clear
}

function swap() {
#checking for swapfile
if free | awk '/^Swap:/ {exit !$2}'; then
    echo "Swapfile already exist"
sleep 2
clear
else	
    echo "Creating Swap"
    rm -f /var/troll_swap.img
    dd if=/dev/zero of=/var/troll_swap.img bs=1024k count=500
    chmod 0600 /var/troll_swap.img
    mkswap /var/troll_swap.img
    swapon /var/troll_swap.img
    echo '/var/troll_swap.img none swap sw 0 0' | tee -a /etc/fstab
    echo 'vm.swappiness=10' | tee -a /etc/sysctl.conf               
    echo 'vm.vfs_cache_pressure=50' | tee -a /etc/sysctl.conf
fi
clear
}

function troll_install()  {
#check for external ip & select correct nodes
IP4=$(ifconfig  | grep 'inet addr:' | grep -v '127.0.0.1' | awk -F: '{print $2}' | awk '{print $1}' | head -1)

IP6=$(/sbin/ip -6 addr | grep inet6 | awk -F '[ \t]+|/' '{print $3}' | grep -v ^::1 | grep -v ^fe80)

if [[ -n $IP4 ]] && [[ -n $IP6 ]]; then 
echo "Both IPv4 - $IP4 & Ipv6 - $IP6"
echo "Address's detected, Will setup config with both Nodes"
PEERS=$(curl -s$ $FTP/$TROLL_COIN_NAME/{seed_ipv6.txt,seed_ipv4.txt})

elif [[ $IP4 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
echo "$IP IPv4"
PEERS=$(curl -s$ $FTP/$TROLL_COIN_NAME/seed_ipv4.txt)

elif [[ $IP6 =~ "${1#*:[0-9a-fA-F]}" ]]; then
echo "$IP IPv6"
PEERS=$(curl -s$ $FTP/$TROLL_COIN_NAME/seed_ipv6.txt)

else
echo No IP Found
fi

clear

#Setup Firewall
 echo -e "Setting up firewall ${GREEN}$COIN_PORT${NC}"
  ufw allow $TROLL_COIN_PORT/tcp comment "$TROLL_COIN_NAME" >/dev/null

#Make Coin Directory
mkdir $USERDIR/$TROLL_CONFIGFOLDER >/dev/null 2>&1

#Create Config File
echo -e "Creating $TROLL_COIN_NAME config file"
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $USERDIR/$TROLL_CONFIGFOLDER/$TROLL_CONFIG_FILE
maxconnections=12
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcport=$TROLL_RPC_PORT
port=$TROLL_COIN_PORT
$PEERS
EOF

#Downloading Bootstrap
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
    read -p "Download $TROLL_COIN_NAME Bootstrap? (Y or N)" yn
    case $yn in
        [Yy]* ) wget --progress=bar:force -O $USERDIR/$TROLL_CONFIGFOLDER/$STRAP $FTP/$TROLL_COIN_NAME/$STRAP 2>&1 | progressfilt; break;;
        [Nn]* ) echo You must like waiting a long time for shit to sync; break;;
        * ) echo "Please answer yes or no.";;
    esac
done
clear
#Download precompiled daemon
  echo -e "Installing ${YELLOW}$TROLL_COIN_NAME${WHITE} Daemon${NC}."
 wget --progress=bar:force -O $COIN_PATH/$TROLL_COIN_DAEMON $TROLL_DAEMON 2>&1 | progressfilt;
 sleep 2
 chmod +x $COIN_PATH/$TROLL_COIN_DAEMON
  clear

#Create system servivce
  cat << EOF > /etc/systemd/system/$TROLL_COIN_NAME.service
[Unit]
Description=$TROLL_COIN_NAME service
After=network.target
[Service]
User=root
Group=root
Type=forking
#PIDFile=$USERDIR/$TROLL_CONFIGFOLDER/$TROLL_COIN_NAME.pid
ExecStart=$COIN_PATH/$TROLL_COIN_DAEMON -daemon -conf=$USERDIR/$TROLL_CONFIGFOLDER/$TROLL_CONFIG_FILE -datadir=$USERDIR/$TROLL_CONFIGFOLDER
ExecStop=$COIN_PATH/$TROLL_COIN_DAEMON -conf=$USERDIR/$TROLL_CONFIGFOLDER/$TROLL_CONFIG_FILE -datadir=$USERDIR/$TROLL_CONFIGFOLDER stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=2
CPUQuota=60%
[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 4
  systemctl start $TROLL_COIN_NAME.service
  systemctl enable $TROLL_COIN_NAME.service >/dev/null 2>&1

  if [[ -z "$(ps axo cmd:100 | egrep $TROLL_COIN_DAEMON)" ]]; then
    echo -e "${RED}$TROLL_COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start $TROLL_COIN_NAME.service"
    echo -e "systemctl status $TROLL_COIN_NAME.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
    fi
echo -e "Starting $TROLL_COIN_NAME Daemon"
sleep 4 
rm $USERDIR/$TROLL_CONFIGFOLDER/debug.log
}

important_information() {
clear
if [ -f "/etc/systemd/system/$TROLL_COIN_NAME.service" ]; then
echo -e "================================================================================================================================"
 echo -e "${YELLOW}$TROLL_COIN_NAME Node is up and running listening on port ${GREEN}$TROLL_COIN_PORT${NC}."
 echo -e "Configuration file is: ${RED}$TROLL_CONFIGFOLDER/$TROLL_CONFIG_FILE${NC}"
 echo -e "Start: ${RED}systemctl start $TROLL_COIN_NAME.service${NC}"
 echo -e "Stop: ${RED}systemctl stop $TROLL_COIN_NAME.service${NC}"
 echo -e "Please check ${GREEN}$TROLL_COIN_NAME${NC} daemon is running with the following command: ${BBlue}systemctl status $TROLL_COIN_NAME.service${NC}"
 fi
echo -e "================================================================================================================================"
echo -e "${YELLOW}===============================================   ${WHITE}Finishing up Please Wait${NC}   ${YELLOW}===================================================${NC}"
}
function bootstrap_script() {
if [ -f "$USERDIR/$TROLL_CONFIGFOLDER/$STRAP" ]; then
cat << 'EOT' > $USERDIR/bootstrap.sh
#!/bin/bash
USER=$(whoami)
USERDIR=$(eval echo ~$user)
TROLL_CONFIGFOLDER='.trollcoin'
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec &> >(tee $USERDIR/bootstrap.log) 2>&1
# Everything below will go to the file '$USERDIR/bootstrap.log':
date +%d/%m/%Y%t%H:%M:%S
#Checking for Bootstrap
if [ -f "$USERDIR/$TROLL_CONFIGFOLDER/bootstrap.dat" ]; then
echo "Trollcoin still importing bootstrap"
else [ -f "$USERDIR/$TROLL_CONFIGFOLDER/bootstrap.dat.old" ]
rm $USERDIR/$TROLL_CONFIGFOLDER/bootstrap.dat.old
echo "Deleting Trollcoin Bootstrap"
echo "Disabling Bootstrap systemctl service"
systemctl disable bootstrap.service
systemctl daemon-reload
sleep 2
echo "Deleting this script"
rm -- "$0"
fi
EOT

chmod u+x bootstrap.sh
sleep 4
else 
exit
fi
}

function bootstrap_check() {
if [ ! -f "$USERDIR/$TROLL_CONFIGFOLDER/$STRAP" ]; then
echo "BootStrap Not downloaded Removel Script will not be installed"
exit
elif [ ! -f "/etc/systemd/system/bootstrap.service" ]; then
cat << EOF > /etc/systemd/system/bootstrap.service
[Unit]
Description=Check and remove bootstraps when done
[Service]
StandardOutput=null
#StandardError=null
User=$USER
Restart=always
RestartSec=3600s
ExecStart=$USERDIR/bootstrap.sh
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
sleep 4
systemctl start bootstrap.service
systemctl enable bootstrap.service >/dev/null 2>&1
else
echo -e "Bootstrap Removal Service Already Running"
fi
}

function setup_node() {
  troll_install
  important_information
  bootstrap_script
  bootstrap_check
}

##### Main #####
clear

checks
prepare_system
swap
setup_node
