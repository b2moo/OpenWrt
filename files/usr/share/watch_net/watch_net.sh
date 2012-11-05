#!/bin/sh

# Watch the different broadcast networks

CONF=/var/run/hostapd-phy0.conf
PID=/var/run/wifi-phy0.pid

. /lib/functions.sh

# Numbered of changed statuses
changed=0


set_ignore_broadcast_ssid() {
  old=`sed -e "/^ssid=$1$/,/^bss=/ s/^ignore_broadcast_ssid=\(.*\)$/\1/; t; d" $CONF`
  echo "Set to $2 (old=$old)"
  [ "$old" -eq $2 ] && {
    echo "...Unchanged !"
  } || {
    sed -e "/^ssid=$1$/,/^bss=/ s/^ignore_broadcast_ssid=.*$/ignore_broadcast_ssid=$2/; " -i $CONF
    changed=$(($changed+1))
  }
}

check_ssid() {
  local iface="$1"
  config_get ssid $iface ssid default
  config_get test_connect $iface test_connect 
  [ -z "$test_connect" ] && {
    config_get server $iface server
    [ -z "$server" ] && {
       test_connect="true"
    } || {
       test_connect="ping -c 4 $server"
    }
  }
  echo "$ssid: $test_connect ..."
  $test_connect &> /dev/null
  [ 0 -eq $? ] && set_ignore_broadcast_ssid "$ssid" 0 \
               || set_ignore_broadcast_ssid "$ssid" 1
  
}


reload_hostapd() {
  echo "reload config"
  kill -1 `cat $PID`
}

config_load wireless
cp $CONF $CONF.bak
config_foreach check_ssid wifi-iface
[ 0 -ne "$changed" ] && {
  reload_hostapd
}

exit $changed
