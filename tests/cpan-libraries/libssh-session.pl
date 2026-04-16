#!/usr/bin/perl
use strict;
use warnings;
use Libssh::Session qw(:all);
use POSIX qw(WIFEXITED WEXITSTATUS);

# Install SSH server
if (-f "/etc/debian_version") {
    system("apt-get update") == 0
    or die "apt-update failed: $?";
    system("apt-get install -y openssh-server") == 0
    or die "Installation failed: $?";
} elsif (-f "/etc/redhat-release") {
    system("dnf install -y openssh-server") == 0
    or die "Installation failed: $?";
} else {
    die "Unsupported operating system";
}

mkdir("/var/run/sshd") unless -d "/var/run/sshd";

system("ssh-keygen -A") == 0
or die "SSH keys generation failed: $?";

if (getpwnam("testuser")) {
    print "User testuser already exists\n";
} else {
    system("useradd -m testuser") == 0
    or die "User creation failed: $?";
}

system("echo 'testuser:testpassword' | chpasswd") == 0
or die "Password configuration failed: $?";

# SSH configuration
open(my $fh, '>', '/etc/ssh/sshd_config')
or die "Cannot open sshd_config: $!";
print $fh "Port 2222\n";
print $fh "PermitRootLogin no\n";
print $fh "AllowUsers testuser\n";
print $fh "PasswordAuthentication yes\n";
close($fh);

# Start SSH server
my $pid = fork();
die "Fork failed: $!" unless defined $pid;

if ($pid == 0) {
    exec("/usr/sbin/sshd", "-D")
    or die "Cannot start SSH server: $!";
}

# Wait and check the port
sleep(5);

# Check the port with Perl
use IO::Socket::INET;
my $sock = IO::Socket::INET->new(
    PeerAddr => '127.0.0.1',
    PeerPort => 2222,
    Proto    => 'tcp'
);

die "Port SSH 2222 is not listening" unless $sock;
$sock->close();

# Connection test with Libssh::Session
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

    print "Trying to connect...\n";
    $session->connect() == SSH_OK or die "Connection failed: " . $session->get_error();

    print "Trying to authenticate...\n";
    $session->auth_password(password => "testpassword") == SSH_AUTH_SUCCESS or die "Authentification failed: " . $session->get_error();

    print "SSH connection test succeeded\n";
    $session->disconnect();
};
if ($@) {
    kill 'TERM', $pid;
    die "Test failed: $@";
}

# Cleaning
kill 'TERM', $pid;
waitpid($pid, 0);

# Uninstall SSH server
if (-f "/etc/debian_version") {
    system("apt-get autoremove -y --purge openssh-server") == 0
    or die "Uninstallation failed: $?";
} elsif (-f "/etc/redhat-release") {
    system("dnf autoremove --setopt=keepcache=True -y openssh-server") == 0
    or die "Uninstallation failed: $?";
} else {
    die "Unsupported operating system";
}

system("userdel -r testuser") == 0
or die "Cannot delete user: $?";

print "Test and cleanup succeeded\n";