# Create %DATETIME%
#
option domain-name %DOMAINNAME%;
option domain-name-servers %DNS%;
default-lease-time 86400;
max-lease-time 172800;
ddns-update-style none;
lease-file-name \"/var/db/dhcpd/dhcpd.leases\";


option ms-classless-static-routes code 249 = array of integer 8;
log-facility local7;



shared-network %NETWORK_NAME% {

#subnet %BLOCK_NETWORK% netmask %BLOCK_MASK% {
#  range %block_range%;
#  authoritative;
#}

subnet %NETWORK% netmask %NETWORK_MASK% {
#  range %range%
  deny unknown-clients;
  authoritative;
#  option static-routes %STATIC_ROUTES%
  %ROUTERS%
  %NET_ROUTES%
}

}


%HOSTS%
