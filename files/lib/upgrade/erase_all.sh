add_uci_conffiles() {
        local file="$1"
    	cat <<EOF 
/etc/dropbear/dropbear_rsa_host_key
/etc/dropbear/dropbear_dss_host_key
EOF
> "$file"
        return 0
}
