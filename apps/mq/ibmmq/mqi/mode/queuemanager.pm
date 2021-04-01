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

package apps::mq::ibmmq::mqi::mode::queuemanager;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [command server: %s] [channel initiator: %s]',
         $self->{result_values}->{mgr_status},
         $self->{result_values}->{command_server_status},
         $self->{result_values}->{channel_initiator_status}
    );
}

sub custom_connections_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => $self->{result_values}->{display},
        value => $self->{result_values}->{connection_count},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub prefix_qmgr_output {
    my ($self, %options) = @_;

    return "Queue manager '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'qmgr', type => 0, cb_prefix_output => 'prefix_qmgr_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{qmgr} = [
        { label => 'status', threshold => 0, set => {
                key_values => [
                    { name => 'mgr_status' }, { name => 'channel_initiator_status' },
                    { name => 'command_server_status' }, { name => 'display' }
                ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'connections', nlabel => 'queuemanager.connections.count', set => {
                key_values => [ { name => 'connection_count' }, { name => 'display' } ],
                output_template => 'current number of connections: %s',
                closure_custom_perfdata => $self->can('custom_connections_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{mgr_status} !~ /running/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->execute_command(
        command => 'InquireQueueManagerStatus',
        attrs => { }
    );

    $self->{qmgr} = {
        display => $options{custom}->get_qmgr_name(),
        channel_initiator_status => lc($result->[0]->{ChannelInitiatorStatus}),
        mgr_status => lc($result->[0]->{QMgrStatus}),
        command_server_status => lc($result->[0]->{CommandServerStatus}),
        connection_count => $result->[0]->{ConnectionCount}
    };
}

1;

__END__

=head1 MODE

Check queue manager.

=over 8

=item B<--unknown-status>

Set unknown threshold for status (Default: '').
Can used special variables like: %{mgr_status}, %{channel_initiator_status}, %{command_server_status}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{mgr_status}, %{channel_initiator_status}, %{command_server_status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{mgr_status} !~ /running/i').
Can used special variables like: %{mgr_status}, %{channel_initiator_status}, %{command_server_status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'connections'.

=back

=cut
