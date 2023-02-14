#! /bin/bash

export skelfolder="/etc/skel/webskel"
export apachedr="/www"
export vhostsdir="/etc/apache2/vhosts.d"

if ! test -e $apachedr
then 
	mkdir /www
fi

# vérifier l'existence de "skelfolder"

if ! test -e $skelfolder
then
	echo "Creating the skeleton..."
	mkdir -p $skelfolder/html  $skelfolder/css $skelfolder/cgi-bin $skelfolder/icons $skelfolder/images $skelfolder/javascript $skelfolder/documentation
	touch $skelfolder/index.html
	echo -en "<!doctype html>\n<html>\n<head>\n\t<title>Title here</title>\n\t<meta charset="utf-8">\n</head>\n<body>\n\t<!-- Content here -->\n</body>\n</html>" > $skelfolder/index.html
	echo "...done !!"
fi

# récupérer les paramètres...

for newsite in "$@"
do

# utiliser le format sitename:ipordomain et splitter sur le ':'

	IFS=':'
	read -ra SPLITTHAT <<< "$newsite"
	servername=${SPLITTHAT[0]} 
	domainname=${SPLITTHAT[1]}
	serveradmin=${SPLITTHAT[2]}
	IFS=' '
	
	echo "[servername:$servername]"	
	echo "[domain:$domainname]"
	echo "[serveradmin:$serveradmin]"
	
	if test $servername = ""
	then
		echo -en "Usage: ./addsite.sh [servername:domainorip:serveradmin]\nExample: www.mysite.com:127.0.0.47:mymail@mymail.com\n"
		exit 1
	fi
	
	if test $domain = ""
	then
		echo -en "Usage: ./addsite.sh [servername:domainorip:serveradmin]\nExample: www.mysite.com:127.0.0.47:mymail@mymail.com\n"
		exit 1
	fi
	
	if test $serveradmin = ""
	then
		echo -en "Usage: ./addsite.sh [servername:domainorip:serveradmin]\nExample: www.mysite.com:127.0.0.47:mymail@mymail.com\n"
		exit 1
	fi
		
	echo "Creating site -- $servername..."
	echo "Copying skeleton..."
	mkdir -p $apachedr/$servername
	cp -Rv $skelfolder/* $apachedr/$servername
	echo "...done !!"

	echo "Modifying apache2 configuration..."
	
	# les fichiers vhost.template et vhost-ssl.template par défaut se trouvent dans /etc/apache2/vhosts.d

	if test -e $vhostsdir/vhost.template
	then
			cp -v $vhostsdir/vhost.template $vhostsdir/$servername.conf
	else
		# dans mes configurations je mets les fichiers *.template dans le répertoire "templates"
		cp -v $vhostsdir/templates/vhost.template $vhostsdir/$servername.conf
	fi
	
	sed -i "s|<VirtualHost\ \*:80>|<VirtualHost\ $domainname:80>|g" $vhostsdir/$servername.conf
	
	# le "problème" des doublons n'est en soi qu'un soucis de maintenabilité du fichier /etc/hosts
	# j'ai testé plusieurs noms de domaines pour une ip donnée, TOUS les noms de domaines sont
	# assimilés pas seulement la première ni la dernière occurence !!!
	
	echo -en "$domainname\t$servername\n" >> /etc/hosts
	
	# il devrait y avoir moyen, en perl, à mon avis, de "ranger" les noms de domaines en fonction de leurs équivalent IP. 
	
	sed -i "s|/srv/www/vhosts/dummy-host.example.com|$apachedr/$servername|g" $vhostsdir/$servername.conf
	sed -i "s/dummy-host.example.com/$servername/g" $vhostsdir/$servername.conf
	sed -i "s/webmaster@dummy-host.example.com/$serveradmin/g" $vhostsdir/$servername.conf
	
done

echo "Restarting apache2 service..."
systemctl restart apache2.service
echo "...done !!"









