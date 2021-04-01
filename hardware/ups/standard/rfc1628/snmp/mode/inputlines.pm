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

package hardware::ups::standard::rfc1628::snmp::mode::inputlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'line', type => 1, cb_prefix_output => 'prefix_line_output', message_multiple => 'All input lines are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{line} = [
        { label => 'frequence', set => {
                key_values => [ { name => 'upsInputFrequency' }, { name => 'display' } ],
                output_template => 'Frequence : %.2f Hz',
                perfdatas => [
                    { label => 'frequence', value => 'upsInputFrequency', template => '%s', 
                      unit => 'Hz', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'voltage', set => {
                key_values => [ { name => 'upsInputVoltage' }, { name => 'display' } ],
                output_template => 'Voltage : %.2f V',
                perfdatas => [
                    { label => 'voltage', value => 'upsInputVoltage', template => '%s', 
                      unit => 'V', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'current', set => {
                key_values => [ { name => 'upsInputCurrent' }, { name => 'display' } ],
                output_template => 'Current : %.2f A',
                perfdatas => [
                    { label => 'current', value => 'upsInputCurrent', template => '%s', 
                      unit => 'A', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'power', set => {
                key_values => [ { name => 'upsInputTruePower' }, { name => 'display' } ],
                output_template => 'Power : %.2f W',
                perfdatas => [
                    { label => 'power', value => 'upsInputTruePower', template => '%s', 
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

my $oids = {
    '.1.3.6.1.2.1.33.1.3.3.1.2' => { name => 'upsInputFrequency', factor => 0.1 }, # in dH
    '.1.3.6.1.2.1.33.1.3.3.1.3' => { name => 'upsInputVoltage', factor => 1 }, # in Volt
    '.1.3.6.1.2.1.33.1.3.3.1.4' => { name => 'upsInputCurrent', factor => 0.1 }, # in dA
    '.1.3.6.1.2.1.33.1.3.3.1.5' => { name => 'upsInputTruePower', factor => 1 }, # in Watt
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_upsInputEntry = '.1.3.6.1.2.1.33.1.3.3.1';
    my $results = $options{snmp}->get_table(oid => $oid_upsInputEntry, nothing_quit => 1);
    
    $self->{line} = {};
    foreach my $oid (keys %{$results}) {
        next if ($oid !~ /^(.*)\.(.*?)\.(.*?)$/);
        my ($base, $instance) = ($1 . '.' . $2, $3);
        next if (!defined($oids->{$base}));
        next if ($results->{$oid} !~ /\d/ || $results->{$oid} == 0);
        
        $self->{line}->{$instance} = { display => $instance } if (!defined($self->{line}->{$instance}));
        $self->{line}->{$instance}->{$oids->{$base}->{name}} = $results->{$oid} * $oids->{$base}->{factor};
    }
}

1;

__END__

=head1 MODE

Check Input lines metrics (frequence, voltage, current and true power).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^power$'

=item B<--warning-*>

Threshold warning.
Can be: 'frequence', 'voltage', 'current', 'power'.

=item B<--critical-*>

Threshold critical.
Can be: 'frequence', 'voltage', 'current', 'power'.

=back

=cut
