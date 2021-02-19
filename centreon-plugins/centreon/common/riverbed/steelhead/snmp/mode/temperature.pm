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

package centreon::common::riverbed::steelhead::snmp::mode::temperature;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'temperature', set => {
                key_values => [ { name => 'systemTemperature' } ],
                output_template => 'Temperature: %.2f C',
                perfdatas => [
                    { label => 'temperature', template => '%.2f', min => 0, unit => 'C' }
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
        systemTemperature => { oid => '.1.3.6.1.4.1.17163.1.1.2.9' },
    },
    ex => {
        systemTemperature => { oid => '.1.3.6.1.4.1.17163.1.51.2.9' },
    }
};

my $oids = {
    common => '.1.3.6.1.4.1.17163.1.1.2.9',
    ex => '.1.3.6.1.4.1.17163.1.51.2.9'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oids->{common}, start => $mappings->{common}->{systemTemperature}->{oid}, end => $mappings->{common}->{systemTemperature}->{oid} },
            { oid => $oids->{ex}, start => $mappings->{ex}->{systemTemperature}->{oid}, end => $mappings->{ex}->{systemTemperature}->{oid} }
        ]
    );

    foreach my $equipment (keys %{$oids}) {
        next if (!%{$results->{$oids->{$equipment}}});

        my $result = $options{snmp}->map_instance(mapping => $mappings->{$equipment},
            results => $results->{$oids->{$equipment}}, instance => 0);

        $self->{global} = {
            systemTemperature => $result->{systemTemperature},
        };
    }
}

1;

__END__

=head1 MODE

Check the temperature of the system in Celcius (STEELHEAD-MIB and STEELHEAD-EX-MIB).

=over 8

=item B<--warning-temperature>

Threshold warning for temperature in Celsius.

=item B<--critical-temperature>

Threshold critical for temperature in Celsius.

=back

=cut
