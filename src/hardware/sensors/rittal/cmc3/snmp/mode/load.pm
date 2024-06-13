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

package hardware::sensors::rittal::cmc3::snmp::mode::load;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_output {
    my ($self, %options) = @_;

    return 'system load ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'unit_load', type => 0, cb_prefix_output => 'prefix_output' }
    ];

    $self->{maps_counters}->{unit_load} = [
        {
            label => 'unit-load-1m', nlabel => 'system.load.1m.percentage',
            set   => {
                key_values      => [ { name => 'load1' } ],
                output_template => '%.2f (1m)',
                perfdatas       => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        {
            label => 'unit-load-5m', nlabel => 'system.load.5m.percentage',
            set   => {
                key_values      => [ { name => 'load5' } ],
                output_template => '%.2f (5m)',
                perfdatas       => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        {
            label => 'unit-load-10m', nlabel => 'system.load.10m.percentage',
            set   => {
                key_values      => [ { name => 'load10' } ],
                output_template => '%.2f (10m)',
                perfdatas       => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

my $mapping = {
    unit_load => { oid => '.1.3.6.1.4.1.2606.7.2.14.1.2' }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_cmcIIIUnitLoadEntry = '.1.3.6.1.4.1.2606.7.2.14.1';
    my $results = $options{snmp}->get_table(
        oid          => $oid_cmcIIIUnitLoadEntry,
        nothing_quit => 1
    );

    $self->{unit_load} = {};
    foreach (keys %$results) {
        next if (!/^$mapping->{unit_load}->{oid}\.(\d+)$/);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $1);
        $self->{unit_load}->{'load' . $1} = $result->{unit_load} / 100;
    }
}

1;

__END__

=head1 MODE

Check unit load

=over 8

=item B<--warning-*> B<--critical-*>

Load threshold in %.

Thresholds: unit-load-1m, unit-load-5m, unit-load-10m

=back

=cut
