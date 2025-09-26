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

package apps::vmware::vsphere8::vm::mode::diskio;
use strict;
use warnings;
use base qw(apps::vmware::vsphere8::vm::mode);

my @counters = (
    "disk.throughput.usage.VM",
    "disk.throughput.contention.VM"
);

sub custom_diskio_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Disk throughput usage: %s %s/s",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{throughput_bps})
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'diskio', type => 0 }
    ];

    $self->{maps_counters}->{diskio} = [
        {
            label           => 'usage-bps',
            type            => 1,
            nlabel          => 'disk.throughput.usage.bytespersecond',
            set             => {
                key_values      => [ { name => 'disk.throughput.usage.VM' }, { name => 'throughput_bps' } ],
                closure_custom_output => $self->can('custom_diskio_output'),
                perfdatas       => [ { value => 'throughput_bps', template => '%s', unit => 'Bps' } ]
            }
        },
        {
            label           => 'contention-ms',
            type            => 1,
            nlabel          => 'disk.throughput.contention.milliseconds',
            set             => {
                key_values      => [ { name => 'disk.throughput.contention.VM' }],
                output_template => 'Disk throughput contention is %s ms',
                output_use      => 'disk.throughput.contention.VM',
                threshold_use   => 'disk.throughput.contention.VM',
                perfdatas       => [ { value => 'disk.throughput.contention.VM', template => '%s', unit => 'ms' } ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my %results = map {
        $_ => $self->get_vm_stats(%options, cid => $_, vm_id => $self->{vm_id}, vm_name => $self->{vm_name} )
    } @counters;
    if (!defined($results{'disk.throughput.usage.VM'}) || !defined($results{'disk.throughput.contention.VM'})) {
        $self->{output}->add_option_msg(short_msg => "get_vm_stats function failed to retrieve stats");
        $self->{output}->option_exit();
    }

    $self->{diskio} = \%results;

    if ( defined($results{'disk.throughput.usage.VM'}) ) {
        $self->{diskio}->{throughput_bps} = $results{'disk.throughput.usage.VM'} * 1024;
    }
}

1;

=head1 MODE

Monitor the disk throughput and contention of VMware virtual machines through vSphere 8 REST API.

    Meaning of the available counters in the VMware API:
    - disk.throughput.usage.VM         Virtual disk I/O rate.
    - disk.throughput.contention.VM    Average amount of time for an I/O operation to complete successfully.

=over 8

=item B<--warning-contention-ms>

Threshold in milliseconds.

=item B<--critical-contention-ms>

Threshold in milliseconds.

=item B<--warning-usage-bps>

Threshold in bytes per second.

=item B<--critical-usage-bps>

Threshold in bytes per second.

=back

=cut
