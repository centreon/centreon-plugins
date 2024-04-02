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

package apps::etcd::api::mode::statistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "Node state is '%s' [id: %s]",
            $self->{result_values}->{state},
            $self->{result_values}->{id}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Members ';
}

sub prefix_member_output {
    my ($self, %options) = @_;

    return "Member '" . $options{instance_value}->{id} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'node',
            type => 0,
            skipped_code => { -10 => 1 }
        },
        {
            name => 'global',
            type => 0,
            cb_prefix_output => 'prefix_global_output',
            skipped_code => { -10 => 1 }
        },
        {
            name => 'members',
            type => 1,
            cb_prefix_output => 'prefix_member_output',
            message_multiple => 'All members are ok'
        }
    ];

    $self->{maps_counters}->{node} = [
        {
            label => 'status',
            type => 2,
            set => {
                key_values => [
                    { name => 'state' },
                    { name => 'id' },
                    { name => 'name' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'requests-sent-bandwidth',
            nlabel => 'requests.sent.bandwidth.bytespersecond',
            set => {
                key_values => [
                    { name => 'sendBandwidthRate' }
                ],
                output_template => 'requests sent bandwidth: %.2f %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%.2f', unit => 'B/s', min => 0 }
                ]
            }
        },
        {
            label => 'requests-sent',
            nlabel => 'requests.sent.persecond',
            set => {
                key_values => [
                    { name => 'sendPkgRate' }
                ],
                output_template => 'requests sent: %.2f/s',
                perfdatas => [
                    { template => '%.2f', unit => 'requests/s', min => 0 }
                ]
            }
        },
        {
            label => 'requests-received-bandwidth',
            nlabel => 'requests.received.bandwidth.bytespersecond',
            set => {
                key_values => [
                    { name => 'recvBandwidthRate' }
                ],
                output_template => 'requests received bandwidth: %.2f %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%.2f', unit => 'B/s', min => 0 }
                ]
            }
        },
        {
            label => 'requests-received',
            nlabel => 'requests.received.persecond',
            set => {
                key_values => [
                    { name => 'recvPkgRate' }
                ],
                output_template => 'requests received: %.2f/s',
                perfdatas => [
                    { template => '%.2f', unit => 'requests/s', min => 0 }
                ]
            }
        }
    ];
        
    $self->{maps_counters}->{global} = [
        {
            label => 'total',
            nlabel => 'cluster.members.total.count',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'total' }
                ],
                output_template => 'total: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        {
            label => 'leader',
            nlabel => 'cluster.members.leader.count',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'leader' }
                ],
                output_template => 'leader: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        {
            label => 'follower',
            nlabel => 'cluster.members.follower.count',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'follower' }
                ],
                output_template => 'follower: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{members} = [
        {
            label => 'latency',
            nlabel => 'member.latency.milliseconds',
            set => {
                key_values => [
                    { name => 'latency' },
                    { name => 'id' }
                ],
                output_template => 'Latency: %.3f ms',
                perfdatas => [
                    {
                        template => '%.3f',
                        unit => 'ms',
                        min => 0,
                        label_extra_instance => 1,
                        instance_use => 'id'
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

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $self_result = $options{custom}->get_self_statistics;

    $self->{node} = {
        name => $self_result->{name},
        id => $self_result->{id},
        state => $self_result->{state},
        recvBandwidthRate => defined($self_result->{recvBandwidthRate}) ? $self_result->{recvBandwidthRate} : 0,
        recvPkgRate => defined($self_result->{recvPkgRate}) ? $self_result->{recvPkgRate} : 0,
        sendBandwidthRate => defined($self_result->{sendBandwidthRate}) ? $self_result->{sendBandwidthRate} : 0,
        sendPkgRate => defined($self_result->{sendPkgRate}) ? $self_result->{sendPkgRate} : 0
    };
    
    if (defined($self_result->{state}) && $self_result->{state} =~ /StateLeader/) {
        $self->{global}->{total} = 1;
        $self->{global}->{leader} = 1;
        $self->{global}->{follower} = 0;

        my $leader_result = $options{custom}->get_leader_statistics;

        foreach my $entry (keys %{$leader_result->{followers}}) {
            $self->{members}->{$entry} = {
                id => $entry,
                latency => $leader_result->{followers}->{$entry}->{latency}->{average} * 1000
            };
            $self->{global}->{total}++;
            $self->{global}->{follower}++;
        }
    }
}

1;

__END__

=head1 MODE

Check member status in a cluster.

=over 8

=item B<--warning-status>

Set warning threshold for status.
Can use special variables like: %{state}, %{id}, %{name}.

=item B<--critical-status>

Set critical threshold for status.
Can use special variables like: %{state}, %{id}, %{name}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total', 'leader', 'followe', 'latency' (ms).

=back

=cut