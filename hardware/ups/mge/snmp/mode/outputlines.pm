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

package hardware::ups::mge::snmp::mode::outputlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'oline', type => 1, cb_prefix_output => 'prefix_oline_output', message_multiple => 'All output lines are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'stdev-3phases', nlabel => 'output.3phases.stdev.gauge', set => {
                key_values => [ { name => 'stdev' } ],
                output_template => 'Load Standard Deviation : %.2f',
                perfdatas => [
                    { label => 'stdev', value => 'stdev', template => '%.2f' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{oline} = [
        { label => 'load', nlabel => 'line.output.load.percentage', set => {
                key_values => [ { name => 'mgoutputLoadPerPhase', no_value => 0 } ],
                output_template => 'Load : %.2f %%',
                perfdatas => [
                    { value => 'mgoutputLoadPerPhase', template => '%.2f', 
                      min => 0, max => 100, unit => '%', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'current', nlabel => 'line.output.current.ampere', set => {
                key_values => [ { name => 'mgoutputCurrent', no_value => 0 } ],
                output_template => 'Current : %.2f A',
                perfdatas => [
                    { value => 'mgoutputCurrent', template => '%.2f', 
                      min => 0, unit => 'A', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'voltage', nlabel => 'line.output.voltage.volt', set => {
                key_values => [ { name => 'mgoutputVoltage', no_value => 0 } ],
                output_template => 'Voltage : %.2f V',
                perfdatas => [
                    { value => 'mgoutputVoltage', template => '%.2f', 
                      unit => 'V', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'frequence', nlabel => 'line.output.frequence.hertz', set => {
                key_values => [ { name => 'mgoutputFrequency', no_value => -1 } ],
                output_template => 'Frequence : %.2f Hz',
                perfdatas => [
                    { value => 'mgoutputFrequency', template => '%.2f', 
                      unit => 'Hz', label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub prefix_oline_output {
    my ($self, %options) = @_;

    return "Output Line '" . $options{instance_value}->{display} . "' ";
}

sub stdev {
    my ($self, %options) = @_;
    
    # Calculate stdev
    my $total = 0;
    my $num_present = scalar(keys %{$self->{oline}});
    foreach my $instance (keys %{$self->{oline}}) {
        next if (!defined($self->{oline}->{$instance}->{mgoutputLoadPerPhase}));
        $total += $self->{oline}->{$instance}->{mgoutputLoadPerPhase};
    }
    
    my $mean = $total / $num_present;
    $total = 0;
    foreach my $instance (keys %{$self->{oline}}) {
        next if (!defined($self->{oline}->{$instance}->{mgoutputLoadPerPhase}));
        $total += ($mean - $self->{oline}->{$instance}->{mgoutputLoadPerPhase}) ** 2; 
    }
    my $stdev = sqrt($total / $num_present);
    $self->{global} = { stdev => $stdev };
}

my $mapping = {
    mgoutputVoltage         => { oid => '.1.3.6.1.4.1.705.1.7.2.1.2' }, # in dV
    mgoutputFrequency       => { oid => '.1.3.6.1.4.1.705.1.7.2.1.3' }, # in dHz
    mgoutputLoadPerPhase    => { oid => '.1.3.6.1.4.1.705.1.7.2.1.4' }, # in %
    mgoutputCurrent         => { oid => '.1.3.6.1.4.1.705.1.7.2.1.5' }, # in dA
};
my $oid_upsmgOutputPhaseEntry = '.1.3.6.1.4.1.705.1.7.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{oline} = {};
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_upsmgOutputPhaseEntry,
        nothing_quit => 1
    );
    foreach my $oid (keys %{$snmp_result}) {
        $oid =~ /^$oid_upsmgOutputPhaseEntry\.\d+\.(.*)$/;
        my $instance = $1;
        next if (defined($self->{oline}->{$instance}));
        
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        $result->{mgoutputVoltage} *= 0.1 if (defined($result->{mgoutputVoltage}));
        $result->{mgoutputFrequency} *= 0.1 if (defined($result->{mgoutputFrequency}));
        $result->{mgoutputCurrent} *= 0.1 if (defined($result->{mgoutputCurrent}));
        $self->{oline}->{$instance} = { display => $instance, %$result };
    }
    
    if (scalar(keys %{$self->{oline}}) > 1) {
        $self->stdev();
    }
}

1;

__END__

=head1 MODE

Check Output lines metrics (load, voltage, current).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'load', 'voltage', 'current', 'frequence', 'stdev-3phases'.

=item B<--critical-*>

Threshold critical.
Can be: 'load', 'voltage', 'current', 'frequence', 'stdev-3phases'.

=back

=cut
