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

package storage::emc::vplex::restapi::mode::clustercommunication;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'operational state: %s [admin: %s]',
        $self->{result_values}->{operational_state},
        $self->{result_values}->{admin_state}
    );
}

sub prefix_component_output {
    my ($self, %options) = @_;

    return "Cluster witness component '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'components', type => 1, cb_prefix_output => 'prefix_component_output', message_multiple => 'All cluster witness components are ok' }
    ];

    $self->{maps_counters}->{components} = [
        { label => 'operational-status', type => 2, critical_default => '%{admin_state} eq "enabled" and %{operational_state} !~ /cluster-in-contact|in-contact/i', set => {
                key_values => [ { name => 'operational_state' }, { name => 'admin_state' }, { name => 'name' } ],
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
        'filter-component-name:s' => { name => 'filter_component_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $items = $options{custom}->get_cluster_communication();

    $self->{components} = {};
    foreach my $item (@$items) {
        next if (defined($self->{option_results}->{filter_component_name}) && $self->{option_results}->{filter_component_name} ne '' &&
            $item->{name} !~ /$self->{option_results}->{filter_component_name}/);

        $self->{components}->{ $item->{name} } = $item;
    }
}

1;

__END__

=head1 MODE

Check cluster communication state.

=over 8

=item B<--filter-component-name>

Filter components by name (can be a regexp).

=item B<--warning-operational-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{operational_state}, %{admin_state}, %{name}

=item B<--critical-operational-status>

Define the conditions to match for the status to be CRITICAL (default: '%{admin_state} eq "enabled" and %{operational_state} !~ /cluster-in-contact|in-contact/i').
You can use the following variables: %{operational_state}, %{admin_state}, %{name}

=back

=cut
