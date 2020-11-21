#!/bin/bash

######Cambiar nombre de la maquina
sudo hostnamectl set-hostname MAINS-MDM

echo "########## DHCP SERVICE ##########"

#####Instala paquetes net-tools
sudo apt install net-tools
sleep 1

#####Instals servidor dhcp
sudo apt install isc-dhcp-server
sleep 1

#####Apaga la interficie enp0s8
sudo ifconfig enp0s8 down 
sleep 2

#####Crea el fixero de la ip propia
sudo bash -c 'cat <<END> /etc/netplan/01-netcfg.yaml
# This file describes the network interfaces avilable on your system.
# For more information, see netplan(5).
network: 
 version: 2
 renderer: networkd
 ethernets: 
  enp0s8:
   dhcp4: no
   dhcp6: no
   addresses: [10.5.5.1/24]
   nameservers:
    addresses: [10.5.5.1]
    search: [mdm.itb]
END'
sleep 2

#####Aplicamos el netplan
sudo netplan apply
sleep 1

#####Activa el enp0s8
sudo ifconfig enp0s8 up
sleep 2

#####Remplaza el fixero por enp0s8
sudo sed -i 's/INTERFACESv4=""/INTERFACESv4="enp0s8"/g' "/etc/default/isc-dhcp-server"
sleep 2

#####Declara la red interna
sudo bash -c 'cat <<END>> /etc/dhcp/dhcpd.conf
subnet 10.5.5.0 netmask 255.255.255.0 {
    range 10.5.5.3 10.5.5.40;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.5.5.255;
    option routers 10.5.5.1; 
    option domain-name-servers 10.5.5.1;
    option domain-name "mdm.itb";
}
END'
sleep 2

#####Inicia el servicio y hace un status
sudo systemctl start isc-dhcp-server
sleep 2

#####Soluciona el problema de PID file 
sudo systemctl daemon-reload
sudo systemctl restart isc-dhcp-server
sleep 1
sudo systemctl status isc-dhcp-server
sleep 2

#####Solucion de problemas ivp4 inernet cliente, etc.
sudo sysctl -w net.ipv4.ip_forward=1
sleep 1

#####Problema internet
sudo iptables -A FORWARD -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 10.5.5.0/24 -o enp0s8 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -s 10.5.5.0/24 -j MASQUERADE
sleep 1

echo "########## DNS SERVICE ##########"

######Instala paquetes bind9
sudo apt install bind9
sleep 1

######Cambia el nombre del original named.conf.options
sudo mv /etc/bind/named.conf.options /etc/bind/named.conf.options.back

######Crea el named.conf.options configurado
sudo bash -c 'cat <<END> /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };
};
END'
sleep 2

######Recarga el servicio y ve estatus
sudo service bind9 restart
sleep 1

######Configura el named.conf.local como se le diga 
sudo bash -c 'cat <<END>> /etc/bind/named.conf.local
zone "mdm.itb" {
    type master;
    file "/etc/bind/db.mdm.itb";
};
zone "5.5.10.in-addr.arpa" {
    type master;
    file "/etc/bind/db.10";
};
END'
sleep 2

######Crea archivo db.mdm.itb (Directa)
sudo bash -c 'cat <<END> /etc/bind/db.mdm.itb
; Definició de la zona mdm.itb
\$TTL 604800
mdm.itb. IN SOA router.mdm.itb. dm.router.mdm.itb. (
                 20141003       ; versió
                        1D      ; temps d’espera per refrescar
                        2H      ; temps de reintent
                        1W      ; Caducitat
                        2D )    ; ttl

@                       IN      NS      router.mdm.itb.
localhost               IN      A       127.0.0.1
router                  IN      A       10.5.5.1
bdd                     IN      A       10.5.5.2
eq1                     IN      A       10.5.5.101
eq2                     IN      A       10.5.5.102
www			            IN	    CNAME	router
END'
sleep 2

######Crea el fixero db.10 (Inversa)
sudo bash -c 'cat <<END> /etc/bind/db.10
\$TTL 604800
5.5.10.in-addr.arpa. IN SOA router.mdm.itb. dm.router.mdm.itb. (
                        20141003        ; versió
                        1D      ; temps d’espera per refrescar
                        2H      ; temps de reintent
                        1W      ; Caducitat
                        2D )    ; ttl

                IN      NS      router.mdm.itb.
1               IN      PTR             router.mdm.itb.
2               IN      PTR             bdd.mdm.itb.
101             IN      PTR             eq1.mdm.itb.
102             IN      PTR             eq2.mdm.itb.
END'
sleep 2

######Datos y status
sudo systemctl restart bind9
sleep 1
sudo systemctl status bind9
sleep 2

######Sube el script a internet
echo "######Usa wget http://10.5.5.1:2222/Desktop/sc_cliente.sh para descargar el script en el cliente######"
python3 -m http.server 2222

