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

package network::cisco::standard::ssh::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu_avg', type => 0, cb_prefix_output => 'prefix_cpu_avg_output', message_separator => ' ', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{cpu_avg} = [
        { label => 'average-5s', nlabel => 'cpu.utilization.5s.percentage', set => {
                key_values => [ { name => 'average_5s' } ],
                output_template => '%.2f %% (5s)',
                perfdatas => [
                    { label => 'total_cpu_5s_avg', value => 'average_5s', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'average-1m', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'average_1m' } ],
                output_template => '%.2f %% (1m)',
                perfdatas => [
                    { label => 'total_cpu_1m_avg', value => 'average_1m', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'average-5m', nlabel => 'cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'average_5m' } ],
                output_template => '%.2f %% (5m)',
                perfdatas => [
                    { label => 'total_cpu_5m_avg', value => 'average_5m', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
}

sub prefix_cpu_avg_output {
    my ($self, %options) = @_;

    return 'CPU(s) average usage is ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($result) = $options{custom}->execute_command(commands => ['show proc cpu | include CPU utilization']);
    #CPU utilization for five seconds: 17%/1%; one minute: 18%; five minutes: 18%

    $self->{cpu_avg} = {};
    $self->{cpu_avg}->{average_5s} = $1 if ($result =~ /^CPU utilization.*?five\s+seconds\s*:\s*(\d+)%/mi);
    $self->{cpu_avg}->{average_1m} = $1 if ($result =~ /^CPU utilization.*?one\s+minute\s*:\s*(\d+)%/mi);
    $self->{cpu_avg}->{average_5m} = $1 if ($result =~ /^CPU utilization.*?five\s+minutes\s*:\s*(\d+)%/mi);
}

1;

__END__

=head1 MODE

Check cpu usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'average-5s', 'average-1m', 'average-5m'.

=back

=cut
