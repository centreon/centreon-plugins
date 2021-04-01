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

package storage::oracle::zs::restapi::mode::pools;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status : ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    my $msg = sprintf('space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'pool', type => 1, cb_prefix_output => 'prefix_pool_output', message_multiple => 'All pools are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{pool} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'usage', nlabel => 'pool.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'used_space', template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'usage-free', nlabel => 'pool.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'free_space', template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'usage-prct', nlabel => 'pool.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'display' } ],
                output_template => 'used : %.2f %%',
                perfdatas => [
                    { value => 'prct_used_space', template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
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
        'critical-status:s' => { name => 'critical_status', default => '%{status} !~ /online|exported/i' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

sub prefix_pool_output {
    my ($self, %options) = @_;
    
    return "Pool '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(url_path => '/api/storage/v1/pools');

    $self->{pool} = {};
    foreach (@{$results->{pools}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping pool '" . $_->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{pool}->{$_->{name}} = {
            display => $_->{name},
            status => $_->{status},
            total_space => $_->{usage}->{total},
            used_space => $_->{usage}->{used},
            free_space => $_->{usage}->{free},
            prct_used_space => 
                defined($_->{usage}->{total}) ? ($_->{usage}->{used} * 100 / $_->{usage}->{total}) : undef,
            prct_free_space => 
                defined($_->{usage}->{total}) ? ($_->{usage}->{free} * 100 / $_->{usage}->{total}) : undef,
        };
    }
    
    if (scalar(keys %{$self->{pool}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No pool found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check pool usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^usage$'

=item B<--filter-name>

Filter pool name (can be a regexp).

=item B<--unknown-status>

Set unknon threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /online|exported/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
