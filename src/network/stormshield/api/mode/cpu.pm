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

package network::stormshield::api::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_cpu_core_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu_avg', type => 0 },
        { name => 'cpu_core', type => 1, cb_prefix_output => 'prefix_cpu_core_output' }
    ];

    $self->{maps_counters}->{cpu_avg} = [
        { label => 'average', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'average' } ],
                output_template => 'CPU(s) average usage is: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cpu_core} = [
        { label => 'core', nlabel => 'core.cpu.utilization.percentage', set => {
                key_values => [ { name => 'used' } ],
                output_template => 'usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
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
        'filter-core:s' => { name => 'filter_core' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $system = $options{custom}->request(command => 'monitor system');

    my $cpu = 0;

    $self->{cpu_core} = {};
    foreach my $label (%{$system->{STAT_Result}}) {
        next if ($label !~ /CPU(\d+)/);
        my $num = $1;

        next if (defined($self->{option_results}->{filter_core}) && $self->{option_results}->{filter_core} ne '' &&
            $num !~ /$self->{option_results}->{filter_core}/);
        my @values = split(/,/, $system->{STAT_Result}->{$label});
        my $used = $values[0] + $values[1] + $values[2];
        $self->{cpu_core}->{$num} = { used => $used };
        $cpu += $used;
    }

    my $num_core = scalar(keys %{$self->{cpu_core}});
    $self->{cpu_avg} = {
        average => $num_core > 0 ? $cpu / $num_core : ''
    };
}

1;

__END__

=head1 MODE

Check cpu usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'core', 'average'.

=item B<--filter-core>

Core cpu to monitor (can be a regexp).

=back

=cut
