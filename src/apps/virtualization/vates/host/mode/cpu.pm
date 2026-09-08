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

package apps::virtualization::vates::host::mode::cpu;
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
        { name => 'cpu', type => COUNTER_TYPE_GLOBAL }
    ];

    $self->{maps_counters}->{cpu} = [
        {
            label             => 'cpu-usage-prct',
            type              => COUNTER_TYPE_INSTANCE,
            nlabel            => 'host.cpu.usage.percentage',
            warning_default   => '80',
            critical_default  => '95',
            set               => {
                key_values      => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'CPU usage is %.2f %%',
                perfdatas       => [
                    { value => 'prct_used', template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        {
            label  => 'cpu-count',
            type   => COUNTER_TYPE_INSTANCE,
            nlabel => 'host.cpu.count',
            set    => {
                key_values      => [ { name => 'cpu_count' }, { name => 'display' } ],
                output_template => '%s pCPU(s)',
                perfdatas       => [
                    { value => 'cpu_count', template => '%d', min => 0 }
                ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    # get_name_and_uuid only resolves identity (uuid/name_label) and caches it on disk, unlike
    # get_host_info which always hits the API live. We don't need any other host field here: the
    # "is the host actually reachable" check is deferred to the /stats call itself below.
    my $host = $options{custom}->get_name_and_uuid(type => "host", api_endpoint => "hosts");

    # silently_fail lets us read the (non-200) error body ourselves instead of the http layer
    # auto-exiting with a generic "500 ..." UNKNOWN: a disabled/halted host makes this endpoint
    # fail with a XAPI "HOST_OFFLINE" error, which we can report with a clearer message.
    my $host_stats = $options{custom}->request_api_get(endpoint => 'hosts/' . $host->{uuid} . '/stats', silently_fail => 1);

    if (defined($host_stats->{error})) {
        $self->{output}->option_exit(short_msg => "host '" . $host->{name_label} . "' is not enabled/running, can not get CPU usage data (" . $host_stats->{error} . ").");
    }

    if (
        !defined($host_stats->{stats})
        or !defined($host_stats->{stats}->{cpus})
        or ref($host_stats->{stats}->{cpus}) ne "HASH"
        or scalar(keys %{$host_stats->{stats}->{cpus}}) == 0
    ) {
        $self->{output}->option_exit(short_msg => "Field cpus not found in API response for host '" . $host->{name_label} . "'. Please check --debug or the Swagger documentation.");
    }

    # the API returns one time series (percentage) per physical core, the last value of each
    # series is the most recent one. The aggregated usage is the average of all cores, and the
    # number of series is itself the live physical CPU count (no need for the separate,
    # deprecated CPUs.cpu_count field on the host object).
    my $total = 0;
    my $cores = 0;
    for my $core (keys %{$host_stats->{stats}->{cpus}}) {
        my $serie = $host_stats->{stats}->{cpus}->{$core};
        next if (ref($serie) ne "ARRAY" or scalar @$serie == 0);
        $total += $serie->[-1];
        $cores++;
    }
    if ($cores == 0) {
        $self->{output}->option_exit(short_msg => "Field cpus is empty in API response for host '" . $host->{name_label} . "'. Please check --debug or the Swagger documentation.");
    }

    $self->{cpu} = {
        display    => $host->{name_label},
        prct_used  => $total / $cores,
        cpu_count  => $cores
    };
}

1;

__END__

=head1 MODE

Check the aggregated CPU usage of a Vates XCP-ng host (average of the last real-time value of
every physical core, as reported by C<< GET /hosts/<uuid>/stats >>).

=over 8

=item B<--host-uuid>

Identify the host by its exact uuid.

=item B<--host-name>

Identify the host by its name (only one host is expected).

=item B<--warning-cpu-usage-prct>

Threshold warning for the CPU usage percentage.
Default: 80

=item B<--critical-cpu-usage-prct>

Threshold critical for the CPU usage percentage.
Default: 95

=item B<--warning-cpu-count> / B<--critical-cpu-count>

Threshold on the number of physical CPUs reported by the host. Informative counter, no default.

=back

=cut
