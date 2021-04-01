#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package hardware::devices::polycom::trio::restapi::mode::device;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    return "status is '" . $self->{result_values}->{status} . "'";
}

sub custom_memory_output {
    my ($self, %options) = @_;

    return sprintf(
        "memory total: %s %s used: %s %s (%.2f%%) free: %s %s (%.2f%%)",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'cpu-utilization-average', nlabel => 'device.cpu.utilization.average.percentage', set => {
                key_values => [ { name => 'cpu_average' } ],
                output_template => 'cpu average: %.2f%%',
                perfdatas => [
                    { value => 'cpu_average', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'memory-usage', nlabel => 'device.memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' },
                    { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { value => 'used', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1 },
                ],
            }
        },
        { label => 'memory-usage-free', display_ok => 0, nlabel => 'device.memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' },
                    { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { value => 'free', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1 },
                ],
            }
        },
        { label => 'memory-usage-prct', display_ok => 0, nlabel => 'device.memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'Memory Used: %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0, max => 100,
                      unit => '%' },
                ],
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} =~ /error/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(url_path => '/api/v1/mgmt/device/stats');
    if (!defined($result->{data}->{CPU})) {
        $self->{output}->add_option_msg(short_msg => "cannot find device information.");
        $self->{output}->option_exit();
    }

    my $used = $result->{data}->{Memory}->{Used} - $result->{data}->{Memory}->{SReclaim};
    $self->{global} = {
        cpu_average => $result->{data}->{CPU}->{Average},
        total => $result->{data}->{Memory}->{Total},
        free => $result->{data}->{Memory}->{Total} - $used,
        used => $used,
        prct_free => ($result->{data}->{Memory}->{Total} - $used) * 100 / $result->{data}->{Memory}->{Total},
        prct_used => $used * 100 / $result->{data}->{Memory}->{Total}
    };

    $result = $options{custom}->request_api(url_path => '/api/v1/mgmt/pollForStatus');
    return if (!defined($result->{data}->{State}));
    
    $self->{global}->{status} = $result->{data}->{State};
}

1;

__END__

=head1 MODE

Check device cpu, memory and state.

=over 8

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /error/i').
Can used special variables like: %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization-average', 'memory-usage',
'memory-usage-free', 'memory-usage-prct'.

=back

=cut
