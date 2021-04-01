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

package hardware::ats::apc::snmp::mode::inputlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'input', type => 1, cb_prefix_output => 'prefix_line_output', message_multiple => 'All input lines are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{input} = [
        { label => 'voltage', set => {
                key_values => [ { name => 'atsInputVoltage' }, { name => 'display' } ],
                output_template => 'Voltage : %.2f V',
                perfdatas => [
                    { label => 'voltage', value => 'atsInputVoltage', template => '%s', 
                      unit => 'V', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'current', set => {
                key_values => [ { name => 'atsInputCurrent' }, { name => 'display' } ],
                output_template => 'Current : %.2f A',
                perfdatas => [
                    { label => 'current', value => 'atsInputCurrent', template => '%s', 
                      unit => 'A', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'power', set => {
                key_values => [ { name => 'atsInputPower' }, { name => 'display' } ],
                output_template => 'Power : %.2f W',
                perfdatas => [
                    { label => 'power', value => 'atsInputPower', template => '%s', 
                      unit => 'W', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_line_output {
    my ($self, %options) = @_;
    
    return "Input Line '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

my $mapping = {
    atsInputVoltage     => { oid => '.1.3.6.1.4.1.318.1.1.8.5.3.3.1.3' },
    atsInputCurrent     => { oid => '.1.3.6.1.4.1.318.1.1.8.5.3.3.1.6' },
    atsInputPower       => { oid => '.1.3.6.1.4.1.318.1.1.8.5.3.3.1.9' },
};
my $mapping2 = {
    atsInputName        => { oid => '.1.3.6.1.4.1.318.1.1.8.5.3.2.1.6' },
};
my $oid_atsInputPhaseEntry = '.1.3.6.1.4.1.318.1.1.8.5.3.3.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_multiple_table(oids => [ 
                                                                { oid => $oid_atsInputPhaseEntry },
                                                                { oid => $mapping2->{atsInputName}->{oid} },
                                                     ],
                                                     nothing_quit => 1);
    
    $self->{input} = {};
    foreach my $oid (keys %{$results->{$oid_atsInputPhaseEntry}}) {
        next if ($oid !~ /^$mapping->{atsInputVoltage}->{oid}\.(\d+)\.(.*)$/);
        my ($input_index, $phase_index) = ($1, $2);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results->{$oid_atsInputPhaseEntry}, instance => $input_index . '.' . $phase_index);
        my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $results->{$mapping2->{atsInputName}->{oid}}, instance => $input_index);
        
        my $name = defined($result2->{atsInputName}) && $result2->{atsInputName} ne '' ? $result2->{atsInputName} : $input_index;
        $name .= '.' . $phase_index;
        $self->{input}->{$name} = { display => $name };
        foreach (keys %{$mapping}) {
            $result->{$_} = undef if (defined($result->{$_}) && $result->{$_} == -1);
            $self->{input}->{$name}->{$_} = $result->{$_};
        }
    }
}

1;

__END__

=head1 MODE

Check input phase metrics (voltage, current and power).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^power$'

=item B<--warning-*>

Threshold warning.
Can be: 'voltage', 'current', 'power'.

=item B<--critical-*>

Threshold critical.
Can be: 'voltage', 'current', 'power'.

=back

=cut
