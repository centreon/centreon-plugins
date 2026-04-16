#!/usr/bin/perl
use strict;
use warnings;
use Test2::V0;
use Test2::Plugin::NoWarnings echo => 1;

use FindBin;
use lib "$FindBin::RealBin/../../../src";

# Tests that Centreon functions get_leef, get_table, and get_multiple_table return the same values as
# snmpget/snmpwalk calls from the snmplogger module.
# The snmpget and snmpwalk binaries must be installed.
# For get_leef_cache and get_table_cache, only log generation is verified.
# get_multiple_table_cache is not tested since it just calls get_table_cache.

my @_extract_commands = ();

{
    package MockOptions;
    sub new { bless {}, shift }
    sub add_options { }
    sub add_help { }
}

{
    package MockOutput;

    sub new { bless {}, shift }
    sub add_option_msg {  }
    sub output_add {
        my ($self, %options) = @_;
        # Extract command from log
        push @_extract_commands, $1
            if $options{long_msg} =~ /^snmp request: (?:\[\d\] )?(.+)$/;
    }
    sub option_exit {  }
    sub is_debug { 1 }
    sub is_litteral_status { }
}

sub flatten_hash {
    my ($hash) = @_;

    my %result;

    while (my ($key, $value) = each %$hash) {
        if (ref $value eq 'HASH') {
            %result = (%result, %$value);
        } else {
            $result{$key} = $value;
        }
    }

    return \%result;
}

use centreon::plugins::snmp;

my $snmp = centreon::plugins::snmp->new(options => MockOptions->new(),
                                        output => MockOutput->new());

# Test get_leef
my %options = ( snmp_version => '2c',
                snmp_port => $ENV{'TEST_SNMP_PORT'} || 2000,
                snmp_retries => 5,
                snmp_timeout => 1,
                host => $ENV{'TEST_SNMP_LOCALHOST'} || 'localhost',
                snmp_errors_exit => 'unknown');


my @tests = ( { snmp_command => 'snmpget',
                perl_command => 'get_leef',
                snmp_community => 'snmp_standard/network-mellanox',
                query => { oids => ['.1.3.6.1.2.1.2.2.1.7.109', '.1.3.6.1.2.1.2.2.1.8.109', '.1.3.6.1.2.1.2.2.1.7.96',
                                    '.1.3.6.1.2.1.2.2.1.8.73', '.1.3.6.1.2.1.2.2.1.7.29100', '.1.3.6.1.2.1.2.2.1.8.29100'] }
              },
              { snmp_command => 'snmpwalk',
                perl_command => 'get_table',
                snmp_community => 'hardware/server/lenovo/xcc/snmp/system-health-critical',
                query => { oid => '.1.3.6.1.4.1.19046.11.1.1.13.1.7.1', end => '.1.3.6.1.4.1.19046.11.1.1.13.1.7.1.4' }
              },
              { snmp_command => 'snmpwalk',
                perl_command => 'get_multiple_table',
                snmp_community => 'hardware/server/lenovo/xcc/snmp/system-health-critical',
                query => { oids => [ { oid => '.1.3.6.1.4.1.19046.11.1.1.13.1.7.1', end => '.1.3.6.1.4.1.19046.11.1.1.13.1.7.1.4' },
                                     { oid => '.1.3.6.1.4.1.19046.11.1.1.4.2.1' } ] }
              },
              { snmp_command => '(cached) snmpget',
                perl_command => 'get_leef_cache',
                snmp_community => 'snmp_standard/network-mellanox',
                query => { oids => ['.1.1.1.1.1' ], nothing_quit => 1 }
              },
              { snmp_command => '(cached) snmpwalk',
                perl_command => 'get_table_cache',
                snmp_community => 'snmp_standard/network-mellanox',
                query => { oid => ['.1.1.1.1.1' ], nothing_quit => 1 }
              }
            );

foreach my $prog (qw/snmpget snmpwalk/) {
    plan skip_all => "Program $prog is required" unless
        `which $prog` =~ $prog;
}

foreach my $test (@tests) {
    @_extract_commands = ();
    $options{snmp_community} = $test->{snmp_community};
    $snmp->check_options(option_results => \%options);
    $snmp->connect();

    my $perl_command = $snmp->can($test->{perl_command});
    my $result = $perl_command->($snmp, %{$test->{query}});

    my $expected = $test->{snmp_command};
    ok(@_extract_commands > 0 && $_extract_commands[0] =~ /^\Q$expected/, $test->{perl_command}." returns valid command");

    if ($expected !~ /^\(/ && @_extract_commands && $_extract_commands[0] =~ /^\Q$expected/) {
        my $resu = join '', map { `$_` } @_extract_commands;

        ok(ref $result eq 'HASH' && keys %$result > 0, $test->{perl_command}." returns values");

        $result = flatten_hash($result);

        foreach (split /\n/, $resu) {
            unless (/^([\d\.]+)[^:]+: (.+)$/) {
                fail("Invalid data: $_");
                next
            }
            my ($oid, $value) = ($1, $2);
            $value =~ s/^"//;
            $value =~ s/"$//;

            ok(exists $result->{$oid}, "$oid exists in perl");
            ok($result->{$oid} eq $value, "$oid has same value $result->{$oid} == $value");
            delete $result->{$oid};
        }
        ok(keys %$result == 0, $test->{snmp_command}." and ".$test->{perl_command}." returns same values");
    }
}

done_testing();
