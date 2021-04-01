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

package storage::netapp::santricity::restapi::mode::storagesystems;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

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
    my $msg = sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
    return $msg;
}

sub prefix_ss_output {
    my ($self, %options) = @_;

    return "storage system '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'ss', type => 1, cb_prefix_output => 'prefix_ss_output',  message_multiple => 'All storage systems are ok' }
    ];
    
    $self->{maps_counters}->{ss} = [
        { label => 'status', type => 2, critical_default => '%{status} =~ /needsAttn/i', set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'usage', nlabel => 'pool.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'used_space', template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-free', nlabel => 'pool.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'free_space', template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-prct', nlabel => 'pool.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'display' } ],
                output_template => 'used : %.2f %%',
                perfdatas => [
                    { value => 'prct_used_space', template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1 }
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
        'filter-storage-name:s' => { name => 'filter_storage_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->execute_storages_request();

    $self->{ss} = {};
    foreach (@{$results->{storages}}) {
        my $storage_name = $_->{name};

        next if (defined($options{filter_storage_name}) && $options{filter_storage_name} ne '' &&
            $storage_name !~ /$options{filter_storage_name}/);

        $self->{ss}->{$storage_name} = {
            display => $_->{name},
            status => $_->{status},
            total_space => $_->{usedPoolSpace} + $_->{freePoolSpace},
            used_space => $_->{usedPoolSpace},
            free_space => $_->{freePoolSpace},
            prct_used_space => 
                ($_->{usedPoolSpace} * 100 / ($_->{usedPoolSpace} + $_->{freePoolSpace})),
            prct_free_space => 
                ($_->{freePoolSpace} * 100 / ($_->{usedPoolSpace} + $_->{freePoolSpace}))
        };
    }
}

1;

__END__

=head1 MODE

Check storage systems.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--filter-storage-name>

Filter storage name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{state}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /needsAttn/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
