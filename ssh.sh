#!/bin/bash

echo "########## SSH ##########"
echo "Recuerda instalar el OPENSSH-SERVER en el servidor antes de acceder por ssh y abre el puerto 2222 en el host y 22 en el servidor"

######Codigo para que no pida contraseñas
OPCSSH="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o loglevel=ERROR -i CLAU"

rm -v CLAU*

ssh-keygen -N "" -f CLAU

LOOP=1
until [ "$LOOP" = "0" ] ; do
	echo -n "·"
	ssh-copy-id -p 2222 $OPCSSH.pub itbsjo@localhost
	LOOP="$?"
	sleep 1
done

echo "Instala antes de todo los paquetes en el servidor, de openssh-server con 
###sudo apt install openssh-server###"

######Copia el script al servidor y luego entra en el con ssh
scp -P 2222 $OPCSSH sc_cliente.sh itbsjo@localhost:/home/itbsjo/Desktop
scp -P 2222 $OPCSSH sc_dhcp_dns.sh itbsjo@localhost:/home/itbsjo/Desktop
ssh -p 2222 $OPCSSH -t itbsjo@localhost bash "/home/itbsjo/Desktop/sc_dhcp_dns.sh"
