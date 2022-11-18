#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package network::patton::smartnode::snmp::mode::call;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_gateway_output {
    my ($self, %options) = @_;
    return "Gateway '".$options{instance_value}->{display}."' ";
}

sub prefix_isdn_output {
    my ($self, %options) = @_;
    return "ISDN '".$options{instance_value}->{display}."' ";
}

sub set_counters {
    my ($self, %options) = @_;

     $self->{maps_counters_type} = [
        { name => 'gateway', type => 1, cb_prefix_output => 'prefix_gateway_output', message_multiple => 'All gateways are ok' },
        { name => 'isdn', type => 1, cb_prefix_output => 'prefix_isdn_output', message_multiple => 'All ISDN are ok' }
    ];

    $self->{maps_counters}->{gateway} = [
        { label => 'gateway-current-connected-calls', nlabel => 'gateway.current.connected.calls', set => {
                key_values => [ { name => 'gateway_current_connected_calls' }, { name => 'display' } ],
                output_template => 'connected calls: %d',
                perfdatas => [
                    { template => '%d', min => 0, unit => '', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'gateway-current-ongoing-calls', nlabel => 'gateway.current.ongoing.calls', set => {
                key_values => [ { name => 'gateway_current_ongoing_calls' }, { name => 'display' } ],
                output_template => 'ongoing calls: %d',
                perfdatas => [
                    { template => '%d', min => 0, unit => '', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'gateway-total-accumulated-calls', nlabel => 'gateway.total.accumulated.calls', set => {
                key_values => [ { name => 'gateway_total_accumulated_calls' }, { name => 'display' } ],
                output_template => 'total accumulated calls: %d',
                perfdatas => [
                    { template => '%d', min => 0, unit => '', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{isdn} = [
        { label => 'isdn-current-connected-calls', nlabel => 'isdn.current.connected.calls', set => {
                key_values => [ { name => 'isdn_current_connected_calls' }, { name => 'display' } ],
                output_template => 'connected calls: %d',
                perfdatas => [
                    { template => '%d', min => 0, unit => '', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'isdn-current-ongoing-calls', nlabel => 'isdn.current.ongoing.calls', set => {
                key_values => [ { name => 'isdn_current_ongoing_calls' }, { name => 'display' } ],
                output_template => 'ongoing calls: %d',
                perfdatas => [
                    { template => '%d', min => 0, unit => '', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'isdn-total-accumulated-calls', nlabel => 'isdn.total.accumulated.calls', set => {
                key_values => [ { name => 'isdn_total_accumulated_calls' }, { name => 'display' } ],
                output_template => 'total accumulated calls: %d',
                perfdatas => [
                    { template => '%d', min => 0, unit => '', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $gwEntry_oid = '.1.3.6.1.4.1.1768.100.70.40.2.1';
my $gwDescr_oid = '.1.3.6.1.4.1.1768.100.70.40.2.1.1';
my $gwCurrentConnectedCalls_oid = '.1.3.6.1.4.1.1768.100.70.40.2.1.2';
my $gwCurrentOngoingCalls_oid = '.1.3.6.1.4.1.1768.100.70.40.2.1.3';
my $gwTotalAccumulatedCalls_oid = '.1.3.6.1.4.1.1768.100.70.40.2.1.4';

my $isdnPortEntry_oid = '.1.3.6.1.4.1.1768.100.70.50.2.1';
my $isdnPortDescr_oid = '.1.3.6.1.4.1.1768.100.70.50.2.1.1';
my $isdnPortCurrentConnectedCalls_oid = '.1.3.6.1.4.1.1768.100.70.50.2.1.2';
my $isdnPortCurrentOngoingCalls_oid = '.1.3.6.1.4.1.1768.100.70.50.2.1.3';
my $isdnPortTotalAccumulatedCalls_oid = '.1.3.6.1.4.1.1768.100.70.50.2.1.4';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_results = $options{snmp}->get_multiple_table(oids => [
        { oid => $gwEntry_oid },
        { oid => $isdnPortEntry_oid }
    ], nothing_quit => 1);

    my $gatewayEntry = $snmp_results->{$gwEntry_oid};
    my $numGateway = 1;
    $self->{gateway} = {};
    while ($gatewayEntry->{$gwDescr_oid.".".$numGateway}) {
        my $gatewayObj = $self->{gateway}->{ $gatewayEntry->{$gwDescr_oid.".".$numGateway} } = {};
        $gatewayObj->{display} = $gatewayEntry->{$gwDescr_oid.".".$numGateway};
        $gatewayObj->{gateway_current_connected_calls} = $gatewayEntry->{$gwCurrentConnectedCalls_oid.".".$numGateway};
        $gatewayObj->{gateway_current_ongoing_calls} = $gatewayEntry->{$gwCurrentOngoingCalls_oid.".".$numGateway};
        $gatewayObj->{gateway_total_accumulated_calls} = $gatewayEntry->{$gwTotalAccumulatedCalls_oid.".".$numGateway};
        $numGateway++;
    }

    my $isdnEntry = $snmp_results->{$isdnPortEntry_oid};
    my $numIsdn = 1;
    $self->{isdn} = {};
    while ($isdnEntry->{$isdnPortDescr_oid.".".$numIsdn}) {
        my $isdnObj = $self->{isdn}->{ $isdnEntry->{$isdnPortDescr_oid.".".$numIsdn} } = {};
        $isdnObj->{display} = $isdnEntry->{$isdnPortDescr_oid.".".$numIsdn};
        $isdnObj->{isdn_current_connected_calls} = $isdnEntry->{$isdnPortCurrentConnectedCalls_oid.".".$numIsdn};
        $isdnObj->{isdn_current_ongoing_calls} = $isdnEntry->{$isdnPortCurrentOngoingCalls_oid.".".$numIsdn};
        $isdnObj->{isdn_total_accumulated_calls} = $isdnEntry->{$isdnPortTotalAccumulatedCalls_oid.".".$numIsdn};
        $numIsdn++;
    }
}

1;

__END__

=head1 MODE

Check system usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^gateway-current-connected-calls$'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'gateway-current-connected-calls', 'gateway-current-ongoing-calls', 'gateway-total-accumulated-calls',
'isdn-current-connected-calls', 'isdn-current-ongoing-calls', 'isdn-total-accumulated-calls'.

=back

=cut
