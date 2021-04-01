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

package storage::nimble::restapi::mode::volumes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s [space usage level: %s]',
        $self->{result_values}->{state},
        $self->{result_values}->{space_usage_level}
    );
}

sub prefix_volume_output {
    my ($self, %options) = @_;
    
    return "Volume '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'volumes', type => 1, cb_prefix_output => 'prefix_volume_output', message_multiple => 'All volumes are ok' }
    ];
    
    $self->{maps_counters}->{volumes} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'space_usage_level' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'space-usage', nlabel => 'volume.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'display' } ],
                output_template => 'space used: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', min => 0, unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'read', nlabel => 'volume.io.read.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'read' } ],
                output_template => 'read: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write', nlabel => 'volume.io.write.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'write' } ],
                output_template => 'write: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read-iops', nlabel => 'volume.io.read.usage.iops', set => {
                key_values => [ { name => 'read_iops' } ],
                output_template => 'read iops: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-iops', nlabel => 'volume.io.write.usage.iops', set => {
                key_values => [ { name => 'write_iops' } ],
                output_template => 'write iops: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read-latency', nlabel => 'volume.io.read.latency.milliseconds', set => {
                key_values => [ { name => 'read_latency' } ],
                output_template => 'read latency: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-latency', nlabel => 'volume.io.write.latency.milliseconds', set => {
                key_values => [ { name => 'write_latency' } ],
                output_template => 'write latency: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s'     => { name => 'filter_name' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '%{space_usage_level} =~ /warning/' },
        'critical-status:s' => { name => 'critical_status', default => '%{state} !~ /online/i || %{space_usage_level} =~ /critical/' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(endpoint => '/v1/volumes/detail');

    $self->{volumes} = {};
    foreach (@{$results->{data}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping volume '" . $_->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{volumes}->{ $_->{name} } = {
            display => $_->{name},
            state => $_->{vol_state},
            space_usage_level => $_->{space_usage_level},
            used_space => $_->{total_usage_bytes},
            read => $_->{avg_stats_last_5mins}->{read_throughput},
            write => $_->{avg_stats_last_5mins}->{write_throughput},
            read_iops => $_->{avg_stats_last_5mins}->{read_iops},
            write_iops => $_->{avg_stats_last_5mins}->{write_iops},
            read_latency => $_->{avg_stats_last_5mins}->{read_latency},
            write_latency => $_->{avg_stats_last_5mins}->{write_latency}
        };
    }
    
    if (scalar(keys %{$self->{volumes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No volumes found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check volumes.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--filter-name>

Filter volume name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{state}, %{space_level_usage}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '%{space_usage_level} =~ /warning/').
Can used special variables like: %{state}, %{space_level_usage}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} !~ /online/i || %{space_usage_level} =~ /critical/').
Can used special variables like: %{state}, %{space_level_usage}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage' (B), 'read' (B/s), 'read-iops', 'write' (B/s), 'write-iops',
'read-latency' (ms), 'write-latency' (ms).

=back

=cut
