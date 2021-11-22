# raspi-wireless-router
 Use your Raspberry PI as a wireless router on Ubuntu server
## Deploy
After modified the file deploy.sh according to your case, the run:
```
sudo sh ./deploy.sh"
```
## Notes

**1. Give your network interface a fixed name**
```
# file: 72-static-mac-mapping.rules
# location: /lib/udev/rules.d/
# You should change the content of MACADDR according to your macaddress. 
# For me, wlan is my internet connection, llan is my local hotspot.
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="MACADDR", NAME="wlan"
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="MACADDR", NAME="llan"
```

**2. Network setting on ubuntu server**

```
# file: 50-cloud-init.yaml
# location: /etc/netplan
# Give my llan a static ip address, later we will have ap hosted on it.
# For me, my wlan connection is also a wifi. You may have ethernet or something.
# Modify it according to your case.
network:
    version: 2
    ethernets:
        eth0:
            dhcp4: true
            optional: true
        llan:
            dhcp4: false
            dhcp6: false
            addresses:
            - 192.168.4.1/24
    wifis:
        wlan:
            access-points:
                YOURWIFINAME:
                    password: 'YOURPASSWORD'
            dhcp4: true
            optional: true
```
**3. Set a DHCP host for local clients**
```
# file: dnsmasq.conf
# location: /etc/
# You don't have to host DHCP server if you can manully set you ip address.
# You may also set you DNS server here.
interface=llan
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
port=5353
```

**4. Set your WiFi AP**
```
# file: hostapd.conf
# location: /etc/hostapd/
# Edit this to fit your situation.
# At least enter your wifi name password and country code

interface=llan
hw_mode=a
channel=36
country_code=COUNTRY
ieee80211d=1
ieee80211n=1
ieee80211ac=1
wmm_enabled=1

ssid=YOURWIFINAME
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_passphrase=YOURPASSWORD
```
```
# file: hostapd
# location: /etc/default/
# Tell your hostap to use above settings
DAEMON_CONF="/etc/hostapd/hostapd.conf"
```
**5. Allow local network clients to visit Internet**
```
# file: firehol.conf
# location: /etc/firehol/
version 6

# have outgoing traffic use the public IP
ipv4 masquerade wlan

# fix tcp mss for ppp devices
tcpmss auto wlan

# Accept all client traffic on WAN
interface wlan wan
    protection bad-packets
    client all accept
    server ssh accept

# Accept all traffic on LAN
interface llan lan
    policy accept

# Route packets between LAN and WAN
router lan2wan inface llan outface wlan
    protection bad-packets
    route all accept
```
```
# file: firehol
# location:/etc/default/
# Enable firehol
START_FIREHOL=YES
WAIT_FOR_IFACE=""
FIREHOL_ESTABLISHED_ACTIVATION_ACCEPT=0
```
