#!/bin/sh

# Customisation Cr@ns : on ne garde que les clefs ssh lors d'un sysupgrade
# le reste de la configuration est géré dans l'image ou via l'initscript
# de first boot (hostname via dhcp par ex)

# Surcharge de la fonction add_uci_conffiles de /sbin/sysupgrade
add_uci_conffiles() {
        local file="$1"
       	( cat <<EOF
/etc/dropbear/dropbear_rsa_host_key
/etc/dropbear/dropbear_dss_host_key
EOF
) > $file
        return 0
}
