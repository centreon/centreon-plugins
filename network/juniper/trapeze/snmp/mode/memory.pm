#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package network::juniper::trapeze::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    
    my $msg = sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                      $total_size_value . " " . $total_size_unit,
                      $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                      $total_free_value . " " . $total_free_unit, 100 - $self->{result_values}->{prct_used});
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'memory', type => 0, cb_prefix_output => 'prefix_memory_output' },
        { name => 'flash', type => 0, cb_prefix_output => 'prefix_flash_output' }
    ];
    
    $self->{maps_counters}->{memory} = [
        { label => 'memory', set => {
                key_values => [ { name => 'prct_used'}, { name => 'used' }, { name => 'free' }, { name => 'total' }  ],
                closure_custom_output => $self->can('custom_usage_output'),
                threshold_use => 'prct_used',
                perfdatas => [
                    { label => 'memory', value => 'used', template => '%.2f', threshold_total => 'total', cast_int => 1,
                      min => 0, max => 'total', unit => 'B' },
                ],
            }
        },
    ];
    $self->{maps_counters}->{flash} = [
        { label => 'flash', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                threshold_use => 'prct_used',
                perfdatas => [
                    { label => 'flash', value => 'used', template => '%.2f', threshold_total => 'total', cast_int => 1,
                      min => 0, max => 'total', unit => 'B' },
                ],
            }
        },
    ];   
}

sub prefix_memory_output {
    my ($self, %options) = @_;
    
    return "Memory ";
}

sub prefix_flash_output {
    my ($self, %options) = @_;

    return "Flash ";
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

sub manage_selection {
    my ($self, %options) = @_;
    
    my ($total_bytes, $used_bytes, $free_bytes);
   
    #  TRAPEZE-NETWORKS-SYSTEM-MIB
    my $oid_trpzSysFlashMemoryUsedBytes = '.1.3.6.1.4.1.14525.4.8.1.1.3.0';
    my $oid_trpzSysFlashMemoryTotalBytes = '.1.3.6.1.4.1.14525.4.8.1.1.4.0';
    my $oid_trpzSysCpuMemoryInstantUsage = '.1.3.6.1.4.1.14525.4.8.1.1.12.1.0';
    my $oid_trpzSysCpuMemoryUsedBytes = '.1.3.6.1.4.1.14525.4.8.1.1.1.0';
    my $oid_trpzSysCpuMemoryTotalBytes = '.1.3.6.1.4.1.14525.4.8.1.1.2.0';
    my $oid_trpzSysCpuMemorySize = '.1.3.6.1.4.1.14525.4.8.1.1.6.0';

    my $results = $options{snmp}->get_leef(oids => [$oid_trpzSysFlashMemoryUsedBytes, $oid_trpzSysFlashMemoryTotalBytes, $oid_trpzSysCpuMemoryUsedBytes,
                                                    $oid_trpzSysCpuMemoryInstantUsage, $oid_trpzSysCpuMemorySize, $oid_trpzSysCpuMemoryTotalBytes ],
                                           nothing_quit => 1);
     
    if (defined($results->{$oid_trpzSysCpuMemorySize}) || $results->{$oid_trpzSysCpuMemorySize} != 0) {
        $total_bytes = $results->{$oid_trpzSysCpuMemorySize} * 1024;
        $used_bytes = $results->{$oid_trpzSysCpuMemoryInstantUsage} * 1024;
        $free_bytes = $total_bytes - $used_bytes;
    } else {
        $total_bytes = $results->{$oid_trpzSysCpuMemoryTotalBytes};
        $used_bytes = $results->{$oid_trpzSysCpuMemoryUsedBytes};
        $free_bytes = $total_bytes - $used_bytes;
    }

    my $free_bytes_flash = $results->{$oid_trpzSysFlashMemoryTotalBytes} - $results->{$oid_trpzSysFlashMemoryUsedBytes};

    $self->{memory} = {display => 'memory',
             prct_used => $used_bytes * 100 / $total_bytes,
             used => $used_bytes,
             free => $free_bytes,
             total => $total_bytes,
             };
    
    $self->{flash} = {display => 'flash',
            prct_used => $results->{$oid_trpzSysFlashMemoryUsedBytes} * 100 / $results->{$oid_trpzSysFlashMemoryTotalBytes},
            used => $results->{$oid_trpzSysFlashMemoryUsedBytes},
            free => $free_bytes_flash,
            total => $results->{$oid_trpzSysFlashMemoryTotalBytes},
           };         
}

1;

__END__

=head1 MODE

Check memory usage 

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(memory)$'

=item B<--warning-*>

Threshold warning.
Can be: 'memory', 'flash'

=item B<--critical-*>

Threshold critical.
Can be: 'memory', 'flash'

=back

=cut
