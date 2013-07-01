#!/bin/sh

# Watch the different broadcast networks and hide them if they
# are considered unusable.
# A new entry in wifi-iface sections of wireless config has been added
# test_connect can contain a shell command giving the state of the
# network:
# for a bridged wifi network (without IP on APs side), this could be:
# option 'test_connect' 'arping -I br-$(net) $(routeur_ip) -c 4'
# for wpa2 networks, test_connect can be ommited and connectivity
# to the radius serveur will be checked.
# In case of lack of connectivity, the corresponding SSID won't be
# broadcast anymore, preveting new clients from connecting.
# Currently, the scripts uses SIGHUP signal to hostapd process which
# ends up in loosing anyway all associated clients on the >>radio<<
# (hope this will be fixed)

CONF=/var/run/hostapd-phy0.conf
PID=/var/run/wifi-phy0.pid

. /lib/functions.sh

# Numbered of changed statuses
changed=0

set_ignore_broadcast_ssid() {
  old=`sed -e "/^ssid=$1$/,/^bss=/ s/^ignore_broadcast_ssid=\(.*\)$/\1/; t; d" $CONF`
  [ -z "$old" ] && { echo "Old value not found. Skipping"; return; }
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
  config_get disabled $iface disabled 0
  [ $disabled -ne 0 ] && {
    echo "$ssid: skipped (disabled)"
    return
  }
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

# TODO: find out why this causes all clients to be disconnected on the radio
# maybe we should try reload the configuration using "hostapd_cli reconfigure"
# however we should figure out first what happened to that command
# (http://lists.shmoo.com/pipermail/hostap/2011-July/023520.html ?)
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
