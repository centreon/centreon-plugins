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
use base qw(centreon::plugins::templates::counter);

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
        'Memory used by VMs: %s %s used - Usable: %s %s',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_bytes}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{max_bytes})
    );
}

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {}
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'memory', type => 0 }
    ];

    $self->{maps_counters}->{memory} = [
        {
            label  => 'vms-usage-percentage',
            type   => 1,
            nlabel => 'vms.memory.usage.percentage',
            set    => {
                key_values      => [ { name => 'used_prct' } ],
                output_template => 'Memory used %2.f%%',
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
            label  => 'vms-usage-bytes',
            type   => 1,
            nlabel => 'vms.memory.usage.bytes',
            set    => {
                key_values            => [ { name => 'used_bytes' }, { name => 'max_bytes' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                threshold_use         => 'used_bytes',
                perfdatas             => [
                    {
                        value    => 'used_bytes',
                        template => '%s',
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

    my %structure = map {
        $_ => $options{custom}->get_stats(
            cid => $_,
            rsrc_name => $self->{option_results}->{esx_name},
            rsrc_id => $self->{option_results}->{esx_id})
    } @counters;

    if (defined($structure{'mem.capacity.usable.HOST'}) && defined($structure{'mem.consumed.vms.HOST'})) {
        $self->{output}->add_option_msg(long_msg => 'Retrieved value for mem.capacity.usable.HOST: ' . $structure{'mem.capacity.usable.HOST'});
        $self->{output}->add_option_msg(long_msg => 'Retrieved value for mem.consumed.vms.HOST: ' . $structure{'mem.consumed.vms.HOST'});
        $self->{memory} = {
            used_prct  => (100 * $structure{'mem.consumed.vms.HOST'} / $structure{'mem.capacity.usable.HOST'}),
            used_bytes => (1024 * 1024 * $structure{'mem.consumed.vms.HOST'}),
            max_bytes  => (1024 * 1024 * $structure{'mem.capacity.usable.HOST'})
        };
    }

    return 1;
}

1;

=head1 MODE

Monitor the status of VMware ESX hosts through vSphere 8 REST API.

    Meaning of the available counters in the VMware API:
    mem.reservedCapacityPct.HOST     Percent of memory that has been reserved either through VMkernel use, by userworlds or due to virtual machine memory reservations.
    mem.capacity.provisioned.HOST    Total amount of memory available to the host.
    mem.capacity.usable.HOST         Amount of physical memory available for use by virtual machines on this host
    mem.capacity.usage.HOST          Amount of physical memory actively used
    mem.capacity.contention.HOST     Percentage of time VMs are waiting to access swapped, compressed or ballooned memory.
    mem.consumed.vms.HOST            Amount of physical memory consumed by VMs on this host.
    mem.consumed.userworlds.HOST     Amount of physical memory consumed by userworlds on this host


=over 8

=item B<--esx-id>

Define which ESX id to monitor based on their name (example: C<host-16>).

=item B<--warning-vms-usage-percentage>

Thresholds in percentage.

=item B<--critical-vms-usage-percentage>

Thresholds in percentage.

=item B<--warning-vms-usage-bytes>

Thresholds in bytes.

=item B<--critical-vms-usage-bytes>

Thresholds in bytes.
