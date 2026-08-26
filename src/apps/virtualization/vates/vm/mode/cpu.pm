#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::virtualization::vates::vm::mode::cpu;
use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::misc qw/is_empty/;
use centreon::plugins::constants qw(:counters :values);


sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, force_new_perfdata => 1, %options);

    $options{options}->add_options(
        arguments => {
            'vm-uuid:s' => { name => 'vm_uuid', default => '' },
            'vm-name:s' => { name => 'vm_name', default => '' }
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    if (is_empty($options{option_results}->{vm_uuid}) and is_empty($options{option_results}->{vm_name})) {
        $self->{output}->option_exit(short_msg => "you must fill either --vm-uuid or --vm-name.");
    }
    $self->SUPER::check_options(%options);
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu', type => COUNTER_TYPE_GLOBAL }
    ];

    $self->{maps_counters}->{cpu} = [
        {
            label  => 'cpu-usage-prct',
            type   => COUNTER_TYPE_INSTANCE,
            nlabel => 'vm.cpu.usage.percentage',
            set    => {
                key_values      => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'CPU usage is %.2f %%',
                output_use      => 'prct_used',
                threshold_use   => 'prct_used',
                perfdatas       => [
                    { value => 'prct_used', template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my $vm_info = $options{custom}->get_vm_info();

    if ($vm_info->{power_state} ne "Running"){
        $self->{output}->option_exit(short_msg => "vm '" . $vm_info->{name_label} . "' is not started, can not get memory usage data.");
    }
    my $vm_stats = $options{custom}->request_api_get(endpoint => 'vms/' . $vm_info->{uuid} . '/stats');



    if (
        !defined($vm_stats->{stats})
        or !defined($vm_stats->{stats}->{cpuUsage})
        or ref($vm_stats->{stats}->{cpuUsage}) ne "ARRAY"
        or scalar @{ $vm_stats->{stats}->{cpuUsage} } == 0
    ) {
        $self->{output}->option_exit(short_msg => "Field cpuUsage not found in API response for vm '" . $vm_info->{name_label} . "'. Please check --debug or the Swagger documentation.");
    }

    # the API returns a time series, the last value is the most recent one.
    $self->{cpu} = {
        display    => $vm_info->{name_label},
        prct_used  => $vm_stats->{stats}->{cpuUsage}->[-1]
    };
}

1;

__END__

=head1 MODE

Check the CPU usage of one Xen Orchestra virtual machine.

=over 8

=item B<--vm-uuid>

Identify the virtual machine by its exact uuid.

=item B<--vm-name>

Identify the virtual machine by its name (only one machine is expected).

=item B<--warning-cpu-usage-prct>

Threshold warning for the CPU usage percentage.

=item B<--critical-cpu-usage-prct>

Threshold critical for the CPU usage percentage.

=back

=cut
