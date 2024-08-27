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

package apps::mq::ibmmq::restapi::mode::queuemanagers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [channel initiator: %s]',
         $self->{result_values}->{mgr_status},
         $self->{result_values}->{channel_initiator_status}
    );
}

sub prefix_qmgr_output {
    my ($self, %options) = @_;

    return "Queue manager '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'qmgr', type => 1, cb_prefix_output => 'prefix_qmgr_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{qmgr} = [
        { label => 'status', type => 2, critical_default => '%{mgr_status} !~ /running/i', set => {
                key_values => [
                    { name => 'mgr_status' }, { name => 'channel_initiator_status' },
                    { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'connections', nlabel => 'queuemanager.connections.count', set => {
                key_values => [ { name => 'connection_count' } ],
                output_template => 'current number of connections: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
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
        'qmgr-name:s'        => { name => 'qmgr_name' },
        'filter-qmgr-name:s' => { name => 'filter_qmgr_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my @lists = ();
    if (defined($self->{option_results}->{qmgr_name}) && $self->{option_results}->{qmgr_name} ne '') {
        @lists = ($self->{option_results}->{qmgr_name});
    } else {
        my $names = $options{custom}->request_api(
            endpoint => '/qmgr/'
        );
        foreach (@{$names->{qmgr}}) {
            push @lists, $_->{name}; 
        }
    }

    $self->{qmgr} = {};
    foreach my $name (@lists) {
        if (defined($self->{option_results}->{filter_qmgr_name}) && $self->{option_results}->{filter_qmgr_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_qmgr_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        my $infos = $options{custom}->request_api(
            endpoint => '/qmgr/' . $name,
            get_param => ['status=*']
        );

        $self->{qmgr}->{$name} = {
            display => $name,
            channel_initiator_status => lc($infos->{qmgr}->[0]->{status}->{channelInitiatorState}),
            mgr_status => lc($infos->{qmgr}->[0]->{state}),
            connection_count => $infos->{qmgr}->[0]->{status}->{connectionCount}
        };
    }

    if (scalar(keys %{$self->{qmgr}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No queue managers found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check queue managers.

=over 8

=item B<--qmgr-name>

Check exact queue manager (no API listing call).

=item B<--filter-qmgr-name>

Filter queue managers by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{mgr_status}, %{channel_initiator_status}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{mgr_status}, %{channel_initiator_status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{mgr_status} !~ /running/i').
You can use the following variables: %{mgr_status}, %{channel_initiator_status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'connections'.

=back

=cut
