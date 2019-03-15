#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package network::riverbed::interceptor::snmp::mode::interfaces;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'interface', type => 1, cb_prefix_output => 'prefix_interface_output',
          message_multiple => 'All interfaces are ok' },
    ];
    
    $self->{maps_counters}->{interface} = [
        { label => 'packets-in-dropped', set => {
                key_values => [ { name => 'interfaceRxDrops', diff => 1 }, { name => 'display' } ],
                output_template => 'Packets In Dropped (NIC): %d packets/s',
                per_second => 1,
                perfdatas => [
                    { label => 'packets_in_dropped', value => 'interfaceRxDrops_absolute', template => '%d', min => 0,
                      unit => 'packets/s', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'packets-out-dropped', set => {
                key_values => [ { name => 'interfaceTxDrops', diff => 1 }, { name => 'display' } ],
                output_template => 'Packets Out Dropped (NIC): %d packets/s',
                per_second => 1,
                perfdatas => [
                    { label => 'packets_out_dropped', value => 'interfaceTxDrops_absolute', template => '%d', min => 0,
                      unit => 'packets/s', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'packets-soft-dropped', set => {
                key_values => [ { name => 'interfaceSoftwareDrops', diff => 1 }, { name => 'display' } ],
                output_template => 'Packets Dropped (Software): %d packets/s',
                per_second => 1,
                perfdatas => [
                    { label => 'packets_soft_dropped', value => 'interfaceSoftwareDrops', template => '%d', min => 0,
                      unit => 'packets/s', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'packets-xoff', set => {
                key_values => [ { name => 'interfaceFlowCtrlPkts', diff => 1 }, { name => 'display' } ],
                output_template => 'XOFF Flow Control Packets Transmitted: %d packets/s',
                per_second => 1,
                perfdatas => [
                    { label => 'packets_xoff', value => 'interfaceFlowCtrlPkts', template => '%d', min => 0,
                      unit => 'packets/s', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub prefix_interface_output {
    my ($self, %options) = @_;
    
    return "Interface '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $self->{version} = '0.1';
    $options{options}->add_options(arguments => {
    });
    return $self;
}

my $mappings = {
    int => {
        interfaceName => { oid => '.1.3.6.1.4.1.17163.1.3.2.9.1.2' },
        interfaceRxDrops => { oid => '.1.3.6.1.4.1.17163.1.3.2.9.1.3' },
        interfaceTxDrops => { oid => '.1.3.6.1.4.1.17163.1.3.2.9.1.4' },
        interfaceSoftwareDrops => { oid => '.1.3.6.1.4.1.17163.1.3.2.9.1.5' },
        interfaceFlowCtrlPkts => { oid => '.1.3.6.1.4.1.17163.1.3.2.9.1.6' },
    },
};

my $oids = {
    int => '.1.3.6.1.4.1.17163.1.3.2.9.1',
};

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oids->{int},
              start => $mappings->{int}->{interfaceName}->{oid},
              end => $mappings->{int}->{interfaceFlowCtrlPkts}->{oid} }
        ]
    );
    
    foreach my $equipment (keys %{$oids}) {
        next if (!%{$results->{$oids->{$equipment}}});
        foreach my $oid (keys %{$results->{$oids->{$equipment}}}) {
            next if ($oid !~ /^$mappings->{$equipment}->{interfaceName}->{oid}\.(\d+)/);
            my $instance = $1;

            my $result = $options{snmp}->map_instance(mapping => $mappings->{$equipment},
                results => $results->{$oids->{$equipment}}, instance => $instance);
                
            $self->{interface}->{$result->{interfaceName}} = {
                display => $result->{interfaceName},
                interfaceRxDrops => $result->{interfaceRxDrops},
                interfaceTxDrops => $result->{interfaceTxDrops},
                interfaceSoftwareDrops => $result->{interfaceSoftwareDrops},
                interfaceFlowCtrlPkts => $result->{interfaceFlowCtrlPkts}
            };
        }
    }

    $self->{cache_name} = "riverbed_steelhead_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() .
        '_' . $self->{mode} . '_' . md5_hex('all');
}

1;

__END__

=head1 MODE

Check interfaces packets.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'packets-in-dropped', 'packets-out-dropped',
'packets-soft-dropped', 'packets-xoff'.

=item B<--critical-*>

Threshold critical.
Can be: 'packets-in-dropped', 'packets-out-dropped',
'packets-soft-dropped', 'packets-xoff'.

=back

=cut
