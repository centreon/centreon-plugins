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

package network::alcatel::isam::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPU usages are ok' }
    ];
    
    $self->{maps_counters}->{cpu} = [
        { label => 'usage', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'usage' }, { name => 'display' }, ],
                output_template => 'Usage : %.2f %%',
                perfdatas => [
                    { label => 'cpu', value => 'usage', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    return "CPU '" . $options{instance_value}->{display} . "' ";
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
    cpuLoadAverage                  => { oid => '.1.3.6.1.4.1.637.61.1.9.29.1.1.4' },
    eqptSlotActualType              => { oid => '.1.3.6.1.4.1.637.61.1.23.3.1.3' },
    eqptBoardInventorySerialNumber  => { oid => '.1.3.6.1.4.1.637.61.1.23.3.1.19' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $mapping->{cpuLoadAverage}->{oid} },
                                                            { oid => $mapping->{eqptSlotActualType}->{oid} },
                                                            { oid => $mapping->{eqptBoardInventorySerialNumber}->{oid} },
                                                          ], return_type => 1, nothing_quit => 1);
    
    $self->{cpu} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{cpuLoadAverage}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        my $name = $result->{eqptBoardInventorySerialNumber} . '_' . $result->{eqptSlotActualType};
        $self->{cpu}->{$instance} = { display => $name, usage => $result->{cpuLoadAverage} };
    }
}

1;

__END__

=head1 MODE

Check CPU usages.

=over 8

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=back

=cut
