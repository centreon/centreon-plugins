#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package network::stormshield::snmp::mode::memorydetailed;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw/:counters :values/;
use centreon::plugins::misc;

my @mem_labels = qw(asq icmp frag host system dtrack socket etherstate user);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'asq', set => {
                key_values => [ { name => 'asq' } ],
                output_template => "ASQ: %s%%",
                perfdatas => [
                    {
                        label => 'mem_asq',
                        value => 'asq',
                        template => '%s',
                        unit => '%',
                        min => 0,
                        max => 100,
                    }
                ]
            }
        },
        { label => 'icmp', set => {
                key_values => [ { name => 'icmp' } ],
                output_template => "ICMP: %s%%",
                perfdatas => [
                    {
                        label => 'mem_icmp',
                        value => 'icmp',
                        template => '%s',
                        unit => '%',
                        min => 0,
                        max => 100,
                    }
                ]
            }
        },
        { label => 'frag', set => {
                key_values => [ { name => 'frag' } ],
                output_template => "Frag: %s%%",
                perfdatas => [
                    {
                        label => 'mem_frag',
                        value => 'frag',
                        template => '%s',
                        unit => '%',
                        min => 0,
                        max => 100,
                    }
                ]
            }
        },
        { label => 'host', set => {
                key_values => [ { name => 'host' } ],
                output_template => "Host: %s%%",
                perfdatas => [
                    {
                        label => 'mem_host',
                        value => 'host',
                        template => '%s',
                        unit => '%',
                        min => 0,
                        max => 100,
                    }
                ]
            }
        },
        { label => 'system', set => {
                key_values => [ { name => 'system' } ],
                output_template => "System: %s%%",
                perfdatas => [
                    {
                        label => 'mem_system',
                        value => 'system',
                        template => '%s',
                        unit => '%',
                        min => 0,
                        max => 100,
                    }
                ]
            }
        },
        { label => 'dtrack', set => {
                key_values => [ { name => 'dtrack' } ],
                output_template => "Data Tracking: %s%%",
                perfdatas => [
                    {
                        label => 'mem_dtrack',
                        value => 'dtrack',
                        template => '%s',
                        unit => '%',
                        min => 0,
                        max => 100,
                    }
                ]
            }
        },
        { label => 'socket', set => {
                key_values => [ { name => 'socket' } ],
                output_template => "Socket: %s%%",
                perfdatas => [
                    {
                        label => 'mem_socket',
                        value => 'socket',
                        template => '%s',
                        unit => '%',
                        min => 0,
                        max => 100,
                    }
                ]
            }
        },
        { label => 'etherstate', set => {
                key_values => [ { name => 'etherstate' } ],
                output_template => "EtherState: %s%%",
                perfdatas => [
                    {
                        label => 'mem_etherstate',
                        value => 'etherstate',
                        template => '%s',
                        unit => '%',
                        min => 0,
                        max => 100,
                    }
                ]
            }
        },
        # only for version >= 4.8.9
        { label => 'user', set => {
                key_values => [ { name => 'user' } ],
                output_template => "User: %s%%",
                perfdatas => [
                    {
                        label => 'mem_user',
                        value => 'user',
                        template => '%s',
                        unit => '%',
                        min => 0,
                        max => 100,
                    }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "warning:s"  => { name => 'warning_memory' },
        "critical:s" => { name => 'critical_memory' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    foreach my $label (@mem_labels) {
        if (($self->{perfdata}->threshold_validate(label => 'warning-' . $label,value => $self->{option_results}->{warning_memory})) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning_memory} . "'.");
            $self->{output}->option_exit();
        }
        if (($self->{perfdata}->threshold_validate(label => 'critical-' . $label,value => $self->{option_results}->{critical_memory})) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical_memory} . "'.");
            $self->{output}->option_exit();
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_os_version = '.1.3.6.1.4.1.11256.1.0.2.0';

    # Récupération de la version pour déterminer quel OID utiliser
    my $snmp_result = $options{snmp}->get_leef(oids => [ $oid_os_version ], nothing_quit => 1);
    my $version_raw = $snmp_result->{$oid_os_version};
    my $version_clean = $version_raw;
    $version_clean =~ s/([0-9]+(?:\.[0-9]+)*).*/$1/;

    my %mem_values;
    my $is_new_version = centreon::plugins::misc::minimal_version($version_clean, '4.8.9');

    if ($is_new_version) {
        # version >= 4.8.9
        my $oids = [
            '.1.3.6.1.4.1.11256.1.10.10.1.2.1',  # snsMemHost
            '.1.3.6.1.4.1.11256.1.10.10.1.3.1',  # snsMemFrag
            '.1.3.6.1.4.1.11256.1.10.10.1.4.1',  # snsMemIcmp
            '.1.3.6.1.4.1.11256.1.10.10.1.5.1',  # snsMemConn
            '.1.3.6.1.4.1.11256.1.10.10.1.6.1',  # snsMemEther
            '.1.3.6.1.4.1.11256.1.10.10.1.7.1',  # snsMemDataTrack
            '.1.3.6.1.4.1.11256.1.10.10.1.8.1',  # snsMemSystem
            '.1.3.6.1.4.1.11256.1.10.10.1.9.1',  # snsMemUser
            '.1.3.6.1.4.1.11256.1.10.10.1.10.1'  # snsMemMbuf
        ];

        $snmp_result = $options{snmp}->get_leef(oids => $oids, nothing_quit => 1);

        $mem_values{'host'}       = $snmp_result->{'.1.3.6.1.4.1.11256.1.10.10.1.2.1'};
        $mem_values{'frag'}       = $snmp_result->{'.1.3.6.1.4.1.11256.1.10.10.1.3.1'};
        $mem_values{'icmp'}       = $snmp_result->{'.1.3.6.1.4.1.11256.1.10.10.1.4.1'};
        $mem_values{'asq'}        = $snmp_result->{'.1.3.6.1.4.1.11256.1.10.10.1.5.1'};
        $mem_values{'etherstate'} = $snmp_result->{'.1.3.6.1.4.1.11256.1.10.10.1.6.1'};
        $mem_values{'dtrack'}     = $snmp_result->{'.1.3.6.1.4.1.11256.1.10.10.1.7.1'};
        $mem_values{'system'}     = $snmp_result->{'.1.3.6.1.4.1.11256.1.10.10.1.8.1'};
        $mem_values{'user'}       = $snmp_result->{'.1.3.6.1.4.1.11256.1.10.10.1.9.1'};
        $mem_values{'socket'}     = $snmp_result->{'.1.3.6.1.4.1.11256.1.10.10.1.10.1'};

    } else {
        # oid for version < 4.8.9
        my $oid_snsMem = '.1.3.6.1.4.1.11256.1.10.3.0';
        $snmp_result = $options{snmp}->get_leef(oids => [ $oid_snsMem ], nothing_quit => 1);

        my @values = split(/,/, $snmp_result->{$oid_snsMem});
        my $fields = scalar(@values);
        if ($fields >= 7) {
            $mem_values{'host'}       = $values[0];
            $mem_values{'frag'}       = $values[1];
            $mem_values{'icmp'}       = $values[2];
            $mem_values{'asq'}        = $values[3];
            $mem_values{'etherstate'} = $values[4];
            $mem_values{'dtrack'}     = $values[5];
            $mem_values{'system'}     = $values[6];

            if ($fields == 8) {
                $mem_values{'socket'} = $values[7];
            }
        }
    }

        # Cleaning and Converting Values
    foreach my $key (keys %mem_values) {
        if (defined $mem_values{$key}) {
            $mem_values{$key} =~ s/%//g;
            $mem_values{$key} =~ s/^\s+|\s+$//g;
            # If the value is not a number, it is removed
            if ($mem_values{$key} !~ /^\d+\.?\d*$/) {
                delete $mem_values{$key};
            }
        } else {
            delete $mem_values{$key};
        }
    }

    $self->{global} = \%mem_values;
}


1;

__END__

=head1 MODE

Check memory utilization on Stormshield firewalls.

=over 8

=item B<--warning>

Set warning threshold for all memory types (asq, icmp, frag, host, system, dtrack, socket, etherstate, user).

=item B<--critical>

Set critical threshold for all memory types (asq, icmp, frag, host, system, dtrack, socket, etherstate, user).

=back

=cut