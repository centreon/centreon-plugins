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

package apps::vmware::vsphere8::esx::mode::diskio;
use strict;
use warnings;
use base qw(apps::vmware::vsphere8::esx::mode);

my @counters = (
    "disk.throughput.usage.HOST",
    "disk.throughput.contention.HOST"
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
                key_values      => [ { name => 'disk.throughput.usage.HOST' }, { name => 'throughput_bps' } ],
                closure_custom_output => $self->can('custom_diskio_output'),
                perfdatas       => [ { value => 'throughput_bps', template => '%s', unit => 'Bps' } ]
            }
        },
        {
            label           => 'contention-ms',
            type            => 1,
            nlabel          => 'disk.throughput.contention.milliseconds',
            set             => {
                key_values      => [ { name => 'disk.throughput.contention.HOST' }],
                output_template => 'Disk throughput contention is %s ms',
                output_use      => 'disk.throughput.contention.HOST',
                threshold_use   => 'disk.throughput.contention.HOST',
                perfdatas       => [ { value => 'disk.throughput.contention.HOST', template => '%s', unit => 'ms' } ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my %results = map {
        $_ => $self->get_esx_stats(%options, cid => $_, esx_id => $self->{esx_id}, esx_name => $self->{esx_name} )
    } @counters;

    if (!defined($results{'disk.throughput.usage.HOST'}) || !defined($results{'disk.throughput.contention.HOST'})) {
        $self->{output}->option_exit(short_msg => "get_esx_stats function failed to retrieve stats");
    }

    $self->{diskio} = \%results;
    $self->{diskio}->{throughput_bps} = $results{'disk.throughput.usage.HOST'} * 1024;

    return 1;
}

1;

=head1 MODE

Monitor the disk throughput and contention of VMware ESX hosts through vSphere 8 REST API.

    Meaning of the available counters in the VMware API:
    - disk.throughput.usage.HOST         Aggregated disk I/O rate (in kB/s), including the rates for all virtual machines running on the host during the collection interval
    - disk.throughput.contention.HOST    Average amount of time (in milliseconds) for an I/O operation to complete successfully

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
