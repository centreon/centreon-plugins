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

package hardware::ups::standard::rfc1628::snmp::mode::outputlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'oline', type => 1, cb_prefix_output => 'prefix_oline_output', message_multiple => 'All output lines are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'stdev-3phases', nlabel => 'output.3phases.stdev.gauge', set => {
                key_values => [ { name => 'stdev' } ],
                output_template => 'Load standard deviation: %.2f',
                perfdatas => [
                    { label => 'stdev', template => '%.2f' }
                ]
            }
        },
        { label => 'frequence', nlabel => 'lines.output.frequence.hertz', set => {
                key_values => [ { name => 'frequency' } ],
                output_template => 'frequence: %.2f Hz',
                perfdatas => [
                    { template => '%.2f', unit => 'Hz' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{oline} = [
        { label => 'load', nlabel => 'line.output.load.percentage', set => {
                key_values => [ { name => 'outputPercentLoad' } ],
                output_template => 'load: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'current', nlabel => 'line.output.current.ampere', set => {
                key_values => [ { name => 'outputCurrent' } ],
                output_template => 'current: %.2f A',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'A', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'voltage', nlabel => 'line.output.voltage.volt', set => {
                key_values => [ { name => 'outputVoltage' } ],
                output_template => 'voltage: %.2f V',
                perfdatas => [
                    { template => '%.2f', unit => 'V', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'power', nlabel => 'line.output.power.watt', set => {
                key_values => [ { name => 'outputPower' } ],
                output_template => 'power: %.2f W',
                perfdatas => [
                    { template => '%.2f', unit => 'W', label_extra_instance => 1 }
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
        'ignore-zero-counters' => { name => 'ignore_zero_counters' }
    });

    return $self;
}

sub prefix_oline_output {
    my ($self, %options) = @_;

    return "Output line '" . $options{instance_value}->{display} . "' ";
}

sub stdev {
    my ($self, %options) = @_;
    
    # Calculate stdev
    my $total = 0;
    my $num_present = scalar(keys %{$self->{oline}});
    foreach my $instance (keys %{$self->{oline}}) {
        next if (!defined($self->{oline}->{$instance}->{outputPercentLoad}));
        $total += $self->{oline}->{$instance}->{outputPercentLoad};
    }
    
    my $mean = $total / $num_present;
    $total = 0;
    foreach my $instance (keys %{$self->{oline}}) {
        next if (!defined($self->{oline}->{$instance}->{outputPercentLoad}));
        $total += ($mean - $self->{oline}->{$instance}->{outputPercentLoad}) ** 2; 
    }
    my $stdev = sqrt($total / $num_present);
    $self->{global}->{stdev} = $stdev;
}

my $mapping = {
    outputVoltage     => { oid => '.1.3.6.1.2.1.33.1.4.4.1.2' }, # in Volt 
    outputCurrent     => { oid => '.1.3.6.1.2.1.33.1.4.4.1.3' }, # in dA 
    outputPower       => { oid => '.1.3.6.1.2.1.33.1.4.4.1.4' }, # in Watt 
    outputPercentLoad => { oid => '.1.3.6.1.2.1.33.1.4.4.1.5' }
};
my $oid_outputFrequency = '.1.3.6.1.2.1.33.1.4.2.0'; # upsOutputFrequency
my $oid_outputEntry = '.1.3.6.1.2.1.33.1.4.4.1';
my $oid_output = '.1.3.6.1.2.1.33.1.4'; # upsOutput

sub manage_selection {
    my ($self, %options) = @_;

    $self->{oline} = {};
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_output,
        nothing_quit => 1
    );

    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$oid_outputEntry\.\d+\.(.*)$/);
        my $instance = $1;
        next if (defined($self->{oline}->{$instance}));

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if (defined($self->{option_results}->{ignore_zero_counters})) {
            foreach (keys %$result) {
                delete $result->{$_} if ($result->{$_} == 0);
            }
        }
        $result->{outputCurrent} *= 0.1 if (defined($result->{outputCurrent}));

        if (scalar(keys %$result) > 0) {
            $self->{oline}->{$instance} = { display => $instance, %$result };
        }
    }

    $self->{global} = {};
    $self->{global}->{frequency} = $snmp_result->{$oid_outputFrequency} * 0.1 if (defined($snmp_result->{$oid_outputFrequency}));
    if (scalar(keys %{$self->{oline}}) > 1) {
        $self->stdev();
    }
}

1;

__END__

=head1 MODE

Check Output lines metrics (load, voltage, current and true power).

=over 8

=item B<--ignore-zero-counters>

Ignore counters equals to 0.

=item B<--warning-*> B<--critical-*>

Threshold.
Can be: 'frequency', 'load', 'voltage', 'current', 'power'.

=item B<--warning-stdev-3phases>

Warning threshold for standard deviation of 3 phases.

=item B<--critical-stdev-3phases>

Critical threshold for standard deviation of 3 phases.

=back

=cut
