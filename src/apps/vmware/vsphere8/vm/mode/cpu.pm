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

package apps::vmware::vsphere8::vm::mode::cpu;
use strict;
use warnings;
use base qw(apps::vmware::vsphere8::vm::mode);

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options);

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
        { name => 'cpu_usage',      type => 0 }
    ];

    $self->{maps_counters}->{cpu_usage} = [
        {
            label  => 'usage-prct',
            type   => 1,
            nlabel => 'cpu.capacity.usage.percentage',
            set    => {
                output_template => 'CPU average usage is %.2f %%',
                key_values      => [ { name => 'prct_used' } ],
                output_use      => 'prct_used',
                threshold_use   => 'prct_used',
                perfdatas       => [
                    {
                        value    => 'prct_used',
                        template => '%.2f',
                        min      => 0,
                        max      => 100,
                        unit     => '%'
                    }
                ]
            }
        },
        {
            label  => 'usage-frequency',
            type   => 1,
            nlabel => 'cpu.capacity.usage.hertz',
            set    => {
                key_values      => [ { name => 'cpu.capacity.usage.VM' }, { name => 'cpu_usage_hertz' }, { name => 'cpu_provisioned_hertz' } ],
                output_use      => 'cpu.capacity.usage.VM',
                threshold_use   => 'cpu.capacity.usage.VM',
                output_template => 'used frequency is %s kHz',
                perfdatas       => [
                    {
                        value    => 'cpu_usage_hertz',
                        template => '%s',
                        min      => 0,
                        max      => 'cpu_provisioned_hertz',
                        unit     => 'Hz'
                    }
                ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    # Set the list of basic counters IDs
    my @counters = (
        'cpu.capacity.entitlement.VM',
        'cpu.capacity.usage.VM'
    );

    # Get all the needed stats
    my %results = map {
        $_ => $self->get_vm_stats(%options, cid => $_, vm_id => $self->{vm_id}, vm_name => $self->{vm_name} )
    } @counters;

    # Example:
    # $VAR1 = {
    #           'cpu.capacity.usage.VM' => '81.37',
    #           'cpu.capacity.entitlement.VM' => '733'
    #         };

    if (!defined($results{'cpu.capacity.usage.VM'}) || !defined($results{'cpu.capacity.entitlement.VM'})) {
        $self->{output}->add_option_msg(short_msg => "get_vm_stats function failed to retrieve stats");
        $self->{output}->option_exit();
    }

    $self->{cpu_usage} = {
        'prct_used'               => 100 * $results{'cpu.capacity.usage.VM'} / $results{'cpu.capacity.entitlement.VM'},
        'cpu_usage_hertz'         => $results{'cpu.capacity.usage.VM'} * 1000_000,
        'cpu_provisioned_hertz'   => $results{'cpu.capacity.entitlement.VM'} * 1000_000,
        'cpu.capacity.usage.VM'   => $results{'cpu.capacity.usage.VM'}
    };

    return 1;
}

1;

__END__

=head1 MODE

Monitor the CPU stats of a VMware virtual machine through vSphere 8 REST API.

    Meaning of the available counters in the VMware API:
    - cpu.capacity.entitlement.VM     CPU resources in MHz devoted by the ESXi scheduler to the virtual machines and resource pools.
    - cpu.capacity.usage.VM           CPU usage in MHz during the interval.

    The default metrics provided by this plugin are:
    - cpu.capacity.usage.hertz based on the API's cpu.capacity.usage.VM counter
    - cpu.capacity.usage.percentage based on 100 * cpu.capacity.usage.VM / cpu.capacity.entitlement.VM

=over 8

=item B<--warning-usage-frequency>

Threshold in Hertz.

=item B<--critical-usage-frequency>

Threshold in Hertz.

=item B<--warning-usage-prct>

Threshold in percentage.

=item B<--critical-usage-prct>

Threshold in percentage.

=back

=cut
