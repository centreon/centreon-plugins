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

package network::fortinet::fortigate::restapi::mode::ha;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub member_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking member '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_member_output {
    my ($self, %options) = @_;

    return sprintf(
        "member '%s' ",
        $options{instance_value}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'members', type => 3, cb_prefix_output => 'prefix_member_output', cb_long_output => 'member_long_output', indent_long_output => '    ', message_multiple => 'All members are ok',
            group => [
                { name => 'cpu', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'memory', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'session', type => 0, display_short => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'members-detected', nlabel => 'members.detected.count', set => {
                key_values => [ { name => 'num_members' } ],
                output_template => 'members detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'cpu-utilization', nlabel => 'member.cpu.utilization.percentage', set => {
                key_values => [ { name => 'load' } ],
                output_template => 'cpu load: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'memory-usage', nlabel => 'member.memory.usage.percentage', set => {
                key_values => [ { name => 'used' } ],
                output_template => 'memory used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{session} = [
        { label => 'sessions-active', nlabel => 'member.sessions.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => 'active sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
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

sub manage_selection {
    my ($self, %options) = @_;

    my $members = $options{custom}->request_api(
        endpoint => '/api/v2/monitor/system/ha-statistics/select/'
    );

    $self->{global} = { num_members => 0 };
    $self->{members} = {};
    foreach my $member (@{$members->{results}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $member->{hostname} !~ /$self->{option_results}->{filter_name}/);

        $self->{global}->{num_members}++;
        $self->{members}->{ $member->{hostname} } = {
            name => $member->{hostname},
            cpu => { load => $member->{cpu_usage} },
            memory => { used => $member->{mem_usage} },
            session => { active => $member->{sessions} }
        };
    }
}

1;

__END__

=head1 MODE

Check vdom system.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='memory-usage'

=item B<--filter-name>

Filter members by name.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'members-detected', 'cpu-utilization' (%), 'memory-usage' (%), 'sessions-active'.

=back

=cut
