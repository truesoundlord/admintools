#! /usr/bin/perl

# De Zordi Dimitri (soundlord@gmail.com)


use strict;
use warnings;
use experimental 'smartmatch';

use File::Copy;
#use Data::Dump 'dump';

my @ipaddresses = ('');

my $targetfile="/etc/hosts";

my $ipentry="";

my @domains;
my $lesdomaines;
my %hashEntries;

my $doyourjob=0;


open(my $descripteur,'<:encoding(UTF-8)', $targetfile) or die "$targetfile not found :{";

while(my $ligne = <$descripteur>) 			# tant que nous ne sommes pas arrivés à la fin du fichier
{
	chomp $ligne;													# on enlève le caractère '\n' de fin de ligne
	
	if($ligne =~ /^([0-9]{1,3}\.){3}[0-9]{1,3}/)
	{
		($ipentry,@domains)=split('\s{1,}|\t',$ligne);									# on "splitte" à un ou plusieurs espaces ou à une tabulation
		
		if(!($ipentry ~~ @ipaddresses))
		{
			#print "IP trouvée --> $ipentry \n";
			$hashEntries{$ipentry} = [ "@domains" ];											# contre intuitif... un "add" ou "+=" ou quelque chose qui pourrait noter qu'on ajoute à ce qui existe déjà...
			push(@ipaddresses,$ipentry);
		}
		else
		{
			my @temp=$hashEntries{$ipentry};
			push(@temp,[@domains]);
			$hashEntries{$ipentry} = [@temp];															# contre intuitif... un "add" ou "+=" ou quelque chose qui pourrait noter qu'on ajoute à ce qui existe déjà...
			$doyourjob=1;
		}
	}
}

#print dump(%hashEntries)."\n";
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

	foreach my $key (keys %hashEntries)
	{
		my @temp=$hashEntries{$key};
		
		foreach my $element (@temp)
		{	
			if($element ~~ /ARRAY/)
			{
				foreach my $autreelement (@$element)
				{
						$lesdomaines.="@$autreelement";
						$lesdomaines.="\t";
				}
			}
			else
			{
				$lesdomaines.="@$element";
				$lesdomaines.="\t";
			}
		}
		print $key."\t".$lesdomaines."\n";
		$ipentry=$key."\t".$lesdomaines."\n";
		
		print $descWRITE $ipentry;
		
		$lesdomaines="";
	}

	close($descWRITE);
}
else
{
	print "Nothing to do... /etc/hosts is not messed ^^\n";
}





