#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::vmware::vsphere8::esx::mode::memory;
use strict;
use warnings;
use base qw(apps::vmware::vsphere8::esx::mode);

my @counters = (
    #'mem.reservedCapacityPct.HOST',    # Percent of memory that has been reserved either through VMkernel use, by userworlds or due to virtual machine memory reservations.
    #'mem.capacity.provisioned.HOST',   # Total amount of memory available to the host.
    'mem.capacity.usable.HOST',         # Amount of physical memory available for use by virtual machines on this host
    #'mem.capacity.usage.HOST',         # Amount of physical memory actively used
    #'mem.capacity.contention.HOST',    # Percentage of time VMs are waiting to access swapped, compressed or ballooned memory.
    'mem.consumed.vms.HOST',            # Amount of physical memory consumed by VMs on this host.
    #'mem.consumed.userworlds.HOST'     # Amount of physical memory consumed by userworlds on this host
);

sub custom_memory_output {
    my ($self, %options) = @_;

    return sprintf(
        'Memory used: %s %s used - Usable: %s %s',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_bytes}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{max_bytes})
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'memory', type => 0, message_separator => ' - '}
    ];

    $self->{maps_counters}->{memory} = [
        {
            label  => 'usage-prct',
            type   => 1,
            nlabel => 'vms.memory.usage.percentage',
            set    => {
                key_values      => [ { name => 'used_prct' } ],
                output_template => '%2.f%% of usable memory is used by VMs',
                output_use      => 'used_prct',
                threshold_use   => 'used_prct',
                perfdatas       => [
                    {
                        value    => 'used_prct',
                        template => '%.2f',
                        min      => 0,
                        max      => 100,
                        unit     => '%'
                    }
                ]
            }
        },
        {
            label  => 'usage-bytes',
            type   => 1,
            nlabel => 'vms.memory.usage.bytes',
            set    => {
                key_values            => [ { name => 'used_bytes' }, { name => 'max_bytes' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                threshold_use         => 'used_bytes',
                perfdatas             => [
                    {
                        value    => 'used_bytes',
                        template => '%d',
                        max      => 'max_bytes',
                        unit     => 'B'
                    }
                ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my %results = map {
        $_ => $self->get_esx_stats(%options, cid => $_, esx_id => $self->{esx_id}, esx_name => $self->{esx_name} )
    } @counters;

    if (!defined($results{'mem.capacity.usable.HOST'}) || !defined($results{'mem.consumed.vms.HOST'})) {
        $self->{output}->option_exit(short_msg => "get_esx_stats function failed to retrieve stats");
    }

    $self->{output}->add_option_msg(long_msg => 'Retrieved value for mem.capacity.usable.HOST: ' . $results{'mem.capacity.usable.HOST'});
    $self->{output}->add_option_msg(long_msg => 'Retrieved value for mem.consumed.vms.HOST: ' . $results{'mem.consumed.vms.HOST'});
    $self->{memory} = {
        used_prct  => (100 * $results{'mem.consumed.vms.HOST'} / $results{'mem.capacity.usable.HOST'}),
        used_bytes => int(1024 * 1024 * $results{'mem.consumed.vms.HOST'}),
        max_bytes  => int(1024 * 1024 * $results{'mem.capacity.usable.HOST'})
    };

    return 1;
}

1;

=head1 MODE

Monitor the memory of VMware ESX hosts consumed by the virtual machines through vSphere 8 REST API.

    Meaning of the available counters in the VMware API:
    - mem.reservedCapacityPct.HOST     Percent of memory that has been reserved either through VMkernel use, by userworlds or due to virtual machine memory reservations.
    - mem.capacity.provisioned.HOST    Total amount of memory available to the host.
    - mem.capacity.usable.HOST         Amount of physical memory available for use by virtual machines on this host
    - mem.capacity.usage.HOST          Amount of physical memory actively used
    - mem.capacity.contention.HOST     Percentage of time VMs are waiting to access swapped, compressed or ballooned memory.
    - mem.consumed.vms.HOST            Amount of physical memory consumed by VMs on this host.
    - mem.consumed.userworlds.HOST     Amount of physical memory consumed by userworlds on this host

=over 8

=item B<--warning-usage-bytes>

Threshold in bytes.

=item B<--critical-usage-bytes>

Threshold in bytes.

=item B<--warning-usage-prct>

Threshold in percentage.

=item B<--critical-usage-prct>

Threshold in percentage.

=back

=cut
