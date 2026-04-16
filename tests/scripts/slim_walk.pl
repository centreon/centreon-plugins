#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Getopt::Long;
use File::Find;
use List::MoreUtils qw(uniq);
use Digest::MD5 qw(md5);

# Global variables for the parameters
my $snmpwalk_path = '';
my $module_path   = '';
my $no_anonymization;
my $help;
my $debug;

my @modules_to_parse;
my @oids_to_keep;

# For each type that must be anonymized, give the replacement string
my %type_anonymization = (
    'STRING'    => 'Anonymized ',
    'IpAddress' => '192.168.42.'
);
# If the value of the string matches this regex, we won't anonymize it:
# - interface names
# - system counters
# - disk paths
# - device names
# - loop
# - floating values (eg sysLoad)
my $ignore_anon_regex = qr{^"?(lo|eth[\d]*|.* memory|.*Swap.*|.*Memory.*|tmpfs|systemStats|systemd-udevd|kdevtmpfs|.*centreontrapd.*|gorgone-.*|[C-Z]:\\.*|(/[\d\w_-]*){1,}|sd[a-z]\d*|loop\d+|\d*\.?\d*)"?$};

sub oid_matches {
    my ($given_oid, $list) = @_;

    return 0 if (is_empty($given_oid) == 1);
    for my $oid (@$list) {
        if ($given_oid =~ /^$oid/) {
            print STDERR "OID $given_oid matches $oid\n"  if (defined($debug));;
            return 1;
        }
    }
    return 0;
}

