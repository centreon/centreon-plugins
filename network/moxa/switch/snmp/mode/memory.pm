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

package network::moxa::switch::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    
    my $msg = sprintf("Memory Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                      $total_size_value . " " . $total_size_unit,
                      $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                      $total_free_value . " " . $total_free_unit, 100 - $self->{result_values}->{prct_used});
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'memory', type => 0 },
    ];
    
    $self->{maps_counters}->{memory} = [
        { label => 'usage', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'total' }, { name => 'prct_used' }  ],
                closure_custom_output => $self->can('custom_usage_output'),
                threshold_use => 'prct_used',
                perfdatas => [
                    { label => 'used', value => 'used', template => '%.2f',
                      threshold_total => 'total', cast_int => 1,
                      min => 0, max => 'total', unit => 'B' },
                ],
            }
        },
    ];
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

my $mappings = {
    iks6726a    => {
        totalMemory     => { oid => '.1.3.6.1.4.1.8691.7.116.1.56' },
        freeMemory      => { oid => '.1.3.6.1.4.1.8691.7.116.1.57' },
        usedMemory      => { oid => '.1.3.6.1.4.1.8691.7.116.1.58' },
    },
    edsp506e => {
        totalMemory     => { oid => '.1.3.6.1.4.1.8691.7.162.1.56' },
        freeMemory      => { oid => '.1.3.6.1.4.1.8691.7.162.1.57' },
        usedMemory      => { oid => '.1.3.6.1.4.1.8691.7.162.1.58' },
    },
    edsp506a => {
        totalMemory     => { oid => '.1.3.6.1.4.1.8691.7.41.1.56' },
        freeMemory      => { oid => '.1.3.6.1.4.1.8691.7.41.1.57' },
        usedMemory      => { oid => '.1.3.6.1.4.1.8691.7.41.1.58' },
    },
};

my $oids = {
    iks6726a => '.1.3.6.1.4.1.8691.7.116.1',
    edsp506e => '.1.3.6.1.4.1.8691.7.162.1',
    edsp506a => '.1.3.6.1.4.1.8691.7.41.1',
};

sub manage_selection {
    my ($self, %options) = @_;
   
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ { oid => $oids->{iks6726a}, start => $mappings->{iks6726a}->{totalMemory}->{oid}, end => $mappings->{iks6726a}->{usedMemory}->{oid} },
                                                                   { oid => $oids->{edsp506e}, start => $mappings->{edsp506e}->{totalMemory}->{oid}, end => $mappings->{edsp506e}->{usedMemory}->{oid} },
                                                                   { oid => $oids->{edsp506a}, start => $mappings->{edsp506a}->{totalMemory}->{oid}, end => $mappings->{edsp506a}->{usedMemory}->{oid} } ]);

    foreach my $equipment (keys %{$oids}) {
        next if (!%{$snmp_result->{$oids->{$equipment}}});
        my $result = $options{snmp}->map_instance(mapping => $mappings->{$equipment}, results => $snmp_result->{$oids->{$equipment}}, instance => 0);
        $self->{memory} = { 
            used => $result->{usedMemory},
            free => $result->{freeMemory},
            total => $result->{totalMemory},
            prct_used => $result->{usedMemory} * 100 / $result->{totalMemory},
        };
    }
}

1;

__END__

=head1 MODE

Check memory usage 

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(memory)$'

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=back

=cut
