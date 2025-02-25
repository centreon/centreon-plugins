#!/usr/bin/perl

use strict;
use warnings;
use libssh::session;

# Configuration de la connexion SSH
my $host = 'example.com';
my $username = 'your_username';
my $password = 'your_password';

# Création d'une nouvelle session SSH
my $session = libssh::session->new();

# Configuration de la session
$session->options(
    host => $host,
    user => $username,
    password => $password,
);

# Connexion au serveur SSH
$session->connect() or die "Unable to connect to host $host\n";

# Authentification avec nom d'utilisateur et mot de passe
$session->auth_password() or die "Unable to authenticate with username $username and password\n";

# Ouverture d'une session de canal
my $channel = $session->channel() or die "Unable to open channel\n";

# Exécution d'une commande sur le serveur distant
$channel->exec('ls -l') or die "Unable to execute command\n";

# Lecture de la sortie de la commande
while (my $line = $channel->read()) {
    print $line;
}

# Fermeture du canal et de la session SSH
$channel->close();
$session->disconnect();

print "Test completed successfully.\n";
