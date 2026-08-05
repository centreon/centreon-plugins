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

sub prefix_memory_output {
    my ($self, %options) = @_;

    return 'Memory usage ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_memory_output', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'host', nlabel => 'memory.protected_host.percentage', set => {
                key_values => [ { name => 'host' } ],
                output_template => 'protected host: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'frag', nlabel => 'memory.fragmented.percentage', set => {
                key_values => [ { name => 'frag' } ],
                output_template => 'fragmented: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'conn', nlabel => 'memory.connections.percentage', set => {
                key_values => [ { name => 'asq' } ],
                output_template => "ASQ: %.2f%%",
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'icmp', nlabel => 'memory.icmp.percentage', set => {
                key_values => [ { name => 'icmp' } ],
                output_template => 'icmp: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'dtrack', nlabel => 'memory.data_tracking.percentage', set => {
                key_values => [ { name => 'dtrack' } ],
                output_template => "Data Tracking: %.2f%%",
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'dyn', nlabel => 'memory.dynamic.percentage', set => {
                key_values => [ { name => 'dyn' } ],
                output_template => 'dynamic: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'etherstate', nlabel => 'memory.ether_state.percentage', set => {
                key_values => [ { name => 'etherstate' } ],
                output_template => "EtherState: %s%%",
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'socket',nlabel => 'memory.socket.percentage', set => {
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

        # only for version >= 4.8.9
        { label => 'user', nlabel => 'memory.user.percentage', set => {
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
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
        $mem_values{'conn'}        = $snmp_result->{'.1.3.6.1.4.1.11256.1.10.10.1.5.1'};
        $mem_values{'etherstate'} = $snmp_result->{'.1.3.6.1.4.1.11256.1.10.10.1.6.1'};
        $mem_values{'dtrack'}     = $snmp_result->{'.1.3.6.1.4.1.11256.1.10.10.1.7.1'};
        $mem_values{'dyn'}     = $snmp_result->{'.1.3.6.1.4.1.11256.1.10.10.1.8.1'};
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
            $mem_values{'conn'}        = $values[3];
            $mem_values{'etherstate'} = $values[4];
            $mem_values{'dtrack'}     = $values[5];
            $mem_values{'dyn'}     = $values[6];

            if ($fields == 8) {
                $mem_values{'socket'} = $values[7];
            }
        }
    }

    # Cleaning and Converting Values
    my $total = 0;
    foreach my $key (keys %mem_values) {
        if (defined $mem_values{$key}) {
            $mem_values{$key} =~ s/%//g;
            $mem_values{$key} =~ s/^\s+|\s+$//g;
            # If the value is not a number, it is removed
            if ($mem_values{$key} !~ /^\d+\.?\d*$/) {
                delete $mem_values{$key};
                next;
            }
            $total += $mem_values{$key};
        } else {
            delete $mem_values{$key};
        }
    }
    $mem_values{total} = $total;

    $self->{global} = \%mem_values;
}

1;

__END__

=head1 MODE

Check memory utilization on Stormshield firewalls.

=over 8

=item B<--warning-total>

Threshold.

=item B<--warning-host>

Threshold.

=item B<--warning-frag>

Threshold.

=item B<--warning-conn>

Threshold.

=item B<--warning-icmp>

Threshold.

=item B<--warning-dtrack>

Threshold.

=item B<--warning-dyn>

Threshold.

=item B<--warning-etherstate>

Threshold.

=item B<--warning-socket>

Threshold.
=item B<--warning-user>

Threshold. only for version >= 4.8.9

=item B<--critical-total>

Threshold.

=item B<--critical-host>

Threshold.

=item B<--critical-frag>

Threshold.

=item B<--critical-conn>

Threshold.

=item B<--critical-icmp>

Threshold.

=item B<--critical-dtrack>

Threshold.

=item B<--critical-dyn>

Threshold.

=item B<--critical-etherstate>

Threshold.

=item B<--critical-socket>

Threshold.

=item B<--critical-user>

Threshold. only for version >= 4.8.9

=back

=cut
