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

package hardware::ups::himoinsa::snmp::mode::frequency;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_measure_output {
    my ($self, %options) = @_;

    return "Measure '" . $options{instance} . "' frequency ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'measures', type => 1, cb_prefix_output => 'prefix_measure_output', message_multiple => 'All frequency measures are ok', skipped_code => { -10 => 1 } }
    ];
        
    $self->{maps_counters}->{measures} = [
        { label => 'mains-frequency', nlabel => 'mains.frequency.hertz', set => {
                key_values => [ { name => 'mainsFreqConm' } ],
                output_template => 'mains: %.2f Hz',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'Hz', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'genset-frequency', nlabel => 'genset.frequency.hertz', set => {
                key_values => [ { name => 'genFreqConm' } ],
                output_template => 'genset: %.2f Hz',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'Hz', label_extra_instance => 1 }
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
    });

    return $self;
}

my $mapping = {
    mainsFreqConm => { oid => '.1.3.6.1.4.1.41809.1.49.1.1' },
    genFreqConm   => { oid => '.1.3.6.1.4.1.41809.1.49.1.8' }
};
my $oid_conmutationmeasuresEntry = '.1.3.6.1.4.1.41809.1.49.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_conmutationmeasuresEntry,
        start => $mapping->{mainsFreqConm}->{oid},
        end => $mapping->{genFreqConm}->{oid},
        nothing_quit => 1
    );

    $self->{measures} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{genFreqConm}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $self->{measures}->{$instance} = $result;
    }
}

1;

__END__

=head1 MODE

Check mains and genset frequency.

=over 8

=item B<--warning-*> B<--critical-*>

Threshold in Hertz.

Where '*' can be: 'mains-frequency', 'genset-frequency' 

=back

=cut
