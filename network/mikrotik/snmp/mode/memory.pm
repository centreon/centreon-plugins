#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package network::mikrotik::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_memory_output' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => '1min', set => {
                key_values => [ { name => '1min' } ],
                output_template => '1 minute average : %.2f %%',
                perfdatas => [
                    { label => 'mem_1min_avg', value => '1min_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        }
    ];
}

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    return "RAM ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $oid_totalMemMikro = '.1.3.6.1.2.1.25.2.3.1.5.65536';
    my $oid_usedMemMikro = '.1.3.6.1.2.1.25.2.3.1.6.65536';
    my $snmp_result = $options{snmp}->get_leef(oids => [
            $oid_totalMemMikro,
            $oid_usedMemMikro
        ], nothing_quit => 1);

    $self->{global} = { '1min' => ($snmp_result->{$oid_usedMemMikro}/$snmp_result->{$oid_totalMemMikro})*100};
}

1;

__END__

=head1 MODE

Check memory usages.

=over 8

=item B<--warning-1min>

Threshold warning.

=item B<--critical-1min>

Threshold critical.

=back

=cut
