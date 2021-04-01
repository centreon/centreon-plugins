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

package hardware::ats::eaton::snmp::mode::outputline;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'oline', type => 0, cb_prefix_output => 'prefix_line_output', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{oline} = [
        { label => 'voltage', nlabel => 'line.output.voltage.volt', set => {
                key_values => [ { name => 'voltage' } ],
                output_template => 'Voltage : %.2f V',
                perfdatas => [
                    { value => 'voltage', template => '%s', 
                      unit => 'V' },
                ],
            }
        },
        { label => 'current', nlabel => 'line.current.ampere', set => {
                key_values => [ { name => 'current' } ],
                output_template => 'current : %s A',
                perfdatas => [
                    { template => '%s', value => 'current',
                      unit => 'A', min => 0 },
                ],
            }
        },
    ];
}

sub prefix_line_output {
    my ($self, %options) = @_;
    
    return "Output line ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
   
    return $self;
}

my $oid_atsOutputVoltage = '.1.3.6.1.4.1.534.10.1.3.2.1.0';
my $oid_atsOutputCurrent = '.1.3.6.1.4.1.534.10.1.3.2.2.0';
my $oid_ats2OutputVoltage = '.1.3.6.1.4.1.534.10.2.2.3.1.0';
my $oid_ats2OutputCurrent = '.1.3.6.1.4.1.534.10.2.2.3.2.0';

sub check_ats2 {
    my ($self, %options) = @_;

    return if (!defined($options{result}->{$oid_ats2OutputVoltage}));

    $self->{oline} = {
        voltage => $options{result}->{$oid_ats2OutputVoltage} * 0.1,
        current => $options{result}->{$oid_ats2OutputCurrent} * 0.1
    };
}

sub check_ats {
    my ($self, %options) = @_;

    return if (defined($self->{oline}));

    $self->{oline} = {
        voltage => $options{result}->{$oid_atsOutputVoltage} * 0.1,
        current => $options{result}->{$oid_atsOutputCurrent} * 0.1
    };
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(oids => [
        $oid_atsOutputVoltage, $oid_atsOutputCurrent,
        $oid_ats2OutputVoltage, $oid_ats2OutputCurrent,
    ], nothing_quit => 1);
    $self->check_ats2(result => $snmp_result);
    $self->check_ats(result => $snmp_result);
}

1;

__END__

=head1 MODE

Check output line.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^voltage$'

=item B<--warning-*> B<--critical-*> 

Threshold warning.
Can be: 'voltage', 'current'.

=back

=cut
