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

package hardware::ups::powerware::snmp::mode::outputlines;

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
        { label => 'load', nlabel => 'lines.output.load.percentage', set => {
                key_values => [ { name => 'xupsOutputLoad', no_value => -1 } ],
                output_template => 'Load : %.2f %%',
                perfdatas => [
                    { value => 'xupsOutputLoad', template => '%.2f', 
                      min => 0, max => 100 },
                ],
            }
        },
        { label => 'frequence', nlabel => 'lines.output.frequence.hertz', set => {
                key_values => [ { name => 'xupsOutputFrequency', no_value => 0 } ],
                output_template => 'Frequence : %.2f Hz',
                perfdatas => [
                    { value => 'xupsOutputFrequency', template => '%.2f', 
                      unit => 'Hz' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{oline} = [
        { label => 'current', nlabel => 'line.output.current.ampere', set => {
                key_values => [ { name => 'xupsOutputCurrent', no_value => 0 } ],
                output_template => 'Current : %.2f A',
                perfdatas => [
                    { value => 'xupsOutputCurrent', template => '%.2f', 
                      min => 0, unit => 'A', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'voltage', nlabel => 'line.output.voltage.volt', set => {
                key_values => [ { name => 'xupsOutputVoltage', no_value => 0 } ],
                output_template => 'Voltage : %.2f V',
                perfdatas => [
                    { value => 'xupsOutputVoltage', template => '%.2f', 
                      unit => 'V', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'power', nlabel => 'line.output.power.watt', set => {
                key_values => [ { name => 'xupsOutputWatts', no_value => 0 } ],
                output_template => 'Power: %.2f W',
                perfdatas => [
                    { value => 'xupsOutputWatts', template => '%.2f', 
                      unit => 'W', label_extra_instance => 1 },
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

my $mapping = {
    xupsOutputVoltage   => { oid => '.1.3.6.1.4.1.534.1.4.4.1.2' }, # in V
    xupsOutputCurrent   => { oid => '.1.3.6.1.4.1.534.1.4.4.1.3' }, # in A
    xupsOutputWatts     => { oid => '.1.3.6.1.4.1.534.1.4.4.1.4' }, # in W
};
my $mapping2 = {
    xupsOutputLoad      => { oid => '.1.3.6.1.4.1.534.1.4.1' }, # in %
    xupsOutputFrequency => { oid => '.1.3.6.1.4.1.534.1.4.2' }, # in dHZ
};

my $oid_xupsOutput = '.1.3.6.1.4.1.534.1.4';
my $oid_xupsOutputEntry = '.1.3.6.1.4.1.534.1.4.4.1';

sub manage_selection {
    my ($self, %options) = @_;
 
    $self->{oline} = {};
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_xupsOutput,
        nothing_quit => 1
    );
    
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$oid_xupsOutputEntry\.\d+\.(.*)$/);
        my $instance = $1;
        next if (defined($self->{oline}->{$instance}));
        
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        $self->{oline}->{$instance} = { display => $instance, %$result };
    }
    
    if (scalar(keys %{$self->{oline}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No output lines found.");
        $self->{output}->option_exit();
    }

    my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => '0');
    
    $result->{xupsOutputFrequency} = defined($result->{xupsOutputFrequency}) ? ($result->{xupsOutputFrequency} * 0.1) : 0;
    $result->{xupsOutputLoad} = defined($result->{xupsOutputLoad}) ? $result->{xupsOutputLoad} : -1;
    $self->{global} = { %$result };
}

1;

__END__

=head1 MODE

Check Output lines metrics (load, voltage, current and true power) (XUPS-MIB).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'load', 'voltage', 'current', 'power'.
Load is a rate for X phase.

=item B<--critical-*>

Threshold critical.
Can be: 'load', 'voltage', 'current', 'power'.
Load is a rate for X phase.

=back

=cut
