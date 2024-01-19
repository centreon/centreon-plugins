#
# Copyright 2024 Centreon (http://www.centreon.com/)
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
use Digest::MD5 qw(md5_hex);

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
        { label => 'gateway-calls-connected', nlabel => 'gateway.calls.connected.count', set => {
                key_values => [ { name => 'gateway_calls_connected_count' }, { name => 'display' } ],
                output_template => 'connected calls: %d',
                perfdatas => [
                    { template => '%d', min => 0, unit => '', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'gateway-calls-ongoing', nlabel => 'gateway.calls.ongoing.count', set => {
                key_values => [ { name => 'gateway_calls_ongoing_count' }, { name => 'display' } ],
                output_template => 'ongoing calls: %d',
                perfdatas => [
                    { template => '%d', min => 0, unit => '', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'gateway-calls-accumulated', nlabel => 'gateway.calls.accumulated.count', set => {
                key_values => [ { name => 'gateway_calls_accumulated_count', diff => 1 }, { name => 'display' } ],
                output_template => 'total accumulated calls: %d',
                perfdatas => [
                    { template => '%d', min => 0, unit => '', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{isdn} = [
        { label => 'isdn-calls-connected', nlabel => 'isdn.calls.connected.count', set => {
                key_values => [ { name => 'isdn_calls_connected_count' }, { name => 'display' } ],
                output_template => 'connected calls: %d',
                perfdatas => [
                    { template => '%d', min => 0, unit => '', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'isdn-calls-ongoing', nlabel => 'isdn.calls.ongoing.count', set => {
                key_values => [ { name => 'isdn_calls_ongoing_count' }, { name => 'display' } ],
                output_template => 'ongoing calls: %d',
                perfdatas => [
                    { template => '%d', min => 0, unit => '', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'isdn-calls-accumulated', nlabel => 'isdn.calls.accumulated.count', set => {
                key_values => [ { name => 'isdn_calls_accumulated_count', diff => 1 }, { name => 'display' } ],
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $gwEntry = '.1.3.6.1.4.1.1768.100.70.40.2.1';
my $isdnPortEntry = '.1.3.6.1.4.1.1768.100.70.50.2.1';

my $mappingGw = {
    display => { oid => '.1.3.6.1.4.1.1768.100.70.40.2.1.1' }, # gwDescr
    gateway_calls_connected_count => { oid => '.1.3.6.1.4.1.1768.100.70.40.2.1.2' }, # gwCurrentConnectedCalls
    gateway_calls_ongoing_count => { oid => '.1.3.6.1.4.1.1768.100.70.40.2.1.3' }, # gwCurrentOngoingCalls
    gateway_calls_accumulated_count => { oid => '.1.3.6.1.4.1.1768.100.70.40.2.1.4' } # gwTotalAccumulatedCalls
};
my $mappingIsdn = {
    display => { oid => '.1.3.6.1.4.1.1768.100.70.50.2.1.1' }, # isdnPortDescr
    isdn_calls_connected_count => { oid => '.1.3.6.1.4.1.1768.100.70.50.2.1.2' }, # isdnPortCurrentConnectedCalls
    isdn_calls_ongoing_count => { oid => '.1.3.6.1.4.1.1768.100.70.50.2.1.3' }, # isdnPortCurrentOngoingCalls
    isdn_calls_accumulated_count => { oid => '.1.3.6.1.4.1.1768.100.70.50.2.1.4' } # isdnPortTotalAccumulatedCalls
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'patton_smartnode_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $snmp_results = $options{snmp}->get_multiple_table(oids => [
        { oid => $gwEntry },
        { oid => $isdnPortEntry }
    ], nothing_quit => 1);

    $self->{gateway} = {};
    foreach my $oid (keys %{$snmp_results->{$gwEntry}}) {
        next if ($oid !~ /^$mappingGw->{display}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mappingGw, results => $snmp_results->{$gwEntry}, instance => $instance);
        $self->{gateway}->{$instance} = { display => $instance,
            %$result
        };
    }

    $self->{isdn} = {};
    foreach my $oid (keys %{$snmp_results->{$isdnPortEntry}}) {
        next if ($oid !~ /^$mappingIsdn->{display}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mappingIsdn, results => $snmp_results->{$isdnPortEntry}, instance => $instance);
        $self->{isdn}->{$instance} = { display => $instance,
            %$result
        };
    }
}

1;

__END__

=head1 MODE

Check system usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^gateway-calls-connected$'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'gateway-calls-connected', 'gateway-calls-ongoing', 'gateway-calls-accumulated',
'isdn-calls-connected', 'isdn-calls-ongoing', 'isdn-calls-accumulated'.

=back

=cut
