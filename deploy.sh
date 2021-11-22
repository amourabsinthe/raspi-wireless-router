# At least edit following content before use
WLAN_MAC_ADDR=""
LOCAL_MAC_ADDR=""

# Your internet connection may not be a wifi, so please edit netplan settings manully.
INTER_CONN_WIFI_NAME=""
INTER_CONN_WIFI_PASSWORD=""

LOCAL_WIFI_NAME=""
LOCAL_WIFI_PASSWORD=""


YELLOW='\033[1;33m'
SP='    '

echo "${YELLOW}disable cloud-init"
sudo touch /etc/cloud/cloud-init.disabled

echo "${YELLOW}retrives required packages"
sudo apt update
sudo apt install dnsmasq hostapd firehol

#Edit this according to you macaddress before use 
CONTENT="SUBSYSTEM==\"net\", ACTION==\"add\", ATTR{address}==\"${WLAN_MAC_ADDR}\", NAME=\"wlan\"\n\
SUBSYSTEM==\"net\", ACTION==\"add\", ATTR{address}==\"${LOCAL_MAC_ADDR}\", NAME=\"llan\""
LOCATION=/lib/udev/rules.d/72-static-mac-mapping.rules
echo "${YELLOW}deploys ${LOCATION}"
sudo printf "$CONTENT" > $LOCATION

CONTENT="network:
${SP}version: 2
${SP}ethernets:
${SP}${SP}eth0:
${SP}${SP}${SP}dhcp4: true
${SP}${SP}${SP}optional: true
${SP}${SP}llan:
${SP}${SP}${SP}dhcp4: false
${SP}${SP}${SP}dhcp6: false
${SP}${SP}${SP}addresses:
${SP}${SP}${SP}- 192.168.4.1/24
${SP}wifis:
${SP}${SP}wlan:
${SP}${SP}${SP}access-points:
${SP}${SP}${SP}${SP}${INTER_CONN_WIFI_NAME}:
${SP}${SP}${SP}${SP}${SP}password: '${INTER_CONN_WIFI_PASSWORD}'
${SP}${SP}${SP}dhcp4: true
${SP}${SP}${SP}optional: true"
LOCATION=/etc/netplan/50-cloud-init.yaml
echo "${YELLOW}deploys ${LOCATION}"
sudo printf "$CONTENT" > $LOCATION


CONTENT="interface=llan\n\
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h\n\
port=5353"
LOCATION=/etc/dnsmasq.conf
echo "${YELLOW}deploys ${LOCATION}"
sudo printf "$CONTENT" > $LOCATION

CONTENT="DAEMON_CONF=\"/etc/hostapd/hostapd.conf\""
LOCATION=/etc/default/hostapd
echo "${YELLOW}deploys ${LOCATION}"
sudo printf "$CONTENT" > $LOCATION

CONTENT="interface=llan\n\
hw_mode=a\n\
channel=36\n\
country_code=JP\n\
ieee80211d=1\n\
ieee80211n=1\n\
ieee80211ac=1\n\
wmm_enabled=1\n\
\n\
ssid=${LOCAL_WIFI_NAME}\n\
auth_algs=1\n\
wpa=2\n\
wpa_key_mgmt=WPA-PSK\n\
rsn_pairwise=CCMP\n\
wpa_passphrase=${LOCAL_WIFI_PASSWORD}"
LOCATION=/etc/hostapd/hostapd.conf
echo "${YELLOW}deploys ${LOCATION}"
sudo printf "$CONTENT" > $LOCATION

CONTENT="START_FIREHOL=YES\n\
WAIT_FOR_IFACE=\"\"\n\
FIREHOL_ESTABLISHED_ACTIVATION_ACCEPT=0"
LOCATION=/etc/default/firehol
echo "${YELLOW}deploys ${LOCATION}"
sudo printf "$CONTENT" > $LOCATION

CONTENT="version 6\n\
\n\
# have outgoing traffic use the public IP\n\
ipv4 masquerade wlan\n\
\n\
# fix tcp mss for ppp devices\n\
tcpmss auto wlan\n\
\n\
# Accept all client traffic on WAN\n\
interface wlan wan\n\
${SP}protection bad-packets\n\
${SP}client all accept\n\
${SP}server ssh accept\n\
\n\
# Accept all traffic on LAN\n\
interface llan lan\n\
${SP}policy accept\n\
\n\
# Route packets between LAN and WAN\n\
router lan2wan inface llan outface wlan\n\
${SP}protection bad-packets\n\
${SP}route all accept"
LOCATION=/etc/firehol/firehol.conf
echo "${YELLOW}deploys ${LOCATION}"
sudo printf "$CONTENT" > $LOCATION

echo "${YELLOW}enables ip forwarding"
sudo echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf

echo "${YELLOW}enables services:"
sudo systemctl enable dnsmasq
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl enable firehol