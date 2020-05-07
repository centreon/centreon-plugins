#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package storage::netapp::santricity::restapi::mode::storagepools;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s [raid status: %s]',
        $self->{result_values}->{state},
        $self->{result_values}->{raid_status}
    );
}

sub ss_long_output {
    my ($self, %options) = @_;

    return "checking storage system '" . $options{instance_value}->{display} . "'";
}

sub prefix_ss_output {
    my ($self, %options) = @_;

    return "storage system '" . $options{instance_value}->{display} . "' ";
}

sub prefix_pool_output {
    my ($self, %options) = @_;

    return "pool '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'ss', type => 3, cb_prefix_output => 'prefix_ss_output', cb_long_output => 'ss_long_output', indent_long_output => '    ', message_multiple => 'All storage systems are ok',
            group => [
                { name => 'pools', display_long => 1, cb_prefix_output => 'prefix_pool_output',  message_multiple => 'pools are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{pools} = [
        { label => 'pool-status', threshold => 0, set => {
                key_values => [ { name => 'raid_status' }, { name => 'state'}, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-storage-name:s'  => { name => 'filter_storage_name' },
        'filter-pool-name:s'     => { name => 'filter_pool_name' },
        'unknown-pool-status:s'  => { name => 'unknown_pool_status', default => '' },
        'warning-pool-status:s'  => { name => 'warning_pool_status', default => '%{raid_status} =~ /degraded/i' },
        'critical-pool-status:s' => { name => 'critical_pool_status', default => '%{raid_status} =~ /failed/i' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_pool_status', 'critical_pool_status', 'unknown_pool_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->execute_storages_request(
        endpoints => [ { endpoint => '/storage-pools' } ],
        filter_name => $self->{option_results}->{filter_storage_name}
    );

    $self->{ss} = {};
    foreach (@{$results->{storages}}) {
        my $storage_name = $_->{name};

        $self->{ss}->{$storage_name} = {
            display => $storage_name,
            pools => {}
        };

        next if (!defined($_->{'/storage-pools'}));

        foreach my $entry (@{$_->{'/storage-pools'}}) {

            next if (defined($self->{option_results}->{filter_pool_name}) && $self->{option_results}->{filter_pool_name} ne '' &&
                $entry->{name} !~ /$self->{option_results}->{filter_pool_name}/);

            $self->{ss}->{$storage_name}->{pools}->{ $entry->{name} } = {
                display => $entry->{name},
                state => $entry->{state},
                raid_status => $entry->{raidStatus}
            };
        }
    }
}

1;

__END__

=head1 MODE

Check storage pools.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^pool-status$'

=item B<--filter-storage-name>

Filter storage name (can be a regexp).

=item B<--filter-pool-name>

Filter pool name (can be a regexp).

=item B<--unknown-pool-status>

Set unknown threshold for status.
Can used special variables like: %{raid_status}, %{state}, %{display}

=item B<--warning-pool-status>

Set warning threshold for status (Default: '%{raid_status} =~ /degraded/i').
Can used special variables like: %{raid_status}, %{state}, %{display}

=item B<--critical-pool-status>

Set critical threshold for status (Default: '%{raid_status} =~ /failed/i').
Can used special variables like: %{raid_status}, %{state}, %{display}

=back

=cut
