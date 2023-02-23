#! /usr/bin/perl

# De Zordi Dimitri (soundlord@gmail.com)


use strict;
use warnings;
use experimental 'smartmatch';

use File::Copy;
#use Data::Dump 'dump';

my @ipaddresses;

my $targetfile="/etc/hosts";

my $ipentry="";

my @domains;
my $lesdomaines;
my %hashIPv4Hosts;

my $doyourjob=0;

binmode(STDOUT, ":utf8");
open(my $descripteur,'<:encoding(UTF-8)', $targetfile) or die "$targetfile not found :{";

while(my $ligne = <$descripteur>) 			# tant que nous ne sommes pas arrivés à la fin du fichier
{
	chomp $ligne;													# on enlève le caractère '\n' de fin de ligne
	
	if($ligne =~ /^([0-9]{1,3}\.){3}[0-9]{1,3}/)
	{
		($ipentry,@domains)=split('\s{1,}|\t',$ligne);									# on "splitte" à un ou plusieurs espaces ou à une tabulation
		
		if(!($ipentry ~~ @ipaddresses))
		{
			# si adresse IP pas trouvée 
			$hashIPv4Hosts{$ipentry} = [ @domains ];											# on associe @domains avec l'adresse IP 
			push(@ipaddresses,$ipentry);																	# on ajoute l'adresse IP dans le tableau ipaddresses
		}
		else
		{
			my $recupHosts=$hashIPv4Hosts{$ipentry};
			#print "BEFORE recupHosts -> "."@$recupHosts"."\n";
			push( @$recupHosts,"@domains");
			#print "AFTER recupHosts -> "."@$recupHosts"."\n";
			$hashIPv4Hosts{$ipentry}=~[ @domains ];												# on remplace les hosts liés à l'adresse IP
			$doyourjob=1;
		}
	}
}

#print dump(%hashIPv4Hosts)."\n";
close($descripteur);

# ne faire ceci que si nous avons trouvé deux entrées IPv4 distinctes...

if($doyourjob)
{
	#renommer le fichier /etc/hosts en /etc/hosts.apachehelper
	copy $targetfile, "/etc/hosts.apachehelper" or die "$targetfile can not be copied ($!) :{";
	unlink $targetfile;
	open(my $descWRITE,'>:encoding(UTF-8)',$targetfile); 

	#ouvrir le fichier renommé en lecture et /etc/hosts en écriture

	open(my $descREAD,'<:encoding(UTF-8)', "/etc/hosts.apachehelper") or die "file not found :{";

	# lire chaque ligne du fichier /etc/hosts.apachehelper

	while(my $ligne = <$descREAD>)
	{
		# ne recopier que les lignes ne CONTENANT PAS d'adresse IPv4
		if(!($ligne =~ /^([0-9]{1,3}\.){3}[0-9]{1,3}/))
		{
			chomp $ligne;
			#print $ligne."\t\t\t--> recopiée \n";
			print $descWRITE $ligne."\n";
		}
	}

	close($descREAD);

	foreach my $ipaddress (@ipaddresses)
	{
		my $hoststowrite=$hashIPv4Hosts{$ipaddress};
		my $lineToWrite=$ipaddress."\t"."@$hoststowrite"."\n";
		print $lineToWrite;
		print $descWRITE $lineToWrite;
	}

	close($descWRITE);
}
else
{
	print "Nothing to do... /etc/hosts is not messed ^^\n";
}





