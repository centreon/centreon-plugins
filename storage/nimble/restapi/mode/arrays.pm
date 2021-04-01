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

package storage::nimble::restapi::mode::arrays;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
}

sub prefix_array_output {
    my ($self, %options) = @_;
    
    return "Storage array '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'arrays', type => 1, cb_prefix_output => 'prefix_array_output', message_multiple => 'All storage arrays are ok' }
    ];
    
    $self->{maps_counters}->{arrays} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'space-usage', nlabel => 'array.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-free', nlabel => 'array.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-prct', nlabel => 'array.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'display' } ],
                output_template => 'space used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'snapshots-compression-rate', nlabel => 'array.snapshots.compression.rate.count', display_ok => 0, set => {
                key_values => [ { name => 'snap_compression' }, { name => 'display' } ],
                output_template => 'snapshots compression rate: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'snapshots-space-reduction-rate', nlabel => 'array.snapshots.space.reduction.rate.count', display_ok => 0, set => {
                key_values => [ { name => 'snap_space_reduction' }, { name => 'display' } ],
                output_template => 'snapshots space reduction rate: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
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
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} =~ /unreachable/i' }
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

    my $results = $options{custom}->request_api(endpoint => '/v1/arrays/detail');

    $self->{arrays} = {};
    foreach (@{$results->{data}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping array '" . $_->{name} . "': no matching filter.", debug => 1);
            next;
        }

        my $total = $_->{usage} + $_->{available_bytes};
        $self->{arrays}->{ $_->{name} } = {
            display => $_->{name},
            status => $_->{status},

            total_space => $total,
            used_space => $_->{usage},
            free_space => $_->{available_bytes},
            prct_used_space => $_->{usage} * 100 / $total,
            prct_free_space => $_->{available_bytes} * 100 / $total,

            snap_compression => $_->{snap_compression},
            snap_space_reduction => $_->{snap_space_reduction}
        };
    }
    
    if (scalar(keys %{$self->{arrays}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No storage arrays found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check storage arrays.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--filter-name>

Filter array name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /unreachable/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage' (B), 'space-usage-free' (B), 'space-usage-prct' (%),
'snapshots-compression-rate', 'snapshots-space-reduction-rate'.

=back

=cut
