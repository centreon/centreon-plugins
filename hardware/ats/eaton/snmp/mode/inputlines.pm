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

package hardware::ats::eaton::snmp::mode::inputlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'line', type => 1, cb_prefix_output => 'prefix_line_output', message_multiple => 'All input lines are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{line} = [
        { label => 'voltage', nlabel => 'line.input.voltage.volt', set => {
                key_values => [ { name => 'voltage' }, { name => 'display' } ],
                output_template => 'Voltage : %.2f V',
                perfdatas => [
                    { value => 'voltage', template => '%s', 
                      unit => 'V', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'frequence', nlabel => 'line.input.frequence.hertz', set => {
                key_values => [ { name => 'frequency', no_value => -1 } ],
                output_template => 'Frequence : %.2f Hz',
                perfdatas => [
                    { value => 'frequency', template => '%.2f',
                      unit => 'Hz', label_extra_instance => 1 },
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
    });
    
    return $self;
}

my $map_input_name = {
    1 => 'source-1',
    2 => 'source-2',
};

sub check_ats {
    my ($self, %options) = @_;

    return if (scalar(keys %{$self->{line}}) > 0);

    my $mapping = {
        atsInputIndex       => { oid => '.1.3.6.1.4.1.534.10.1.3.1.1.1', map => $map_input_name },
        atsInputVoltage     => { oid => '.1.3.6.1.4.1.534.10.1.3.1.1.2' },
        atsInputFrequency   => { oid => '.1.3.6.1.4.1.534.10.1.3.1.1.3' }, 
    };

    my $oid_atsInputEntry = '.1.3.6.1.4.1.534.10.1.3.1.1';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_atsInputEntry, nothing_quit => 1);

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{atsInputIndex}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $self->{line}->{$result->{atsInputIndex}} = {
            display => $result->{atsInputIndex},
            voltage => $result->{atsInputVoltage} * 0.1,
            frequency => $result->{atsInputFrequency} * 0.1,
        };
    }
}

sub check_ats2 {
    my ($self, %options) = @_;

    my $mapping = {
        ats2InputIndex      => { oid => '.1.3.6.1.4.1.534.10.2.2.2.1.1', map => $map_input_name },
        ats2InputVoltage    => { oid => '.1.3.6.1.4.1.534.10.2.2.2.1.2' },
        ats2InputFrequency  => { oid => '.1.3.6.1.4.1.534.10.2.2.2.1.3' }, 
    };

    my $oid_ats2InputEntry = '.1.3.6.1.4.1.534.10.2.2.2.1';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_ats2InputEntry);

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{ats2InputIndex}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $self->{line}->{$result->{ats2InputIndex}} = {
            display => $result->{ats2InputIndex},
            voltage => $result->{ats2InputVoltage} * 0.1,
            frequency => $result->{ats2InputFrequency} * 0.1,
        };
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{line} = {};

    $self->check_ats2(%options);
    $self->check_ats(%options);

    if (scalar(keys %{$self->{line}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No line found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check input lines.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^voltage$'

=item B<--warning-*> B<--critical-*>

Threshold warning.
Can be: 'voltage', 'frequence'.

=back

=cut
