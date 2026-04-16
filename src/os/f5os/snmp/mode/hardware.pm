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

package os::f5os::snmp::mode::hardware;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_fan_output {
    my ($self, %options) = @_;
    return "fan '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'temperature', type => 0, skipped_code => { -10 => 1 } },
        { name => 'fans', type => 1, cb_prefix_output => 'prefix_fan_output', message_multiple => 'All fans are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{temperature} = [
        { label => 'current-temperature', nlabel => 'temperature.current.celsius', set => {
                key_values => [ { name => 'tempCurrent' } ],
                output_template => 'Current temperature: %s C',
                perfdatas => [
                    { template => '%.1f', unit => 'C', label_extra_instance => 0 }
                ]
            }
        },
        { label => 'average-temperature', nlabel => 'temperature.average.1h.celsius', set => {
                key_values => [ { name => 'tempAverage' } ],
                output_template => 'average: %s C',
                perfdatas => [
                    { template => '%.1f', unit => 'C', label_extra_instance => 0 }
                ]
            }
        },
        { label => 'min-temperature', nlabel => 'temperature.min.1h.celsius', set => {
                key_values => [ { name => 'tempMinimum' } ],
                output_template => 'minimum: %s C',
                perfdatas => [
                    { template => '%.1f', unit => 'C', label_extra_instance => 0 }
                ]
            }
        },
        { label => 'max-temperature', nlabel => 'temperature.max.1h.celsius', set => {
                key_values => [ { name => 'tempMaximum' } ],
                output_template => 'maximum: %s C',
                perfdatas => [
                    { template => '%.1f', unit => 'C', label_extra_instance => 1 }
                ]
            }
        }


    ];

    $self->{maps_counters}->{fans} = [
        { label => 'fantray-fan-speed', nlabel => 'fantray.fanspeed.rpm', set => {
                key_values => [ { name => 'speed' } ],
                output_template => 'speed is %s rpm',
                perfdatas => [
                    { template => '%s', unit => 'rpm', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

}

my $mapping = {
    tempCurrent                 => { oid => '.1.3.6.1.4.1.12276.1.2.1.3.1.1.2' }, 
    tempAverage                 => { oid => '.1.3.6.1.4.1.12276.1.2.1.3.1.1.3' }, 
    tempMinimum                 => { oid => '.1.3.6.1.4.1.12276.1.2.1.3.1.1.4' }, 
    tempMaximum                 => { oid => '.1.3.6.1.4.1.12276.1.2.1.3.1.1.5' },
};

my $oid_temperatureStatsEntry = '.1.3.6.1.4.1.12276.1.2.1.3.1.1';
my $oid_fantrayStatsEntry = '.1.3.6.1.4.1.12276.1.2.1.7.1.1';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
   
    $options{options}->add_options(arguments => {
        'component:s' => { name => 'component', default => '.*' },
        'no-component:s' => { name => 'no_component', default => 'CRITICAL' },
        'include-id:s' => { name => 'include_id', default => '' },
        'exclude-id:s' => { name => 'exclude_id', default => '' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_temperatureStatsEntry },
            { oid => $oid_fantrayStatsEntry },
        ]);

    if ('temperature' =~ /$self->{option_results}->{component}/) {
        my $result;
        foreach (keys %{$results->{$oid_temperatureStatsEntry}}) {
            next unless /^$mapping->{tempCurrent}->{oid}\.(.*)$/;

            $result = $options{snmp}->map_instance(mapping => $mapping, results => $results->{$oid_temperatureStatsEntry}, instance => $1);
            $result->{$_} *= 0.1 for keys %{$result};

            last
        }

        if ($result) {
            $self->{temperature} = $result;
        } else {
            $self->{output}->output_add(   
                severity => $self->{option_results}->{no_component},
                short_msg => 'Temperature not retrieved.'
            );
        }
    }

    if ('fantray' =~ /$self->{option_results}->{component}/) {
        while (my ($oid, $values) = each %{$results->{$oid_fantrayStatsEntry}}) {
            next unless $oid =~ /^$oid_fantrayStatsEntry\.(\d+)/;
            my $fan_id = $1;

            if ($self->{option_results}->{include_id} && $fan_id !~ /$self->{option_results}->{include_id}/) {
                $self->{output}->output_add(long_msg => "skipping fantray fan '$fan_id': no including filter match.", debug => 1);
                next
            }
            if ($self->{option_results}->{exclude_id} && $fan_id =~ /$self->{option_results}->{exclude_id}/) {
                $self->{output}->output_add(long_msg => "skipping fantray fan '$fan_id': excluding filter match.", debug => 1);
                next
            }

            $self->{fans}->{$fan_id} = { speed => $values };
        }

        unless ($self->{fans}) {
            $self->{output}->output_add(   
                severity => $self->{option_results}->{no_component},
                short_msg => 'Fantray Fan speed not retrieved.'
            );
        }
    }
}

1;

__END__

=head1 MODE

Check hardware.

    - temperature.current.celsius          The current temperature in celsius
    - temperature.average.1h.celsius       The arithmetic mean value of the temperature
    - temperature.min.1h.celsius           The minimum value of the temperature statistic over the past hour
    - temperature.max.1h.celsius           The maximum value of the temperature statistic over the past hour
    - fantray.fanspeed.rpm                 The current fan speed in RPM

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: C<temperature>, C<fantray>.

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Can be : C<fantray-fan-speed> C<current-temperature> C<average-temperature> C<min-temperature> C<max-temperature>
Example : C<--filter-counters='^current-temperature$'>

=item B<--include-id>

Filter by fan id (regexp can be used).
Example : --include-id='2'

=item B<--exclude-id>

Exclude fan id from check (can be a regexp).
Example : --exclude-id='10'

=item B<--warning-current-temperature>

Threshold in C.

=item B<--critical-current-temperature>

Threshold in C.

=item B<--warning-average-temperature>

Threshold in C.

=item B<--critical-average-temperature>

Threshold in C.

=item B<--warning-min-temperature>

Threshold in C.

=item B<--critical-min-temperature>

Threshold in C.

=item B<--warning-max-temperature>

Threshold in C.

=item B<--critical-max-temperature>

Threshold in C.

=item B<--warning-fantray-fan-speed>

Threshold in rpm.

=item B<--critical-fantray-fan-speed>

Threshold in rpm.

=back

=cut
