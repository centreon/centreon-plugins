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

package apps::vmware::vsphere8::vcenter::mode::vmcount;

use base qw(apps::vmware::vsphere8::vcenter::mode);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        {
            label  => 'on-count',
            nlabel => 'vm.poweredon.count',
            type   => 1,
            set    => {
                key_values      => [ { name => 'POWERED_ON' }, { name => 'total' } ],
                output_template => '%s VM(s) powered on',
                perfdatas       => [
                    { label => 'POWERED_ON', template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        {
            label  => 'off-count',
            nlabel => 'vm.poweredoff.count',
            type   => 1,
            set    => {
                key_values      => [ { name => 'POWERED_OFF' }, { name => 'total' } ],
                output_template => '%s VM(s) powered off',
                perfdatas       => [
                    { label => 'POWERED_OFF', template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        {
            label  => 'suspended-count',
            nlabel => 'vm.suspended.count',
            type   => 1,
            set    => {
                key_values      => [ { name => 'SUSPENDED' }, { name => 'total' } ],
                output_template => '%s VM(s) suspended',
                perfdatas       => [
                    { label => 'SUSPENDED', template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        {
            label           => 'total-count',
            nlabel          => 'vm.total.count',
            type            => 1,
            warning_default => '1:',
            set             => {
                key_values      => [ { name => 'total' } ],
                output_template => '%s VM(s) in total',
                perfdatas       => [
                    { label => 'total', template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);

    $options{options}->add_options(
        arguments => {
            'include-name:s'  => { name => 'include_name', default => '' },
            'exclude-name:s'  => { name => 'exclude_name', default => '' },
            'include-state:s' => { name => 'include_state', default => '' },
            'exclude-state:s' => { name => 'exclude_state', default => '' },
        }
    );
    $options{options}->add_help(package => __PACKAGE__, sections => 'VMWARE 8 VCENTER OPTIONS', once => 1);

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # get the response from /api/vcenter/vm endpoint
    my $response = $self->get_vms(%options);

    $self->{global} = {
        'POWERED_ON'  => 0,
        'POWERED_OFF' => 0,
        'SUSPENDED'   => 0,
        'total'       => 0,
        'UNKNOWN'     => 0
    };

    for my $vm (@{$response}) {
        # avoid undef values
        my $entry = {
            vm              => $vm->{vm},
            name            => $vm->{name},
            cpu_count       => $vm->{cpu_count} // 0,
            power_state     => $vm->{power_state} // 'UNKNOWN',
            memory_size_MiB => $vm->{memory_size_MiB} // 0
        };

        my $entry_desc = sprintf(
            "VM '%s' (%s) which is %s, has %d CPUs and %d MiB of RAM",
            $entry->{name},
            $entry->{vm},
            $entry->{power_state},
            $entry->{cpu_count},
            $entry->{memory_size_MiB}
        );
        if ( centreon::plugins::misc::is_excluded($entry->{name}, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name})
            || centreon::plugins::misc::is_excluded($entry->{power_state}, $self->{option_results}->{include_state}, $self->{option_results}->{exclude_state}) ) {
            $self->{output}->output_add(long_msg => "skipping VM " . $entry_desc . " (excluded)", debug => 1);
            next;
        }

        $self->{output}->output_add(long_msg => $entry_desc);
        $self->{global}->{ $entry->{power_state} }++;
        $self->{global}->{total}++;

    }
}

1;

__END__

=head1 MODE

Monitor the number of VMware VMs through vSphere 8 REST API.

=over 8

=item B<--include-name>

Filter by including only the VMs whose name matches the regular expression provided after this parameter.

Example : C<--include-name='^prod.*'>

=item B<--exclude-name>

Filter by excluding the VMs whose name matches the regular expression provided after this parameter.

Example : C<--exclude-name='^sandbox.*'>

=item B<--include-state>

Filter by including only the VMs whose power state matches the regular expression provided after this parameter.

Example : C<--include-name='^POWERED_ON$'>

=item B<--exclude-state>

Filter by excluding the VMs whose state matches the regular expression provided after this parameter.

Example : C<--exclude-name='^POWERED_OFF|SUSPENDED$'>

=item B<--warning-on-count>

Threshold.

=item B<--critical-on-count>

Threshold.

=item B<--warning-off-count>

Threshold.

=item B<--critical-off-count>

Threshold.

=item B<--warning-suspended-count>

Threshold.

=item B<--critical-suspended-count>

Threshold.

=item B<--warning-total-count>

Threshold.

=item B<--critical-total-count>

Threshold.

=back

=cut
