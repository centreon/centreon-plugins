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

package network::raisecom::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'Memory total: %s %s used: %s %s (%.2f%%) free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'memory', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_raisecomAvailableMemory = '.1.3.6.1.4.1.8886.1.1.3.2.0';
    my $oid_raisecomTotalMemory = '.1.3.6.1.4.1.8886.1.1.3.1.0';
    my $oid_PON_raisecomAvailableMemory = '.1.3.6.1.4.1.8886.18.1.7.3.1.1.2.1.0';
    my $oid_PON_raisecomTotalMemory = '.1.3.6.1.4.1.8886.18.1.7.3.1.1.1.1.0';
    
    my $oids = [$oid_raisecomAvailableMemory, $oid_raisecomTotalMemory, $oid_PON_raisecomAvailableMemory, $oid_PON_raisecomTotalMemory];
  
    my $result = $self->{snmp}->get_leef(oids => $oids, nothing_quit => 1);

    my $free_size = defined($result->{$oid_raisecomAvailableMemory}) ? $result->{$oid_raisecomAvailableMemory} : $result->{$oid_PON_raisecomAvailableMemory};
    my $total_size = defined($result->{$oid_raisecomTotalMemory}) ? $result->{$oid_raisecomTotalMemory} : $result->{$oid_PON_raisecomTotalMemory};
    my $used_size = $total_size - $free_size;
    
    my $prct_used = $used_size * 100 / $total_size;
    my $prct_free = 100 - $prct_used;

    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_size);
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $used_size);
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $free_size);
                                 
    $self->{memory} = {
        total => $total_size,
        used => $used_size,
        free => $free_size,
        prct_used => $prct_used,
        prct_free => $prct_free
    };
}

1;

__END__

=head1 MODE

Check memory usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
