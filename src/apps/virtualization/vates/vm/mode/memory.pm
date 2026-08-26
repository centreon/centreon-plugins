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

package apps::virtualization::vates::vm::mode::memory;
use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::misc qw/is_empty/;
use centreon::plugins::constants qw(:counters :values);

sub custom_memory_output {
    my ($self, %options) = @_;

    return sprintf(
        '%s%s out of %s%s total',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_bytes}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_bytes})
    );
}

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
        { name => 'memory', type => COUNTER_TYPE_GLOBAL, message_separator => ' - ' }
    ];

    $self->{maps_counters}->{memory} = [
        {
            label           => 'memory-usage-prct',
            type            => COUNTER_TYPE_INSTANCE,
            nlabel          => 'vm.memory.usage.percentage',
            warning_default => '80',
            critical_default => '95',
            set             => {
                key_values      => [ { name => 'used_prct' } ],
                output_template => '%.2f %% of the memory is used',
                perfdatas       => [
                    { value => 'used_prct', template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        {
            label  => 'memory-usage-bytes',
            type   => COUNTER_TYPE_INSTANCE,
            nlabel => 'vm.memory.usage.bytes',
            set    => {
                key_values            => [ { name => 'used_bytes' }, { name => 'total_bytes' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                threshold_use         => 'used_bytes',
                perfdatas              => [
                    { value => 'used_bytes', template => '%d', min => 0, max => 'total_bytes', unit => 'B' }
                ]
            }
        },
        {
            label  => 'memory-total-bytes',
            type   => COUNTER_TYPE_INSTANCE,
            nlabel => 'vm.memory.total.bytes',
            set    => {
                key_values      => [ { name => 'total_bytes' } ],
                output_template => 'total memory is %s B',
                perfdatas       => [
                    { value => 'total_bytes', template => '%d', min => 0, unit => 'B' }
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
        or !defined($vm_stats->{stats}->{memory})
        or ref($vm_stats->{stats}->{memory}) ne "ARRAY"
        or scalar @{ $vm_stats->{stats}->{memory} } == 0
        or !defined($vm_stats->{stats}->{memoryFree})
        or ref($vm_stats->{stats}->{memoryFree}) ne "ARRAY"
        or scalar @{ $vm_stats->{stats}->{memoryFree} } == 0
    ) {
        $self->{output}->option_exit(short_msg => "Field memory/memoryFree not found in API response for vm '" . $vm_info->{name_label} . "'. Please check --debug or the Swagger documentation. This can happen when the guest tools are not installed or not running.");
    }

    # the API returns a time series, the last value is the most recent one.
    my $total = $vm_stats->{stats}->{memory}->[-1];
    my $free  = $vm_stats->{stats}->{memoryFree}->[-1];

    if ($total == 0) {
        $self->{output}->option_exit(short_msg => "'" . $vm_info->{uuid} . "' vm reports a total memory of 0, inconsistent data.");
    }

    $self->{memory} = {
        used_bytes  => $total - $free,
        total_bytes => $total,
        used_prct   => 100 * ($total - $free) / $total
    };
}

1;

__END__

=head1 MODE

Check the memory usage of one Xen Orchestra virtual machine.

=over 8

=item B<--vm-uuid>

Identify the virtual machine by its exact uuid.

=item B<--vm-name>

Identify the virtual machine by its name (only one machine is expected).

=item B<--warning-memory-usage-prct>

Threshold warning for the memory usage percentage.
Default: 80

=item B<--critical-memory-usage-prct>

Threshold critical for the memory usage percentage.
Default: 95

=item B<--warning-memory-usage-bytes>

Threshold warning for the memory used, in bytes.

=item B<--critical-memory-usage-bytes>

Threshold critical for the memory used, in bytes.

=item B<--warning-memory-total-bytes>

Threshold warning for the total memory, in bytes.

=item B<--critical-memory-total-bytes>

Threshold critical for the total memory, in bytes.

=back

=cut
