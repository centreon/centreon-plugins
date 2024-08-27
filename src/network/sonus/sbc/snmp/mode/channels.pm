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

package network::sonus::sbc::snmp::mode::channels;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg;
    if ($self->{result_values}->{admstatus} eq 'disabled') {
        $msg = 'is disabled (admin)';
    } else {
        $msg = 'oper status: ' . $self->{result_values}->{opstatus};
    }

    return $msg;
}

sub prefix_channel_output {
    my ($self, %options) = @_;

    return sprintf(
        "channel '%s/%s/%s/%s' ",
        $options{instance_value}->{shelf},
        $options{instance_value}->{slot},
        $options{instance_value}->{port},
        $options{instance_value}->{channel}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'number of channels ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'channels', type => 1, cb_prefix_output => 'prefix_channel_output', message_multiple => 'All channels are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'channels-total', nlabel => 'channels.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'channels-outofservice', nlabel => 'channels.outofservice.count', display_ok => 0, set => {
                key_values => [ { name => 'outofservice' } ],
                output_template => 'out of service: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'channels-idle', nlabel => 'channels.idle.count', display_ok => 0, set => {
                key_values => [ { name => 'idle' } ],
                output_template => 'idle: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'channels-pending', nlabel => 'channels.pending.count', display_ok => 0, set => {
                key_values => [ { name => 'pending' } ],
                output_template => 'pending: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'channels-waitingforroute', nlabel => 'channels.waiting_for_route.count', display_ok => 0, set => {
                key_values => [ { name => 'waitingforroute' } ],
                output_template => 'waiting for route: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'channels-actionlist', nlabel => 'channels.action_list.count', display_ok => 0, set => {
                key_values => [ { name => 'actionlist' } ],
                output_template => 'action list: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },		
        { label => 'channels-waitingfordigits', nlabel => 'channels.waiting_for_digits.count', display_ok => 0, set => {
                key_values => [ { name => 'waitingfordigits' } ],
                output_template => 'waiting for digits: %s',
                perfdatas => [
                    { template => '%s',
                      min => 0 }
                ]
            }
        },
        { label => 'channels-remotesetup', nlabel => 'channels.remote_setup.count', display_ok => 0, set => {
                key_values => [ { name => 'remotesetup' } ],
                output_template => 'remote setup: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'channels-peersetup', nlabel => 'channels.peer_setup.count', display_ok => 0, set => {
                key_values => [ { name => 'peersetup' } ],
                output_template => 'peer setup: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'channels-alerting', nlabel => 'channels.alerting.count', display_ok => 0, set => {
                key_values => [ { name => 'alerting' } ],
                output_template => 'alerting: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'channels-inbandinfo', nlabel => 'channels.inband_info.count', display_ok => 0, set => {
                key_values => [ { name => 'inbandinfo' } ],
                output_template => 'inband info: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'channels-connected', nlabel => 'channels.connected.count', display_ok => 0, set => {
                key_values => [ { name => 'connected' } ],
                output_template => 'connected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'channels-tonegeneration', nlabel => 'channels.tone_generation.count', display_ok => 0, set => {
                key_values => [ { name => 'tonegeneration' } ],
                output_template => 'tone generation: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'channels-releasing', nlabel => 'channels.releasing.count', display_ok => 0, set => {
                key_values => [ { name => 'releasing' } ],
                output_template => 'releasing: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'channels-aborting', nlabel => 'channels.aborting.count', display_ok => 0, set => {
                key_values => [ { name => 'aborting' } ],
                output_template => 'aborting: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'channels-resetting', nlabel => 'channels.resetting.count', display_ok => 0, set => {
                key_values => [ { name => 'resetting' } ],
                output_template => 'resetting: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'channels-up', nlabel => 'channels.up.count', display_ok => 0, set => {
                key_values => [ { name => 'up' } ],
                output_template => 'up: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'channels-down', nlabel => 'channels.down.count', display_ok => 0, set => {
                key_values => [ { name => 'down' } ],
                output_template => 'down: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{channels} = [
        { label => 'status', type => 2, critical_default => '%{admstatus} eq "enable" and %{opstatus} !~ /up|idle|connected/', set => {
                key_values => [
                    { name => 'opstatus' }, { name => 'admstatus' },
                    { name => 'shelf' }, { name => 'slot' }, { name => 'port' }, { name => 'channel' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'channel-lifetime', nlabel => 'channel.lifetime.seconds', set => {
                key_values => [ { name => 'seconds' }, { name => 'shelf' }, { name => 'slot' }, { name => 'port' }, { name => 'channel' } ],
                output_template => 'lifetime: %s seconds',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 's',
                        instances => [
                            'shelf' . $self->{result_values}->{shelf},
                            'slot' . $self->{result_values}->{slot},
                            'port' . $self->{result_values}->{port},
                            'channel' . $self->{result_values}->{channel},
                        ],
                        value => $self->{result_values}->{seconds},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-shelf-id:s'   => { name => 'filter_shelf_id' },
        'filter-slot-id:s'    => { name => 'filter_slot_id' },
        'filter-port-id:s'    => { name => 'filter_port_id' },
        'filter-channel-id:s' => { name => 'filter_channel_id' }
    });
    
    return $self;
}

my %map_admin_status = (
    0 => 'down',
    1 => 'up'
);
my %map_operation_status = (
    0 => 'outOfService',
    1 => 'idle',
    2 => 'pending',
    3 => 'waitingForRoute',
    4 => 'actionList',
    5 => 'waitingForDigits',
    6 => 'remoteSetUp',
    7 => 'peerSetUp',
    8 => 'alerting',
    9 => 'inBandInfo',
    10 => 'connected',
    11 => 'toneGeneration',
    12 => 'releasing',
    13 => 'aborting',
    14 => 'resetting',
    15 => 'up',
    16 => 'down'
);

my $mapping = {
    uxChAdminState   => { oid => '.1.3.6.1.4.1.177.15.1.5.6.1.5', map => \%map_admin_status },
    uxChOperState    => { oid => '.1.3.6.1.4.1.177.15.1.5.6.1.6', map => \%map_operation_status },
    uxChInUseSeconds => { oid => '.1.3.6.1.4.1.177.15.1.5.6.1.7' }
};
my $oid_uxChannelStatusEntry = '.1.3.6.1.4.1.177.15.1.5.6.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        total => 0, outofservice => 0, idle => 0,
        pending => 0, waitingforroute => 0, actionlist => 0,
        waitingfordigits => 0, remotesetup => 0, peersetup => 0,
        alerting => 0, inbandinfo => 0, connected => 0, tonegeneration => 0,
        releasing => 0, aborting => 0, resetting => 0, up => 0, down => 0
    };

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_uxChannelStatusEntry,
        nothing_quit => 1
    );

    $self->{channels} = {};
    foreach my $oid (keys %$snmp_result) {
        next if($oid !~ /^$mapping->{uxChOperState}->{oid}\.(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
        my ($shelf, $slot, $port, $channel) = ($1, $2, $3, $4);

        next if (defined($self->{option_results}->{filter_shelf_id}) && $self->{option_results}->{filter_shelf_id} ne '' &&
            $shelf !~ /$self->{option_results}->{filter_shelf_id}/);
        next if (defined($self->{option_results}->{filter_slot_id}) && $self->{option_results}->{filter_slot_id} ne '' &&
            $slot !~ /$self->{option_results}->{filter_slot_id}/);
        next if (defined($self->{option_results}->{filter_port_id}) && $self->{option_results}->{filter_port_id} ne '' &&
            $port !~ /$self->{option_results}->{filter_port_id}/);
        next if (defined($self->{option_results}->{filter_channel_id}) && $self->{option_results}->{filter_channel_id} ne '' &&
            $channel !~ /$self->{option_results}->{filter_channel_id}/);

        my $instance = $shelf . '.' . $slot . '.' . $port . '.' . $channel;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
 
        $self->{global}->{total}++;
        my $oper_state = lc($result->{uxChOperState});

        $self->{global}->{$oper_state}++;
        $self->{channels}->{$instance} = {
            shelf => $shelf,
            slot => $slot,
            port => $port,
            channel => $channel,
            opstatus => $result->{uxChOperState},
            admstatus => $result->{uxChAdminState},
            seconds => $result->{uxChInUseSeconds}
        };
    }
}

1;

__END__

=head1 MODE

Check channels.

=over 8

=item B<--filter-counters>

Only display some counters.

=item B<--filter-shelf-id>

Filter channels by shelf ID (can be a regexp).

=item B<--filter-slot-id>

Filter channels by slot ID (can be a regexp).

=item B<--filter-port-id>

Filter channels by port ID (can be a regexp).

=item B<--filter-channel-id>

Filter channels by channel ID (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{admstatus}, %{opstatus}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{admstatus}, %{opstatus}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'channels-total', 'channels-outofservice', 'channels-idle', 'channels-pending', 
'channels-waitingforroute', 'channels-actionlist', 'channels-waitingfordigits',
'channels-remotesetup', 'channels-peersetup', 'channels-alerting',
'channels-inbandinfo', 'channels-connected', 'channels-tonegeneration', 'channels-releasing',
'channels-aborting', 'channels-resetting', 'channels-up', 'channels-down', 'channel-lifetime'.

=back

=cut
