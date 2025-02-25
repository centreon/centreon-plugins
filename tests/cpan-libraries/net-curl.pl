#!/usr/bin/perl

use strict;
use warnings;
use Net::Curl::Easy;

# URL à récupérer
my $url = 'https://www.centreon.com';

# Création d'un nouvel objet Curl
my $curl = Net::Curl::Easy->new();

# Configuration de l'URL
$curl->setopt(CURLOPT_URL, $url);

# Variable pour stocker le contenu de la page
my $response_body;

# Configuration de l'option pour écrire la réponse dans la variable
$curl->setopt(CURLOPT_WRITEDATA, \$response_body);

# Exécution de la requête
$curl->perform() or die "Unable to fetch URL $url\n";

# Affichage du contenu de la page
print "Response body:\n$response_body\n";

print "Test completed successfully.\n";
