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

package storage::emc::vplex::restapi::mode::clusterdevices;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'health state: %s',
        $self->{result_values}->{health_state}
    );
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return sprintf(
        "device '%s' [cluster: %s] ",
        $options{instance_value}->{device_name},
        $options{instance_value}->{cluster_name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'devices', type => 1, cb_prefix_output => 'prefix_device_output', message_multiple => 'All devices are ok' }
    ];

    $self->{maps_counters}->{devices} = [
        { label => 'health-status', type => 2, critical_default => '%{health_state} ne "ok"', set => {
                key_values => [ { name => 'health_state' }, { name => 'cluster_name' }, { name => 'device_name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-cluster-name:s' => { name => 'filter_cluster_name' },
        'filter-device-name:s'  => { name => 'filter_device_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $items = $options{custom}->get_devices();

    $self->{devices} = {};
    foreach my $item (@$items) {
        next if (defined($self->{option_results}->{filter_cluster_name}) && $self->{option_results}->{filter_cluster_name} ne '' &&
            $item->{cluster_name} !~ /$self->{option_results}->{filter_cluster_name}/);
        next if (defined($self->{option_results}->{filter_device_name}) && $self->{option_results}->{filter_device_name} ne '' &&
            $item->{name} !~ /$self->{option_results}->{filter_device_name}/);

        $self->{devices}->{ $item->{name} } = $item;
        $self->{devices}->{ $item->{name} }->{device_name} = $item->{name};
    }
}

1;

__END__

=head1 MODE

Check cluster devices.

=over 8

=item B<--filter-cluster-name>

Filter devices by cluster name (can be a regexp).

=item B<--filter-device-name>

Filter devices by device name (can be a regexp).

=item B<--warning-health-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{health_state}, %{cluster_name}, %{device_name}

=item B<--critical-health-status>

Define the conditions to match for the status to be CRITICAL (default: '%{health_state} ne "ok"').
You can use the following variables: %{health_state}, %{cluster_name}, %{device_name}

=back

=cut
