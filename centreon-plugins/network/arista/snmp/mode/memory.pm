#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package network::arista::snmp::mode::memory;

use base qw(snmp_standard::mode::storage);

use strict;
use warnings;

sub default_storage_type {
    my ($self, %options) = @_;
    
    return '^(hrStorageRam|hrStorageFlashMemory)';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'storage', type => 1, cb_prefix_output => 'prefix_storage_output', message_multiple => 'All memory spaces are ok' },
    ];
    
    $self->{maps_counters}->{storage} = [
        { label => 'usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'display' }, { name => 'used' }, { name => 'size' }, { name => 'allocation_units' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub prefix_storage_output {
    my ($self, %options) = @_;
    
    return "Memory space '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    return $self;
}

1;

__END__

=head1 MODE

Check memory.

=over 8

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--storage>

Set the storage (number expected) ex: 1, 2,... (empty means 'check all storage').

=item B<--name>

Allows to use storage name with option --storage instead of storage oid index.

=item B<--regexp>

Allows to use regexp to filter storage (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--show-cache>

Display cache storage datas.

=item B<--filter-storage-type>

Filter storage types with a regexp (Default: '^(hrStorageRam|hrStorageFlashMemory)$').

=back

=cut
