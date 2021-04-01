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

package centreon::common::riverbed::steelhead::snmp::mode::loadaverage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'average', nlabel => 'cpu.usage.percentage', set => {
                key_values => [ { name => 'cpuUtil1' } ],
                output_template => 'CPU Average: %.2f%%',
                perfdatas => [
                    { label => 'total_cpu_avg', template => '%.2f',
                      min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => '1min', nlabel => 'cpu.1m.usage.percentage', set => {
                key_values => [ { name => 'cpuLoad1' } ],
                output_template => 'Load 1 min: %.2f',
                perfdatas => [
                    { label => 'load1', template => '%.2f', min => 0 }
                ]
            }
        },
        { label => '5min', nlabel => 'cpu.5m.usage.percentage', set => {
                key_values => [ { name => 'cpuLoad5' } ],
                output_template => 'Load 5 min: %.2f',
                perfdatas => [
                    { label => 'load5', template => '%.2f', min => 0 }
                ]
            }
        },
        { label => '15min', nlabel => 'cpu.15m.usage.percentage', set => {
                key_values => [ { name => 'cpuLoad15' } ],
                output_template => 'Load 15 min: %.2f',
                perfdatas => [
                    { label => 'load15', template => '%.2f', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>{
    });
    return $self;
}

my $mappings = {
    common    => {
        cpuLoad1 => { oid => '.1.3.6.1.4.1.17163.1.1.5.1.1' },
        cpuLoad5 => { oid => '.1.3.6.1.4.1.17163.1.1.5.1.2' },
        cpuLoad15 => { oid => '.1.3.6.1.4.1.17163.1.1.5.1.3' },
        cpuUtil1 => { oid => '.1.3.6.1.4.1.17163.1.1.5.1.4' }
    },
    ex => {
        cpuLoad1 => { oid => '.1.3.6.1.4.1.17163.1.51.5.1.1' },
        cpuLoad5 => { oid => '.1.3.6.1.4.1.17163.1.51.5.1.2' },
        cpuLoad15 => { oid => '.1.3.6.1.4.1.17163.1.51.5.1.3' },
        cpuUtil1 => { oid => '.1.3.6.1.4.1.17163.1.51.5.1.4' }
    },
    interceptor => {
        cpuLoad1 => { oid => '.1.3.6.1.4.1.17163.1.3.5.1.1' },
        cpuLoad5 => { oid => '.1.3.6.1.4.1.17163.1.3.5.1.2' },
        cpuLoad15 => { oid => '.1.3.6.1.4.1.17163.1.3.5.1.3' },
        cpuUtil1 => { oid => '.1.3.6.1.4.1.17163.1.3.5.1.4' }
    },
};

my $oids = {
    common => '.1.3.6.1.4.1.17163.1.1.5.1',
    ex => '.1.3.6.1.4.1.17163.1.51.5.1',
    interceptor => '.1.3.6.1.4.1.17163.1.3.5.1'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_multiple_table(
        oids => [ 
            { oid => $oids->{common}, start => $mappings->{common}->{cpuLoad1}->{oid}, end => $mappings->{common}->{cpuUtil1}->{oid} },
            { oid => $oids->{ex}, start => $mappings->{ex}->{cpuLoad1}->{oid}, end => $mappings->{ex}->{cpuUtil1}->{oid} },
            { oid => $oids->{interceptor}, start => $mappings->{interceptor}->{cpuLoad1}->{oid}, end => $mappings->{interceptor}->{cpuUtil1}->{oid} }
        ]
    );

    foreach my $equipment (keys %{$oids}) {
        next if (!%{$results->{$oids->{$equipment}}});

        my $result = $options{snmp}->map_instance(mapping => $mappings->{$equipment}, results => $results->{$oids->{$equipment}}, instance => 0);

        $self->{global} = {
            cpuLoad1 => $result->{cpuLoad1} / 100,
            cpuLoad5 => $result->{cpuLoad5} / 100,
            cpuLoad15 => $result->{cpuLoad15} / 100,
            cpuUtil1 => $result->{cpuUtil1},
        };
    }
}

1;

__END__

=head1 MODE

Check system load average.

=over 8

=item B<--warning-*>

Warning thresholds
Can be --warning-(average|1m|5m|15m) 

=item B<--critical-*>

Critical thresholds
Can be --critical-(average|1m|5m|15m)

=back

=cut
