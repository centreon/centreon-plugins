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

package storage::netapp::santricity::restapi::mode::storagevolumes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space_absolute});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space_absolute});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space_absolute});
    my $msg = sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space_absolute},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space_absolute}
    );
    return $msg;
}

sub ss_long_output {
    my ($self, %options) = @_;

    return "checking storage system '" . $options{instance_value}->{display} . "'";
}

sub prefix_ss_output {
    my ($self, %options) = @_;

    return "storage system '" . $options{instance_value}->{display} . "' ";
}

sub prefix_volume_output {
    my ($self, %options) = @_;

    return "volume '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'ss', type => 3, cb_prefix_output => 'prefix_ss_output', cb_long_output => 'ss_long_output', indent_long_output => '    ', message_multiple => 'All storage systems are ok',
            group => [
                { name => 'volumes', display_long => 1, cb_prefix_output => 'prefix_volume_output',  message_multiple => 'volumes are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{volumes} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
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
        'filter-storage-name:s'    => { name => 'filter_storage_name' },
        'filter-volume-name:s'     => { name => 'filter_volume_name' },
        'unknown-volyme-status:s'  => { name => 'unknown_volume_status', default => '' },
        'warning-volume-status:s'  => { name => 'warning_volume_status', default => '%{status} =~ /degraded/i' },
        'critical-volume-status:s' => { name => 'critical_volume_status', default => '%{status} =~ /failed/i' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_volume_status', 'critical_volume_status', 'unknown_volume_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->execute_storages_request(
        endpoint => '/storage-volumes',
        filter_name => $self->{option_results}->{filter_storage_name}
    );

    $self->{ss} = {};
    foreach (@{$results->{storages}}) {
        my $storage_name = $_->{name};

        $self->{ss}->{$storage_name} = {
            display => $storage_name,
            volumes => {}
        };

        next if (!defined($_->{'/storage-volumes'}));

        foreach my $entry (@{$_->{'/storage-volumes'}}) {

            next if (defined($options{filter_volume_name}) && $options{filter_volume_name} ne '' &&
                $entry->{name} !~ /$options{filter_volume_name}/);

            $self->{ss}->{$storage_name}->{volumes}->{ $entry->{name} } = {
                display => $entry->{name},
                status => $entry->{status}
            };
        }
    }
}

1;

__END__

=head1 MODE

Check storage volumes.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='volume-status'

=item B<--filter-storage-name>

Filter storage name (can be a regexp).

=item B<--filter-volume-name>

Filter volume name (can be a regexp).

=item B<--unknown-volume-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--warning-volume-status>

Set warning threshold for status (Default: '%{status} =~ /degraded/i').
Can used special variables like: %{status}, %{display}

=item B<--critical-volume-status>

Set critical threshold for status (Default: '%{status} =~ /failed/i').
Can used special variables like: %{status}, %{display}

=back

=cut
