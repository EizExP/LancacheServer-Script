#!/bin/bash

apt update && apt upgrade -y
apt install curl -y
curl -sSL https://get.docker.com/ | sh

echo "############ LanCache Konfiguration ############"
echo
echo Verfügbare Netzwerkkarten:
echo
/sbin/ip -o -4  addr list |awk '{print $D}'
echo
echo Welche der angezeigten Netzwerkkarten soll für den Cacheserver verwendet werden ?
read -p "Anschlussname z.B. eth0: " interface
ipv4=$(/sbin/ip -o -4 addr list $interface | awk '{print $4}' | cut -d/ -f1)
echo 
echo In welchem Pfad sollen die Daten des Cacheservers gespeichert werden? bei keiner Angabe wird der Standartpfad von Docker verwendet.
read -p "Pfad: " path

if [ -z "$path" ]
then
    path=/cache
    mkdir -p $path
else
    mkdir -p $path
fi

path=${path%/}
echo 
echo Netzwerkanschluss: $interface
echo    mit IPv4 Adresse: $ipv4
echo Pfad :$path 
echo 
echo Soll mit der Installation begonnen werden ? bitte überprüfen Sie Pfad und IP Adresse.
read -p "[y/n]" -n 1 -r
echo   
if [[ $REPLY =~ ^[Yy]$ ]]
then
    
if [ "$(docker ps -a | grep lancache)" ]; then
   echo
   echo docker Container lancache wird gelöscht
   docker stop lancache || true && docker rm lancache || true
     
fi

if [ "$(docker ps -a | grep lancache-dns)" ]; then
   echo
   echo docker Container lancache-dns wird gelöscht
   docker stop lancache-dns || true && docker rm lancache-dns || true
fi

if [ "$(docker ps -a | grep lancache-sniproxy)" ]; then
    echo
    echo docker Container lancache-sniproxy wird gelöscht
    docker stop lancache-sniproxy || true && docker rm lancache-sniproxy || true
fi

echo
echo neue Docker Container werden erstellt.

docker run -d --restart unless-stopped --name lancache -v $path/cache:/data/cache -v $path/logs:/data/logs -p $ipv4:80:80 lancachenet/monolithic:latest
docker run -d --restart unless-stopped --name lancache-dns -p $ipv4:53:53/udp -e USE_GENERIC_CACHE=true -e LANCACHE_IP=$ipv4 lancachenet/lancache-dns:latest
docker run -d --restart unless-stopped --name lancache-sniproxy -p $ipv4:443:443 lancachenet/sniproxy:latest    

echo die Installation wurde abgeschlossen.    
    exit 0
else
    echo die Installation wird abgebrochen.
    exit 1
fi
