#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package network::riverbed::steelhead::snmp::mode::loadaverage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'load', type => 0, cb_prefix_output => 'prefix_load_output' },
    ];

    $self->{maps_counters}->{load} = [
        { label => 'average', set => {
                key_values => [ { name => 'cpuUtil1' } ],
                output_template => 'average: %d%%',
                perfdatas => [
                    { label => 'total_cpu_avg', value => 'cpuUtil1_absolute', template => '%d',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => '1min', set => {
                key_values => [ { name => 'cpuLoad1' } ],
                output_template => '1 min: %d%%',
                perfdatas => [
                    { label => 'load1', value => 'cpuLoad1_absolute', template => '%d',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => '5min', set => {
                key_values => [ { name => 'cpuLoad5' } ],
                output_template => '5 min: %d%%',
                perfdatas => [
                    { label => 'load5', value => 'cpuLoad5_absolute', template => '%d',
                       min => 0, max => 100, unit => "%" },
                ],
            }
        },
        { label => '15min', set => {
                key_values => [ { name => 'cpuLoad15' } ],
                output_template => '15 min: %d%%',
                perfdatas => [
                    { label => 'load15', value => 'cpuLoad15_absolute', template => '%d',
                       min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
}

sub prefix_load_output {
    my ($self, %options) = @_;

    return "Load ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $options{options}->add_options(arguments =>
                                {
                                });
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # STEELHEAD-MIB
    my $oids = {
        cpuUtil1  => '.1.3.6.1.4.1.17163.1.1.5.1.1.0',
        cpuLoad1  => '.1.3.6.1.4.1.17163.1.1.5.1.2.0',
        cpuLoad5  => '.1.3.6.1.4.1.17163.1.1.5.1.3.0',
        cpuLoad15 => '.1.3.6.1.4.1.17163.1.1.5.1.4.0',
    };

    # STEELHEAD-EX-MIB
    my $oids_ex = {
        cpuUtil1  => '.1.3.6.1.4.1.17163.1.51.5.1.1.0',
        cpuLoad1  => '.1.3.6.1.4.1.17163.1.51.5.1.2.0',
        cpuLoad5  => '.1.3.6.1.4.1.17163.1.51.5.1.3.0',
        cpuLoad15 => '.1.3.6.1.4.1.17163.1.51.5.1.4.0',
    };

    my $snmp_result = $options{snmp}->get_leef(oids => [ values %{$oids}, values %{$oids_ex} ], nothing_quit => 1);

    $self->{load} = {};
    
    if (defined($snmp_result->{$oids->{cpuUtil1}})) {
        foreach (keys %{$oids}) {
            $self->{load}->{$_} = $snmp_result->{$oids->{$_}};
        }
    } else {
        foreach (keys %{$oids}) {
            $self->{load}->{$_} = $snmp_result->{$oids_ex->{$_}};
        }
    }
}

1;

__END__

=head1 MODE

Check system load-average.

=over 8

=item B<--warning-*>

Warning thresholds
Can be --warning-(average|1m|5m|15m) 

=item B<--critical-*>

Critical thresholds
Can be --critical-(average|1m|5m|15m)

=back

=cut
