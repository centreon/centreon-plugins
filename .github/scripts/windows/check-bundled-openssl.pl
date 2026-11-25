#!/usr/bin/perl
#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
# Fail when the packed centreon_plugins.exe bundles an OpenSSL older than the
# minimum supported version, more than one OpenSSL version, Strawberry's own
# OpenSSL build (lib{ssl,crypto}-*__.dll), or a DLL importing an OpenSSL DLL
# that is not itself bundled.
#
# Usage: perl check-bundled-openssl.pl <centreon_plugins.exe>
use strict;
use warnings;
use Archive::Zip qw(:ERROR_CODES);
use File::Basename qw(basename);

# Oldest OpenSSL release still supported upstream (3.5 is the current LTS).
my @min_version = (3, 5, 0);

my $exe = shift @ARGV or die "usage: check-bundled-openssl.pl <centreon_plugins.exe>\n";

# A PAR executable is the loader followed by a zip archive; Archive::Zip
# handles the leading loader bytes.
my $zip = Archive::Zip->new();
$zip->read($exe) == AZ_OK or die "cannot read the PAR archive embedded in $exe\n";

my @members = $zip->membersMatching(qr/\.dll\z/i);
my %bundled = map { lc(basename($_->fileName())) => 1 } @members;
my (@errors, %versions);
my $net_ssleay_imports = 0;

foreach my $member (@members) {
    my $entry = $member->fileName();
    my $name = basename($entry);
    my ($content, $status) = $member->contents();
    $status == AZ_OK or die "cannot extract $entry\n";

    if ($name =~ /^lib(?:ssl|crypto)-.*__\.dll\z/i) {
        push @errors, "$entry: Strawberry's own OpenSSL build is bundled";
    }

    # Look for OPENSSL_VERSION_TEXT (e.g. "OpenSSL 3.6.5 30 Sep 2025") in every
    # DLL, not only libcrypto: an XS module statically linked against OpenSSL
    # embeds it too.
    my %found = map { $_ => 1 } $content =~ /OpenSSL (\d+\.\d+\.\d+)[a-z]?(?:-\w+)? +\d{1,2} \w{3} \d{4}/g;
    my $is_libcrypto = $name =~ /^libcrypto-.*\.dll\z/i;
    if (scalar(keys %found) > 1 || ($is_libcrypto && !%found)) {
        push @errors, "$entry: cannot determine the OpenSSL version";
    } elsif (%found) {
        my ($version) = keys %found;
        $versions{$version} = 1;
        print "$entry: OpenSSL $version\n";
        push @errors, "$entry: OpenSSL $version is older than " . join('.', @min_version)
            if version_lt([split(/\./, $version)], \@min_version);
    }

    # Every OpenSSL DLL a bundled DLL imports must be bundled too: otherwise
    # Windows resolves it from PATH (e.g. a Strawberry install) or fails to load.
    my $imports = pe_imports($content);
    if (!defined($imports)) {
        push @errors, "$entry: cannot read the PE import table";
        next;
    }
    foreach my $import (grep { /^lib(?:ssl|crypto)-/i } @$imports) {
        push @errors, "$entry: imports $import, which is not bundled"
            if !$bundled{lc($import)};
        $net_ssleay_imports++ if $entry =~ m{/Net/SSLeay/SSLeay\.xs\.dll\z}i;
    }
}

# Positive control: Net::SSLeay must be found importing OpenSSL, so a broken
# import parser cannot let the check pass silently.
push @errors, 'Net::SSLeay XS DLL not found, or not importing libssl/libcrypto'
    if $net_ssleay_imports < 2;
foreach my $lib ('libssl', 'libcrypto') {
    push @errors, "no bundled $lib DLL found"
        if !grep { /^\Q$lib\E-.*\.dll\z/ } keys %bundled;
}
push @errors, 'several OpenSSL versions are bundled: ' . join(', ', sort keys %versions)
    if scalar(keys %versions) > 1;

if (@errors) {
    print STDERR "ERROR: $_\n" foreach @errors;
    exit 1;
}
if (defined($ENV{GITHUB_STEP_SUMMARY}) && open(my $fh, '>>', $ENV{GITHUB_STEP_SUMMARY})) {
    print $fh 'Bundled OpenSSL: ' . join(', ', sort keys %versions) . "\n";
    close($fh);
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

# Return the DLL names of the PE import table, or undef if the file cannot be
# parsed. Pure Perl, so the result does not depend on the objdump found on PATH.
sub pe_imports {
    my ($data) = @_;
    my $len = length($data);
    return undef if $len < 64 || substr($data, 0, 2) ne 'MZ';
    my $pe = unpack('V', substr($data, 0x3c, 4));
    return undef if $pe + 24 > $len || substr($data, $pe, 4) ne "PE\0\0";
    my ($sections_count, $optional_size) = unpack('v x12 v', substr($data, $pe + 6, 16));
    my $optional = $pe + 24;
    my $magic = unpack('v', substr($data, $optional, 2));
    my $directories = $magic == 0x20b ? $optional + 112 : $magic == 0x10b ? $optional + 96 : return undef;
    my ($import_rva) = unpack('V', substr($data, $directories + 8, 4));
    return [] if !$import_rva;

    my @sections;
    for my $i (0 .. $sections_count - 1) {
        my $header = $optional + $optional_size + $i * 40;
        return undef if $header + 40 > $len;
        push @sections, [unpack('x8 V V V V', substr($data, $header, 24))];
    }
    my $rva_to_offset = sub {
        my ($rva) = @_;
        foreach (@sections) {
            my ($virtual_size, $virtual_address, $raw_size, $raw_offset) = @$_;
            my $size = $virtual_size > $raw_size ? $virtual_size : $raw_size;
            return $raw_offset + $rva - $virtual_address
                if $rva >= $virtual_address && $rva < $virtual_address + $size;
        }
        return undef;
    };

    my $descriptor = $rva_to_offset->($import_rva);
    return undef if !defined($descriptor);
    my @names;
    while (1) {
        return undef if $descriptor + 20 > $len;
        my ($name_rva, $first_thunk) = unpack('x12 V V', substr($data, $descriptor, 20));
        last if !$name_rva && !$first_thunk;
        my $name_offset = $rva_to_offset->($name_rva);
        return undef if !defined($name_offset) || $name_offset >= $len;
        push @names, unpack('Z*', substr($data, $name_offset, 256));
        $descriptor += 20;
    }
    return \@names;
}
