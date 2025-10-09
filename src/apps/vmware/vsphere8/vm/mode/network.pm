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

package apps::vmware::vsphere8::vm::mode::network;
use strict;
use warnings;
use base qw(apps::vmware::vsphere8::vm::mode);

my @counters = (
    'net.throughput.contention.VM',
    'net.throughput.usage.VM'
);

sub custom_network_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Network throughput usage: %s %s/s",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{usage_bps})
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'network', type => 0 },
        { name => 'contention', type => 0 }

    ];

    $self->{maps_counters}->{network} = [
        {
            label      => 'usage-bps',
            type       => 1,
            nlabel     => 'network.throughput.usage.bitspersecond',
            set        => {
                key_values            => [ { name => 'usage_bps' }],
                closure_custom_output => $self->can('custom_network_output'),
                perfdatas             => [ { value => 'usage_bps', template => '%s', unit => 'nps', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{contention} = [
        {
            label  => 'contention-count',
            type   => 1,
            nlabel => 'network.throughput.contention.count',
            set    => {
                key_values      => [ { name => 'net.throughput.contention.VM' } ],
                output_template => "%d packet(s) dropped",
                perfdatas       => [ { value => 'net.throughput.contention.VM', template => '%s', unit => '' } ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my %results = map {
        $_ => $self->get_vm_stats(%options, cid => $_, vm_id => $self->{vm_id}, vm_name => $self->{vm_name} )
    } @counters;

    $self->{network} = {};
    $self->{contention} = {};

    if (!defined($results{'net.throughput.usage.VM'}) || !defined($results{'net.throughput.contention.VM'})) {
        $self->{output}->add_option_msg(short_msg => "get_vm_stats function failed to retrieve stats");
        $self->{output}->option_exit();
    }

    $self->{network}->{usage_bps} = $results{'net.throughput.usage.VM'} * 1024 * 8;
    $self->{contention}->{'net.throughput.contention.VM'} = $results{'net.throughput.contention.VM'};
}

1;

=head1 MODE

Monitor the swap usage of VMware virtual machines through vSphere 8 REST API.

    - net.throughput.usage.VM            The current network bandwidth usage (in kB/s) for the host.
    - net.throughput.contention.VM       The aggregate network droppped packets for the host.

=over 8

=item B<--warning-contention-count>

Threshold.

=item B<--critical-contention-count>

Threshold.

=item B<--warning-usage-bps>

Threshold in bytes per second.

=item B<--critical-usage-bps>

Threshold in bytes per second.

=back

=cut
