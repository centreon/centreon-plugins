#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::atlassian::statuspage::mode::components;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_component_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub prefix_component_output {
    my ($self, %options) = @_;

    return "Component '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'components', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_component_output', message_multiple => 'All components are ok' }
    ];

    $self->{maps_counters}->{components} = [
        {
            label => 'status',
            type => COUNTER_KIND_TEXT,
            warningd_default => '%{status} =~ /degraded_performance|partial_outage/',
            critical_default => '%{status} =~ /major_outage/',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'name' }
                ],
                closure_custom_output => $self->can('custom_component_status_output'),
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
       'filter-component-id:s'   => { name => 'filter_component_id' },
       'filter-component-name:s' => { name => 'filter_component_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_components();

    $self->{components} = {};
    foreach (@{$results->{components}}) {
        next if (defined($self->{option_results}->{filter_component_id}) && $self->{option_results}->{filter_component_id} ne '' &&
            $_->{id} !~ /$self->{option_results}->{filter_component_id}/);
        next if (defined($self->{option_results}->{filter_component_name}) && $self->{option_results}->{filter_component_name} ne '' &&
            $_->{name} !~ /$self->{option_results}->{filter_component_name}/);

        $self->{components}->{ $_->{id} } = {
            name => $_->{name},
            status => $_->{status}
        };
    }
}

1;

__END__

=head1 MODE

Check components.

=over 8

=item B<--filter-component-id>

Filter components by ID (can be a regexp).

=item B<--filter-component-name>

Filter components by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{name}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /degraded_performance|partial_outage/').
You can use the following variables: %{status}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /major_outage/').
You can use the following variables: %{status}, %{name}

=back

=cut
