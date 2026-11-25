#!/usr/bin/perl
#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
# Fail when the packed centreon_plugins.exe bundles an OpenSSL older than the
# minimum supported version, more than one OpenSSL version, Strawberry's own
# OpenSSL build (lib{ssl,crypto}-*__.dll), or a DLL that still imports it.
#
# Usage: perl check-bundled-openssl.pl <centreon_plugins.exe>
use strict;
use warnings;
use Archive::Zip qw(:ERROR_CODES);
use File::Basename qw(basename);
use File::Temp qw(tempdir);

# Oldest OpenSSL release still supported upstream (3.5 is the current LTS).
my @min_version = (3, 5, 0);

my $exe = shift @ARGV or die "usage: check-bundled-openssl.pl <centreon_plugins.exe>\n";

# A PAR executable is the loader followed by a zip archive; Archive::Zip
# handles the leading loader bytes.
my $zip = Archive::Zip->new();
$zip->read($exe) == AZ_OK or die "cannot read the PAR archive embedded in $exe\n";

my $tmp = tempdir(CLEANUP => 1);
my (@errors, %versions);
my $libcrypto_count = 0;
my $index = 0;

foreach my $member ($zip->membersMatching(qr/\.dll\z/i)) {
    my $entry = $member->fileName();
    my $name = basename($entry);
    # Prefix with an index: the same basename may appear under several paths.
    my $path = $tmp . '/' . $index++ . '_' . $name;
    $member->extractToFileNamed($path) == AZ_OK or die "cannot extract $entry\n";

    if ($name =~ /^lib(?:ssl|crypto)-.*__\.dll\z/i) {
        push @errors, "$entry: Strawberry's own OpenSSL build is bundled";
    }

    if ($name =~ /^libcrypto-.*\.dll\z/i) {
        $libcrypto_count++;
        open(my $fh, '<:raw', $path) or die "cannot open $path: $!\n";
        my $content = do { local $/; <$fh> };
        close($fh);
        # OPENSSL_VERSION_TEXT, e.g. "OpenSSL 3.6.5 30 Sep 2025".
        my %found = map { $_ => 1 } $content =~ /OpenSSL (\d+\.\d+\.\d+)[a-z]?(?:-\w+)? +\d{1,2} \w{3} \d{4}/g;
        if (scalar(keys %found) != 1) {
            push @errors, "$entry: cannot determine the OpenSSL version";
        } else {
            my ($version) = keys %found;
            $versions{$version} = 1;
            print "$entry: OpenSSL $version\n";
            push @errors, "$entry: OpenSSL $version is older than " . join('.', @min_version)
                if version_lt([split(/\./, $version)], \@min_version);
        }
    }

    open(my $ph, '-|', 'objdump', '-p', $path) or die "cannot run objdump: $!\n";
    while (my $line = <$ph>) {
        if ($line =~ /DLL Name:\s*(lib(?:ssl|crypto)-\S*__\.dll)/i) {
            push @errors, "$entry: imports Strawberry's own OpenSSL ($1)";
        }
    }
    close($ph) or die "objdump failed on $entry\n";
}

push @errors, 'no bundled libcrypto DLL found' if $libcrypto_count == 0;
push @errors, 'several OpenSSL versions are bundled: ' . join(', ', sort keys %versions)
    if scalar(keys %versions) > 1;

if (@errors) {
    print STDERR "ERROR: $_\n" foreach @errors;
    exit 1;
}
print "Bundled OpenSSL check OK.\n";
exit 0;

sub version_lt {
    my ($left, $right) = @_;
    for my $i (0 .. 2) {
        return $left->[$i] < $right->[$i] if $left->[$i] != $right->[$i];
    }
    return 0;
}