sub extract_modes {
    my ($file_to_parse) = @_;
    my @modes;
    my $fd;
    open($fd, '<', $file_to_parse) or die "Could not open $file_to_parse to list modules from.";
    for my $line (<$fd>) {
        if ($line =~ /^.*custom_mode.* ?= ?["']([A-Za-z_:]+)["'];/ or $line =~ /^.* *=> *["']([A-Za-z_:]+)["'],? *$/) {
            my $module_to_push = $1;
            $module_to_push =~ s/::/\//g;
            $module_to_push = 'src/' . $module_to_push . '.pm';
            print STDERR "Mode found $module_to_push\n" if (defined($debug));
            push @modes, $module_to_push;
        }
    }
    return @modes;
}

sub extract_oids {
    my ($file_to_parse) = @_;
    my @oids;
    my $fd;
    open($fd, '<', $file_to_parse) or die "Could not open $file_to_parse to get OIDs from.";
    for my $line (<$fd>) {
        # Find all strings looking like OIDs
        if ($line =~ /.*['"](\.1\.[\.0-9]+)['"].*/) {
            print STDERR "Line $line contains an OID: '$1'\n" if (defined($debug));
            push @oids, $1;
        }
    }
    return @oids;
}

sub is_empty {
    my ($arg) = @_;
    return 1 if (!defined($arg) or $arg eq '');
    return 0;
}

# Args:
# - path of snmpwalk (mandatory)
# - path of the plugin or the mode to test
sub usage {
    return << "END_USAGE";
This scripts looks for the strictly necessary OIDs in a snmpwalk file, and excludes all the useless data.
Usage:
    slim_walk.pl --snmpwalk-path=path/to/file.snmpwalk [--module-path=path/to/file.pm] [--debug]

    --snmpwalk-path
        Define where the snmpwalk file to shrink and anonymize can be found (mandatory).
    --module-path
        Define where the Perl module where to look for OIDs to keep can be found.
        If this option is omitted, all the relevant modules (given where the walk can be found and how it's named)
        will be used.
    --no-anonymization
        Disable anonymization.
    --debug
        Enable DEBUG messages (printed on STDERR).

Examples:
    tests/scripts/slim_walk.pl --snmpwalk-path=tests/os/linux/snmp/linux.snmpwalk
    Will look for all OIDs referenced in src/os/linux/snmp and linked modules and exclude all data that is not related.

    tests/scripts/slim_walk.pl --snmpwalk-path=tests/os/linux/snmp/linux.snmpwalk --module-path=src/snmp_standard/mode/uptime.pm
    Will look for all OIDs referenced in src/snmp_standard/mode/uptime.pm and exclude all data that is not related.
END_USAGE

}
GetOptions (
    "snmpwalk-path=s"  => \$snmpwalk_path,
    "module-path=s"    => \$module_path,
    "no-anonymization" => \$no_anonymization,
    "help"             => \$help,
    "debug"            => \$debug
) or die(usage());

# Control arguments integrity
die(usage()) if (defined($help));
die "Argument --snmpwalk-path is mandatory.\n" . usage() if (is_empty($snmpwalk_path) == 1);
die "File $snmpwalk_path does not exist." if (!-e $snmpwalk_path);
print STDERR "Path: $snmpwalk_path exists.\n" if (defined($debug));

# If only the walk path is given, try to deduct the scope
# if name matches an existing mode, then the scope is presumably only this mode => only this .pm file
# else, find all .pm files of modes, custom modes located here and then find the external modules (eg from snmp_standard)

if (is_empty($module_path) != 1) {
    die "Module file $module_path not found." if (! -e $module_path);
    die "Module file $module_path is not a regular file." if (! -f $module_path);
    push @modules_to_parse, $module_path;
} else {
    # No module path: deduct the scope
    my ($base_path, $relative_path, $name) = $snmpwalk_path =~ /^(.*\/)?tests\/(.*)\/(.*)\.snmpwalk$/ or die "Not able to split path $snmpwalk_path as snmpwalk path";
    my $deducted_path = defined($base_path) ? $base_path : '.';
    $deducted_path .= "/src/$relative_path";
    print STDERR "Path $deducted_path name $name.\n" if (defined($debug));
    my $module_file = "$deducted_path/mode/$name.pm";
    if (-e $module_file) {
        print STDERR "There is a $module_file module!\n" if (defined($debug));
        # The module has been found, we'll only consider it
        push @modules_to_parse, $module_file;
    } else {
        # There is no module, we'll take all perl files under the path
        print STDERR "No $module_file module found! Looking for perl modules in $deducted_path.\n" if (defined($debug));
        find(
            sub {
                return unless -f;
                return unless /\.pm$/;
                push @modules_to_parse, $File::Find::name;
            },
            $deducted_path
        );
    }
}
# module path has been given or deducted, scope is more obvious

# if some files are named plugins.pm
#   list all the modes and custom-modes
for my $i (0..$#modules_to_parse) {
    my $current_module = $modules_to_parse[$i];
    print STDERR "$i => $current_module\n" if (defined($debug));
    if ($current_module =~ /.*\/plugin\.pm/) {
        # search for modes and custom modes
        push @modules_to_parse, extract_modes($current_module);
    }
}

# Now we should have listed all the .pm files that may be linked to the given parameters
# For each .pm file
for my $module (@modules_to_parse) {
    print STDERR "Considering module $module\n" if (defined($debug));
    push @oids_to_keep, extract_oids($module);
}

# Now we have all the oids, presumably with duplicates, let's filter it
# make it more efficient
print STDERR "Number of oids before: $#oids_to_keep\n" if (defined($debug));
@oids_to_keep = uniq @oids_to_keep;
print STDERR "Number of oids after: $#oids_to_keep\n" if (defined($debug));


my $nb_oids_total = 0;
my $nb_oids_accepted = 0;
# For each line of the walk
my $walk_fd;
open($walk_fd, '<', $snmpwalk_path) or die "Could not open $snmpwalk_path to purge OIDs from.";
my $last_line = '';
my $is_last_line_to_keep = 0;
for my $line (<$walk_fd>) {
    chomp $line;
    # remove all CR in the line
    $line =~ s/\r//g;
#   If the line does not begin with an OID
#       If the last processed line has been retained,
#           Then append it to the last accepted line
#       Else
#           Ignore
    if ($line !~ /^\.1/) {
        # this is not an OID, we may be reading the next part of an unfinished previous line
        if ($is_last_line_to_keep == 1) {
            $last_line .= $line;
        }
        next;
    }
    $nb_oids_total++;
    if ($is_last_line_to_keep == 1) {
        $nb_oids_accepted++;
        print("$last_line\n");
        $last_line = '';
        $is_last_line_to_keep = 0;
    }
    my ($line_oid, $line_type, $line_value) = $line =~ /^(\.1\.[\.\d]+) ?= ?(\w+:)? (.*)$/;
    die "Line $line cound not be parsed." if (is_empty($line_oid) == 1);
    next if (oid_matches($line_oid, \@oids_to_keep) != 1);
    my $type_str = defined($line_type) ? ' ' . $line_type . ' ' : ' ';
    $line = $line_oid . ' =' . $type_str . $line_value;

    if (!defined($no_anonymization) and defined($line_type) and is_empty($line_value) != 1 and $line_value ne '""') {
        $line_type =~ s/:$//;
        if (defined($type_anonymization{$line_type}) and $line_value !~ $ignore_anon_regex ) {
            my $md5_based_index = sprintf("%0.3d", unpack('L', md5($line_oid)) % 255);
            my $replacement     = $line_oid . ' = ' . $line_type . ': ' . $type_anonymization{$line_type} . $md5_based_index;
            $line = $replacement;
        }
    }


    $last_line = $line;
    $is_last_line_to_keep = 1;
}
# do not miss the last line
if ($is_last_line_to_keep == 1) {
    $nb_oids_accepted++;
    print("$last_line\n");
}
print STDERR "$nb_oids_accepted accepted OIDs out of $nb_oids_total\n";
#   Remove if it does not match any wanted OID
#   The next block replaces beautify_snmpwalk.py

