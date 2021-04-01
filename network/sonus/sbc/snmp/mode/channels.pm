#
# Copyright 2021 Centreon (http://www.centreon.com/)
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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg;
    
    if ($self->{result_values}->{admstatus} eq 'disabled') {
        $msg = ' is disabled (admin)';
    } else {
        $msg = 'Oper Status : ' . $self->{result_values}->{opstatus};
    }

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{opstatus} = $options{new_datas}->{$self->{instance} . '_opstatus'};
    $self->{result_values}->{admstatus} = $options{new_datas}->{$self->{instance} . '_admstatus'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'channels', type => 1, cb_prefix_output => 'prefix_channels_output', message_multiple => 'All channels are ok' }
    ];
    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total channels : %s',
                perfdatas => [
                    { label => 'total', value => 'total', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-outofservice', set => {
                key_values => [ { name => 'outofservice' } ],
                output_template => 'OutOfService : %s',
                perfdatas => [
                    { label => 'total_outofservice', value => 'outofservice', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-idle', set => {
                key_values => [ { name => 'idle' } ],
                output_template => 'Idle : %s',
                perfdatas => [
                    { label => 'total_idle', value => 'idle', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-pending', set => {
                key_values => [ { name => 'pending' } ],
                output_template => 'Pending : %s',
                perfdatas => [
                    { label => 'total_pending', value => 'pending', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-waitingforroute', set => {
                key_values => [ { name => 'waitingforroute' } ],
                output_template => 'WaitingForRoute : %s',
                perfdatas => [
                    { label => 'total_waitingforroute', value => 'waitingforroute', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-actionlist', set => {
                key_values => [ { name => 'actionlist' } ],
                output_template => 'ActionList : %s',
                perfdatas => [
                    { label => 'total_actionlist', value => 'actionlist', template => '%s',
                      min => 0 },
                ],
            }
        },		
        { label => 'total-waitingfordigits', set => {
                key_values => [ { name => 'waitingfordigits' } ],
                output_template => 'WaitingForDigits : %s',
                perfdatas => [
                    { label => 'total_waitingfordigits', value => 'waitingfordigits', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-remotesetup', set => {
                key_values => [ { name => 'remotesetup' } ],
                output_template => 'RemoteSetup : %s',
                perfdatas => [
                    { label => 'total_remotesetup', value => 'remotesetup', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-peersetup', set => {
                key_values => [ { name => 'peersetup' } ],
                output_template => 'PeerSetup : %s',
                perfdatas => [
                    { label => 'total_peersetup', value => 'peersetup', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-alerting', set => {
                key_values => [ { name => 'alerting' } ],
                output_template => 'Alerting : %s',
                perfdatas => [
                    { label => 'total_alerting', value => 'alerting', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-inbandinfo', set => {
                key_values => [ { name => 'inbandinfo' } ],
                output_template => 'InBandInfo : %s',
                perfdatas => [
                    { label => 'total_inbandinfo', value => 'inbandinfo', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-connected', set => {
                key_values => [ { name => 'connected' } ],
                output_template => 'Connected : %s',
                perfdatas => [
                    { label => 'total_connected', value => 'connected', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-tonegeneration', set => {
                key_values => [ { name => 'tonegeneration' } ],
                output_template => 'ToneGeneration : %s',
                perfdatas => [
                    { label => 'total_tonegeneration', value => 'tonegeneration', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-releasing', set => {
                key_values => [ { name => 'releasing' } ],
                output_template => 'Releasing : %s',
                perfdatas => [
                    { label => 'total_releasing', value => 'releasing', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-aborting', set => {
                key_values => [ { name => 'aborting' } ],
                output_template => 'Aborting : %s',
                perfdatas => [
                    { label => 'total_aborting', value => 'aborting', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-resetting', set => {
                key_values => [ { name => 'resetting' } ],
                output_template => 'Resetting : %s',
                perfdatas => [
                    { label => 'total_resetting', value => 'resetting', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-up', set => {
                key_values => [ { name => 'up' } ],
                output_template => 'Up : %s',
                perfdatas => [
                    { label => 'total_up', value => 'up', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-down', set => {
                key_values => [ { name => 'down' } ],
                output_template => 'Down : %s',
                perfdatas => [
                    { label => 'total_down', value => 'down', template => '%s',
                      min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{channels} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'opstatus' }, { name => 'admstatus' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'seconds', set => {
                key_values => [ { name => 'seconds' }, { name => 'display' } ],
                output_template => 'lifetime : %s seconds',
                perfdatas => [
                    { label => 'seconds', value => 'seconds', template => '%s',
                      min => 0, unit => 's', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "warning-status:s"        => { name => 'warning_status', default => '' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{admstatus} eq "enable" and %{opstatus} !~ /up|idle|connected/' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_channels_output {
    my ($self, %options) = @_;
    
    return "Channels '" . $options{instance_value}->{display} . "' ";
}

my %map_admin_status = (
    0 => 'down',
    1 => 'up',
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
    16 => 'down',
);

my $mapping = {
    uxChAdminState => { oid => '.1.3.6.1.4.1.177.15.1.5.6.1.5', map => \%map_admin_status },
    uxChOperState => { oid => '.1.3.6.1.4.1.177.15.1.5.6.1.6', map => \%map_operation_status },
    uxChInUseSeconds => { oid => '.1.3.6.1.4.1.177.15.1.5.6.1.7' },
};

my $oid_uxChannelStatusEntry = '.1.3.6.1.4.1.177.15.1.5.6.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{channels} = {};
    $self->{global} = { total => 0, outofservice => 0, idle => 0,
                        pending => 0, waitingforroute => 0, actionlist => 0,
                        waitingfordigits => 0, remotesetup => 0, peersetup => 0,
                        alerting => 0, inbandinfo => 0, connected => 0, tonegeneration => 0,
                        releasing => 0, aborting => 0, resetting => 0, up => 0, down => 0 };

    $self->{results} = $options{snmp}->get_table(oid => $oid_uxChannelStatusEntry,
                                                 nothing_quit => 1);

    foreach my $oid (keys %{$self->{results}}) {
        next if($oid !~ /^$mapping->{uxChOperState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);
 
        $self->{global}->{total}++;
        my $oper_state = lc($result->{uxChOperState});

        $self->{global}->{$oper_state}++;
        $self->{channels}->{$instance} = {display => $instance,
                                          opstatus => $result->{uxChOperState},
                                          admstatus => $result->{uxChAdminState},
                                          seconds => $result->{uxChInUseSeconds}};
    }
 
}

1;

__END__

=head1 MODE

Check Channels on Sonus

=over 8

=item B<--filter-counters>

Only display some counters (Can be 'channels' or 'global').

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{display}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'total-outofservice', 'total-disassociating', 'total-idle', 'total-pending', 'total-waitingforroute', 'total-actionlist', 'total-waitingfordigits', 'total-remotesetup', 'total-peersetup', 'total-alerting', 'total-inbandinfo', 'total-connected', 'total-tonegeneration', 'total-releasing', 'total-aborting', 'total-resetting', 'total-up', 'total-down', 'seconds'

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'total', 'total-outofservice', 'total-disassociating', 'total-idle', 'total-pending', 'total-waitingforroute', 'total-actionlist', 'total-waitingfordigits', 'total-remotesetup', 'total-peersetup', 'total-alerting', 'total-inbandinfo', 'total-connected', 'total-tonegeneration', 'total-releasing', 'total-aborting', 'total-resetting', 'total-up', 'total-down', 'seconds'

=back

=cut
