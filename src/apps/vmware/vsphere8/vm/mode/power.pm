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

package apps::vmware::vsphere8::vm::mode::power;
use strict;
use warnings;
use base qw(apps::vmware::vsphere8::vm::mode);
use centreon::plugins::misc qw/is_empty/;

my @counters = (
    'power.capacity.usage.VM'        # Current power usage.
);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'power', type => 0 }
    ];

    $self->{maps_counters}->{power} = [
        {
            label           => 'usage-watt',
            type            => 1,
            nlabel          => 'power.capacity.usage.watt',
            output_template => 'Power usage is %d Watts',
            set             => {
                output_template => 'Power usage is %s Watts',
                key_values      => [ { name => 'power.capacity.usage.VM' } ],
                perfdatas       => [ { value => 'power.capacity.usage.VM', template => '%s', unit => 'W', min => 0 } ]
            }
        }
    ];

}

sub manage_selection {
    my ($self, %options) = @_;

    my %results = map {
        $_ => $self->get_vm_stats(%options, cid => $_, vm_id => $self->{vm_id}, vm_name => $self->{vm_name} )
    } @counters;
    $self->{output}->option_exit(short_msg => "No available data") if is_empty($results{'power.capacity.usage.VM'});
    $self->{power} = {
        'power.capacity.usage.VM' => $results{'power.capacity.usage.VM'}
    };
    return 1;
}

1;

=head1 MODE

Monitor the power consumption of a VMware virtual machine through vSphere 8 REST API.

    Meaning of the available counters in the VMware API:
    - power.capacity.usage.VM       Current power usage in Watts.

=over 8

=item B<--warning-usage-watt>

Threshold in Watts.

=item B<--critical-usage-watt>

Threshold in Watts.

=back

=cut
