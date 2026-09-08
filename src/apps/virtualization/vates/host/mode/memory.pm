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

package apps::virtualization::vates::host::mode::memory;
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
            'host-uuid:s' => { name => 'host_uuid', default => '' },
            'host-name:s' => { name => 'host_name', default => '' }
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    if (is_empty($options{option_results}->{host_uuid}) and is_empty($options{option_results}->{host_name})) {
        $self->{output}->option_exit(short_msg => "you must fill either --host-uuid or --host-name.");
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
            label             => 'memory-usage-prct',
            type              => COUNTER_TYPE_INSTANCE,
            nlabel            => 'host.memory.usage.percentage',
            warning_default   => '80',
            critical_default  => '95',
            set               => {
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
            nlabel => 'host.memory.usage.bytes',
            set    => {
                key_values            => [ { name => 'used_bytes' }, { name => 'total_bytes' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                threshold_use         => 'used_bytes',
                perfdatas             => [
                    { value => 'used_bytes', template => '%d', min => 0, max => 'total_bytes', unit => 'B' }
                ]
            }
        },
        {
            label  => 'memory-free-bytes',
            type   => COUNTER_TYPE_INSTANCE,
            nlabel => 'host.memory.free.bytes',
            set    => {
                key_values      => [ { name => 'free_bytes' } ],
                output_template => 'free memory is %s B',
                perfdatas       => [
                    { value => 'free_bytes', template => '%d', min => 0, unit => 'B' }
                ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my $host = $options{custom}->get_host_info(fields => "name_label,enabled,power_state,memory,uuid");

    if ($host->{enabled} ne 'true' or $host->{power_state} ne 'Running') {
        $self->{output}->option_exit(short_msg => "host '" . $host->{name_label} . "' is not enabled/running, can not get memory usage data.");
    }

    if (
        !defined($host->{memory})
        or ref($host->{memory}) ne "HASH"
        or !defined($host->{memory}->{size})
        or !defined($host->{memory}->{usage})
    ) {
        $self->{output}->option_exit(short_msg => "Field memory not found in API response for host '" . $host->{name_label} . "'. Please check --debug or the Swagger documentation.");
    }

    my $total = $host->{memory}->{size};
    my $used  = $host->{memory}->{usage};

    if ($total == 0) {
        $self->{output}->option_exit(short_msg => "'" . $host->{uuid} . "' host reports a total memory of 0, inconsistent data.");
    }

    $self->{memory} = {
        used_bytes  => $used,
        free_bytes  => $total - $used,
        total_bytes => $total,
        used_prct   => 100 * $used / $total
    };
}

1;

__END__

=head1 MODE

Check the memory usage of a Vates XCP-ng host. C<memory.usage> is the real memory in use
(total minus free), not an allocation. The host must be enabled and running: a disabled/halted
host returns UNKNOWN rather than a misleading near-zero usage.

=over 8

=item B<--host-uuid>

Identify the host by its exact uuid.

=item B<--host-name>

Identify the host by its name (only one host is expected).

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

=item B<--warning-memory-free-bytes>

Threshold warning for the free memory, in bytes.

=item B<--critical-memory-free-bytes>

Threshold critical for the free memory, in bytes.

=back

=cut
