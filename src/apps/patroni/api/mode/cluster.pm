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

package apps::patroni::api::mode::cluster;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status is '%s' [role: %s]",
            $self->{result_values}->{state},
            $self->{result_values}->{role}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Members ';
}

sub prefix_member_output {
    my ($self, %options) = @_;

    return "Member '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'global',
            type => 0,
            cb_prefix_output => 'prefix_global_output'
        },
        {
            name => 'members',
            type => 1,
            cb_prefix_output => 'prefix_member_output',
            message_multiple => 'All members are ok'
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
            label => 'running',
            nlabel => 'cluster.members.running.count',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'running' }
                ],
                output_template => 'running: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        {
            label => 'streaming',
            nlabel => 'cluster.members.streaming.count',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'streaming' }
                ],
                output_template => 'streaming: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        {
            label => 'stopped',
            nlabel => 'cluster.members.stopped.count',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'stopped' }
                ],
                output_template => 'stopped: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{members} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{state} !~ /running|streaming/',
            set => {
                key_values => [
                    { name => 'state' },
                    { name => 'role' },
                    { name => 'name' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'lag',
            nlabel => 'member.replication.lag.bytes',
            set => {
                key_values => [
                    { name => 'lag' },
                    { name => 'name' }
                ],
                output_template => 'Lag: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    {
                        template => '%d',
                        unit => 'B',
                        min => 0,
                        label_extra_instance => 1,
                        instance_use => 'name'
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

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        total => 0,
        running => 0,
        streaming => 0,
        stopped => 0
    };
    $self->{members} = {};

    my $result = $options{custom}->get_cluster;

    foreach my $entry (@{$result->{members}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $entry->{name} !~ /$self->{option_results}->{filter_name}/);
        $self->{members}->{$entry->{name}} = {
            %{$entry}
        };
        $self->{members}->{$entry->{name}}->{lag} = 0 if (!defined($self->{members}->{$entry->{name}}->{lag}) || 
            (defined($self->{members}->{$entry->{name}}->{lag} &&
                $self->{members}->{$entry->{name}}->{lag} =~ /unknown/)));

        $self->{global}->{ $entry->{state} }++;
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check member status in a cluster.

=over 8

=item B<--filter-name>

Filter members by name.

=item B<--warning-status>

Set warning threshold for status.
Can use special variables like: %{state}, %{role}, %{name}.

=item B<--critical-status>

Set critical threshold for status (Default: "%{state} !~ /running/").
Can use special variables like: %{state}, %{role}, %{name}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total', 'running', 'streaming', 'stopped', 'lag' (B).

=back

=cut