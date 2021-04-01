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

package database::warp10::sensision::mode::fetchstatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::monitoring::openmetrics::scrape;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'fetchs', type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All fetchs statistics are ok' },
    ];
    
    $self->{maps_counters}->{fetchs} = [
        { label => 'calls-count', nlabel => 'fetch.calls.count', set => {
                key_values => [ { name => 'calls', diff => 1 }, { name => 'display' } ],
                output_template => 'Calls: %d',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'calls-persecond', nlabel => 'fetch.calls.persecond', set => {
                key_values => [ { name => 'calls', per_second => 1 }, { name => 'display' } ],
                output_template => 'Calls (per second): %.2f',
                perfdatas => [
                    { template => '%.2f', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'bytes-values-count', nlabel => 'fetch.bytes.values.bytes', set => {
                key_values => [ { name => 'bytes_values', diff => 1 }, { name => 'display' } ],
                output_template => 'Bytes Values: %s%s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'bytes-values-persecond', nlabel => 'fetch.bytes.values.bytespersecond', set => {
                key_values => [ { name => 'bytes_values', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 1,
                output_template => 'Bytes Values (per second): %s%s/s',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'bytes-keys-count', nlabel => 'fetch.bytes.keys.bytes', set => {
                key_values => [ { name => 'bytes_keys', diff => 1 }, { name => 'display' } ],
                output_template => 'Bytes Keys: %s%s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'bytes-keys-persecond', nlabel => 'fetch.bytes.keys.bytespersecond', set => {
                key_values => [ { name => 'bytes_keys', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 1,
                output_template => 'Bytes Keys (per second): %s%s/s',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'datapoints-count', nlabel => 'fetch.datapoints.count', set => {
                key_values => [ { name => 'datapoints', diff => 1 }, { name => 'display' } ],
                output_template => 'Datapoints: %d',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'datapoints-persecond', nlabel => 'fetch.datapoints.persecond', set => {
                key_values => [ { name => 'datapoints', per_second => 1 }, { name => 'display' } ],
                output_template => 'Datapoints (per second): %.2f',
                perfdatas => [
                    { template => '%.2f', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;
    
    return "Fetch '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "warp10_" . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    $self->{metrics} = centreon::common::monitoring::openmetrics::scrape::parse(%options);

    foreach my $fetch (@{$self->{metrics}->{'warp.fetch.count'}->{data}}) {
        $self->{fetchs}->{$fetch->{dimensions}->{app}}->{calls} = $fetch->{value};
        $self->{fetchs}->{$fetch->{dimensions}->{app}}->{display} = $fetch->{dimensions}->{app};
    }
    foreach my $fetch (@{$self->{metrics}->{'warp.fetch.bytes.values'}->{data}}) {
        $self->{fetchs}->{$fetch->{dimensions}->{app}}->{bytes_values} = $fetch->{value};
        $self->{fetchs}->{$fetch->{dimensions}->{app}}->{display} = $fetch->{dimensions}->{app};
    }
    foreach my $fetch (@{$self->{metrics}->{'warp.fetch.bytes.keys'}->{data}}) {
        $self->{fetchs}->{$fetch->{dimensions}->{app}}->{bytes_keys} = $fetch->{value};
        $self->{fetchs}->{$fetch->{dimensions}->{app}}->{display} = $fetch->{dimensions}->{app};
    }
    foreach my $fetch (@{$self->{metrics}->{'warp.fetch.datapoints'}->{data}}) {
        $self->{fetchs}->{$fetch->{dimensions}->{app}}->{datapoints} = $fetch->{value};
        $self->{fetchs}->{$fetch->{dimensions}->{app}}->{display} = $fetch->{dimensions}->{app};
    }

    foreach (keys %{$self->{fetchs}}) {
        delete $self->{fetchs}->{$_} if (defined($self->{option_results}->{filter_name}) &&
            $self->{option_results}->{filter_name} ne '' &&
            $_ !~ /$self->{option_results}->{filter_name}/);
    }
    
    if (scalar(keys %{$self->{fetchs}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No fetchs found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check fetchs statistics.

=over 8

=item B<--filter-name>

Filter app name (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='calls'

=item B<--warning-*-count/persecond>

Threshold warning.
Can be: 'calls', 'bytes-values', 'bytes-keys'.

=item B<--critical-*-count/persecond>

Threshold critical.
Can be: 'calls', 'bytes-values', 'bytes-keys'.

=back

=cut
