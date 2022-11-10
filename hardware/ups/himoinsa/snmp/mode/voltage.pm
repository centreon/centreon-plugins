#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package hardware::ups::himoinsa::snmp::mode::voltage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;


sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];
        
    $self->{maps_counters}->{global} = [
        { label => 'mains-vl12', nlabel => 'mains.vl12.voltage.volt', set => {
                key_values => [ { name => 'mainsVL12Conm' } ],
                output_template => 'mains-vl12: %s V',
                perfdatas => [
                    { value => 'mainsVL12Conm', template => '%s', unit => 'V' },
                ],
            }
        },
        { label => 'mains-vl23', nlabel => 'mains.vl23.voltage.volt', set => {
                key_values => [ { name => 'mainsVL23Conm' } ],
                output_template => 'mains-vl23: %s V',
                perfdatas => [
                    { value => 'mainsVL23Conm', template => '%s', unit => 'V' },
                ],
            }
        },
        { label => 'mains-vl13', nlabel => 'mains.vl13.voltage.volt', set => {
                key_values => [ { name => 'mainsVL13Conm' } ],
                output_template => 'mains-vl13: %s V',
                perfdatas => [
                    { value => 'mainsVL13Conm', template => '%s', unit => 'V' },
                ],
            }
        },
        { label => 'mains-vl1n', nlabel => 'mains.vl1n.voltage.volt', set => {
                key_values => [ { name => 'mainsVL1NConm' } ],
                output_template => 'mains-vl1n: %s V',
                perfdatas => [
                    { value => 'mainsVL1NConm', template => '%s', unit => 'V' },
                ],
            }
        },
        { label => 'mains-vl2n', nlabel => 'mains.vl2n.voltage.volt', set => {
                key_values => [ { name => 'mainsVL2NConm' } ],
                output_template => 'mains-vl2n: %s V',
                perfdatas => [
                    { value => 'mainsVL2NConm', template => '%s', unit => 'V' },
                ],
            }
        },
        { label => 'mains-vl3n', nlabel => 'mains.vl3n.voltage.volt', set => {
                key_values => [ { name => 'mainsVL3NConm' } ],
                output_template => 'mains-vl3n: %s V',
                perfdatas => [
                    { value => 'mainsVL3NConm', template => '%s', unit => 'V' },
                ],
            }
        },
        { label => 'gen-vl12', nlabel => 'gen.vl12.voltage.volt', set => {
                key_values => [ { name => 'genVL12Conm' } ],
                output_template => 'gen-vl12: %s V',
                perfdatas => [
                    { value => 'genVL12Conm', template => '%s', unit => 'V' },
                ],
            }
        },
        { label => 'gen-vl23', nlabel => 'gen.vl23.voltage.volt', set => {
                key_values => [ { name => 'genVL23Conm' } ],
                output_template => 'gen-vl23: %s V',
                perfdatas => [
                    { value => 'genVL23Conm', template => '%s', unit => 'V' },
                ],
            }
        },
        { label => 'gen-vl13', nlabel => 'gen.vl13.voltage.volt', set => {
                key_values => [ { name => 'genVL13Conm' } ],
                output_template => 'gen-vl13: %s V',
                perfdatas => [
                    { value => 'genVL13Conm', template => '%s', unit => 'V' },
                ],
            }
        },
        { label => 'gen-vl1n', nlabel => 'gen.vl1n.voltage.volt', set => {
                key_values => [ { name => 'genVL1NConm' } ],
                output_template => 'gen-vl1n: %s V',
                perfdatas => [
                    { value => 'genVL1NConm', template => '%s', unit => 'V' },
                ],
            }
        },
        { label => 'gen-vl2n', nlabel => 'gen.vl2n.voltage.volt', set => {
                key_values => [ { name => 'genVL2NConm' } ],
                output_template => 'gen-vl2n: %s V',
                perfdatas => [
                    { value => 'genVL2NConm', template => '%s', unit => 'V' },
                ],
            }
        },
        { label => 'gen-vl3n', nlabel => 'gen.vl3n.voltage.volt', set => {
                key_values => [ { name => 'genVL3NConm' } ],
                output_template => 'gen-vl3n: %s V',
                perfdatas => [
                    { value => 'genVL3NConm', template => '%s', unit => 'V' },
                ],
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

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
}

my $mapping = {
    mainsVL12Conm           => { oid => '.1.3.6.1.4.1.41809.1.49.1.2' },
    mainsVL23Conm           => { oid => '.1.3.6.1.4.1.41809.1.49.1.3' },
    mainsVL13Conm           => { oid => '.1.3.6.1.4.1.41809.1.49.1.4' },
    mainsVL1NConm           => { oid => '.1.3.6.1.4.1.41809.1.49.1.5' },
    mainsVL2NConm           => { oid => '.1.3.6.1.4.1.41809.1.49.1.6' },
    mainsVL3NConm           => { oid => '.1.3.6.1.4.1.41809.1.49.1.7' },
    genVL12Conm             => { oid => '.1.3.6.1.4.1.41809.1.49.1.9' },
    genVL23Conm             => { oid => '.1.3.6.1.4.1.41809.1.49.1.10' },
    genVL13Conm             => { oid => '.1.3.6.1.4.1.41809.1.49.1.11' },
    genVL1NConm             => { oid => '.1.3.6.1.4.1.41809.1.49.1.12' },
    genVL2NConm             => { oid => '.1.3.6.1.4.1.41809.1.49.1.13' },
    genVL3NConm             => { oid => '.1.3.6.1.4.1.41809.1.49.1.14' }
};
my $oid_conmutationmeasuresEntry = '.1.3.6.1.4.1.41809.1.49.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_conmutationmeasuresEntry,
        start => $mapping->{mainsVL12Conm}->{oid},
        end => $mapping->{genVL3NConm}->{oid}
    );

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{mainsVL12Conm}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $self->{global} = { %$result };

        if (scalar(keys %{$self->{global}}) <= 0) {
            $self->{output}->add_option_msg(short_msg => "No entry found.");
            $self->{output}->option_exit();
        }
    }
}

1;

__END__

=head1 MODE

Check voltage level.

=over 8

=item B<--warning-*>

Warning threshold in volts.

Where '*' can be: 'mains-vl12', 'mains-vl23', 'mains-vl13', 'mains-vl1n', 'mains-vl2n', 'mains-vl3n', 
'gen-vl12', 'gen-vl23', 'gen-vl13', 'gen-vl1n', 'gen-vl2n', 'gen-vl3n'

=item B<--critical-*>

Critical threshold in volts.

Where '*' can be: 'mains-vl12', 'mains-vl23', 'mains-vl13', 'mains-vl1n', 'mains-vl2n', 'mains-vl3n', 
'gen-vl12', 'gen-vl23', 'gen-vl13', 'gen-vl1n', 'gen-vl2n', 'gen-vl3n'

=back

=cut
