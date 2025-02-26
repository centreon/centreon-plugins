#!/usr/bin/perl
use strict;
use warnings;
use Libssh::Session;
use POSIX qw(WIFEXITED WEXITSTATUS);

# Installation du serveur SSH
system("apt-get update") == 0
    or die "Échec de apt-get update: $?";
system("apt-get install -y openssh-server") == 0
    or die "Échec de l'installation: $?";

mkdir("/var/run/sshd") unless -d "/var/run/sshd";

system("ssh-keygen -A") == 0
    or die "Échec de génération des clés SSH: $?";

if (getpwnam("testuser")) {
    print "L'utilisateur testuser existe déjà\n";
} else {
    system("useradd -m testuser") == 0
        or die "Échec de création de l'utilisateur: $?";
}

system("echo 'testuser:testpassword' | chpasswd") == 0
    or die "Échec de configuration du mot de passe: $?";

# Configuration SSH
open(my $fh, '>', '/etc/ssh/sshd_config')
    or die "Impossible d'ouvrir sshd_config: $!";
print $fh "Port 2222\n";
print $fh "PermitRootLogin no\n";
print $fh "AllowUsers testuser\n";
print $fh "PasswordAuthentication yes\n";
close($fh);

# Démarrage du serveur SSH
my $pid = fork();
die "Fork failed: $!" unless defined $pid;

if ($pid == 0) {
    exec("/usr/sbin/sshd", "-D")
        or die "Impossible de démarrer sshd: $!";
}

# Attente et vérification du port
sleep(5);

# Vérification du port avec Perl
use IO::Socket::INET;
my $sock = IO::Socket::INET->new(
    PeerAddr => '127.0.0.1',
    PeerPort => 2222,
    Proto    => 'tcp'
);

die "Le port SSH 2222 n'est pas en écoute" unless $sock;
$sock->close();

# Test de la connexion avec plus de debug
eval {
    my $session = Libssh::Session->new();
    $session->options(
        host         => "127.0.0.1",
        port         => 2222,
        user         => "testuser",
        LogVerbosity => 1,
        PrintError   => 1,
        Timeout      => 10
    );

    print "Tentative de connexion...\n";
    $session->connect() == 0 or die "Échec de connexion: " . $session->get_error();

    print "Tentative d'authentification...\n";
    $session->auth_password(password => "testpassword") == 0 or die "Échec d'authentification: " . $session->get_error();

    print "Test de connexion SSH réussi\n";
    $session->disconnect();
};
if ($@) {
    kill 'TERM', $pid;
    die "Test échoué: $@";
}

# Nettoyage
kill 'TERM', $pid;
waitpid($pid, 0);

system("apt-get purge -y openssh-server") == 0
    or die "Échec de la désinstallation: $?";
system("apt-get autoremove -y") == 0
    or die "Échec de autoremove: $?";

system("userdel -r testuser") == 0
    or die "Échec de la suppression de l'utilisateur: $?";

print "Test et nettoyage terminés avec succès\n";