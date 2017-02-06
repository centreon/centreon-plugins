#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package network::raisecom::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_absolute});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_absolute});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_absolute});
    
    my $msg = sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                      $total_size_value . " " . $total_size_unit,
                      $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_absolute},
                      $total_free_value . " " . $total_free_unit, 100 - $self->{result_values}->{prct_used_absolute});
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'memory', type => 0, cb_prefix_output => 'prefix_memory_output' }
    ];
    
    $self->{maps_counters}->{memory} = [
        { label => 'memory', set => {
                key_values => [ { name => 'prct_used'}, { name => 'used' }, { name => 'free' }, { name => 'total' }  ],
                closure_custom_output => $self->can('custom_usage_output'),
                threshold_use => 'prct_used_absolute',
                perfdatas => [
                    { label => 'used', value => 'used_absolute', template => '%.2f', threshold_total => 'total_absolute', cast_int => 1,
                      min => 0, max => 'total_absolute', unit => 'B' },
                ],
            }
        },
    ];
}

sub prefix_memory_output {
    my ($self, %options) = @_;
    
    return "Memory ";
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
    
    my ($total_bytes, $used_bytes, $free_bytes);
   
    #  RAISECOM-SYSTEM-MIB
    my $oid_raisecomAvailableMemory = '.1.3.6.1.4.1.8886.1.1.3.2.0';
    my $oid_raisecomTotalMemory = '.1.3.6.1.4.1.8886.1.1.3.1.0';

    my $results = $options{snmp}->get_leef(oids => [$oid_raisecomAvailableMemory, $oid_raisecomTotalMemory ],
                                           nothing_quit => 1);
     
    $total_bytes = $results->{$oid_raisecomTotalMemory};
    $free_bytes = $results->{$oid_raisecomAvailableMemory};
    $used_bytes = $total_bytes - $free_bytes;
    
    $self->{memory} = {display => 'memory',
             prct_used => $used_bytes * 100 / $total_bytes,
             used => $used_bytes,
             free => $free_bytes,
             total => $total_bytes,
             };     
}

1;

__END__

=head1 MODE

Check memory usage 

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=back

=cut
