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

package storage::emc::vplex::restapi::mode::fans;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_fan_output {
    my ($self, %options) = @_;

    return sprintf(
        "fan '%s' [engine: %s] ",
        $options{instance_value}->{fan_name},
        $options{instance_value}->{engine_id}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'fans', type => 1, cb_prefix_output => 'prefix_fan_output', message_multiple => 'All fans are ok' }
    ];

    $self->{maps_counters}->{fans} = [
        { label => 'operational-status', type => 2, critical_default => '%{operational_status} ne "online"', set => {
                key_values => [ { name => 'operational_status' }, { name => 'engine_id' }, { name => 'fan_name' } ],
                output_template => 'operational status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'speed-status', type => 2, critical_default => '%{speed_threshold_exceeded} ne "false"', set => {
                key_values => [ { name => 'speed_threshold_exceeded' }, { name => 'engine_id' }, { name => 'fan_name' } ],
                output_template => 'speed threshold exceeded: %s',
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
        'filter-engine-id:s' => { name => 'filter_engine_id' },
        'filter-fan-name:s'  => { name => 'filter_fan_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $items = $options{custom}->get_fans();

    $self->{fans} = {};
    foreach my $item (@$items) {
        next if (defined($self->{option_results}->{filter_engine_id}) && $self->{option_results}->{filter_engine_id} ne '' &&
            $item->{engine_id} !~ /$self->{option_results}->{filter_engine_id}/);
        next if (defined($self->{option_results}->{filter_fan_name}) && $self->{option_results}->{filter_fan_name} ne '' &&
            $item->{name} !~ /$self->{option_results}->{filter_fan_name}/);

        $self->{fans}->{ $item->{name} } = $item;
        $self->{fans}->{ $item->{name} }->{fan_name} = $item->{name};
    }
}

1;

__END__

=head1 MODE

Check fans.

=over 8

=item B<--filter-engine-id>

Filter fans by engine ID (can be a regexp).

=item B<--filter-fan-name>

Filter fans by fan name (can be a regexp).

=item B<--warning-operational-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{operational_status}, %{engine_id}, %{fan_name}

=item B<--critical-operational-status>

Define the conditions to match for the status to be CRITICAL (default: '%{operational_status} ne "online"').
You can use the following variables: %{operational_status}, %{engine_id}, %{fan_name}

=item B<--warning-speed-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{speed_threshold_exceeded}, %{engine_id}, %{fan_name}

=item B<--critical-speed-status>

Define the conditions to match for the status to be CRITICAL (default: '%{operational_status} ne "online"').
You can use the following variables: %{speed_threshold_exceeded}, %{engine_id}, %{fan_name}

=back

=cut
