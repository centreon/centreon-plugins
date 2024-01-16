#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::ceph::restapi::mode::pools;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5;

sub custom_space_usage_output {
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

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of pools ';
}

sub prefix_pool_output {
    my ($self, %options) = @_;

    return "Pool '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'pools', type => 1, cb_prefix_output => 'prefix_pool_output', message_multiple => 'All pools are ok', skipped_code => { -10 => 1, -11 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'pools-detected', nlabel => 'pools.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{pools} = [
        { label => 'pool-space-usage', nlabel => 'pool.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'pool-space-usage-free', nlabel => 'pool.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'pool-space-usage-prct', nlabel => 'pool.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'pool-read', nlabel => 'pool.read.usage.bytespersecond', set => {
                key_values => [ { name => 'read', per_second => 1 } ],
                output_template => 'read: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'pool-write', nlabel => 'pool.write.usage.bytespersecond', set => {
                key_values => [ { name => 'write', per_second => 1 } ],
                output_template => 'write: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $health = $options{custom}->request_api(endpoint => '/api/health/full');

    $self->{global} = { detected => 0 };
    $self->{pools} = {};
    foreach my $pool (@{$health->{df}->{pools}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $pool->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $pool->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{global}->{detected}++;

        my $total = $pool->{stats}->{avail_raw} + $pool->{stats}->{bytes_used};
        $self->{pools}->{ $pool->{name} } = { 
            total_space => $total,
            used_space => $pool->{stats}->{bytes_used},
            free_space => $pool->{stats}->{avail_raw},
            prct_used_space => $pool->{stats}->{bytes_used} * 100 / $total,
            prct_free_space => $pool->{stats}->{avail_raw} * 100 / $total,
            read => $pool->{stats}->{rd_bytes},
            write => $pool->{stats}->{wr_bytes}
        };
    }

    $self->{cache_name} = 'ceph_' . $self->{mode} .
        Digest::MD5::md5_hex(
            $options{custom}->get_connection_info() . '_' .
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : 'all') . '_' .
            (defined($self->{option_results}->{filter_name}) ? $self->{option_results}->{filter_name} : 'all')
        );
}

1;

__END__

=head1 MODE

Check pools.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='detected'

=item B<--filter-name>

Filter pools by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'pools-detected',
'pool-space-usage', 'pool-space-usage-free', 'pool-space-usage-prct',
'pool-read', 'pool-write'.

=back

=cut
