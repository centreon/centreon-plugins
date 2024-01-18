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

package storage::emc::vplex::restapi::mode::directors;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_director_output {
    my ($self, %options) = @_;

    return sprintf(
        "director '%s' [engine: %s] ",
        $options{instance_value}->{director_name},
        $options{instance_value}->{engine_id}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'directors', type => 1, cb_prefix_output => 'prefix_director_output', message_multiple => 'All directors are ok' }
    ];

    $self->{maps_counters}->{directors} = [
        { label => 'health-status', type => 2, critical_default => '%{health_state} ne "ok"', set => {
                key_values => [ { name => 'health_state' }, { name => 'engine_id' }, { name => 'director_name' } ],
                output_template => 'health state: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'communication-status', type => 2, critical_default => '%{communication_status} ne "ok"', set => {
                key_values => [ { name => 'communication_status' }, { name => 'engine_id' }, { name => 'director_name' } ],
                output_template => 'communication status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'temperature-status', type => 2, critical_default => '%{temperature_threshold_exceeded} ne "false"', set => {
                key_values => [ { name => 'temperature_threshold_exceeded' }, { name => 'engine_id' }, { name => 'director_name' } ],
                output_template => 'temperature threshold exceeded: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'voltage-status', type => 2, critical_default => '%{voltage_threshold_exceeded} ne "false"', set => {
                key_values => [ { name => 'voltage_threshold_exceeded' }, { name => 'engine_id' }, { name => 'director_name' } ],
                output_template => 'voltage threshold exceeded: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'vplex-kdriver-status', type => 2, critical_default => '%{vplex_kdriver_status} ne "ok"', set => {
                key_values => [ { name => 'vplex_kdriver_status' }, { name => 'engine_id' }, { name => 'director_name' } ],
                output_template => 'vplex kdriver status: %s',
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
        'filter-engine-id:s'     => { name => 'filter_engine_id' },
        'filter-director-name:s' => { name => 'filter_director_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $items = $options{custom}->get_directors();

    $self->{directors} = {};
    foreach my $item (@$items) {
        next if (defined($self->{option_results}->{filter_engine_id}) && $self->{option_results}->{filter_engine_id} ne '' &&
            $item->{engine_id} !~ /$self->{option_results}->{filter_engine_id}/);
        next if (defined($self->{option_results}->{filter_director_name}) && $self->{option_results}->{filter_director_name} ne '' &&
            $item->{name} !~ /$self->{option_results}->{filter_director_name}/);

        $self->{directors}->{ $item->{name} } = $item;
        $self->{directors}->{ $item->{name} }->{director_name} = $item->{name};
        $self->{directors}->{ $item->{name} }->{temperature_threshold_exceeded} = 
            $self->{directors}->{ $item->{name} }->{temperature_threshold_exceeded} =~ /^(?:true|1)$/i ? 'true' : 'false';
        $self->{directors}->{ $item->{name} }->{voltage_threshold_exceeded} = 
            $self->{directors}->{ $item->{name} }->{voltage_threshold_exceeded} =~ /^(?:true|1)$/i ? 'true' : 'false';
    }
}

1;

__END__

=head1 MODE

Check directors.

=over 8

=item B<--filter-engine-id>

Filter directors by engine ID (can be a regexp).

=item B<--filter-director-name>

Filter directors by director name (can be a regexp).

=item B<--warning-health-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{operational_status}, %{engine_id}, %{director_name}

=item B<--critical-health-status>

Define the conditions to match for the status to be CRITICAL (default: '%{health_state} ne "ok"').
You can use the following variables: %{operational_status}, %{engine_id}, %{director_name}

=item B<--warning-communication-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{communication_status}, %{engine_id}, %{director_name}

=item B<--critical-communication-status>

Define the conditions to match for the status to be CRITICAL (default: '%{communication_status} ne "ok"').
You can use the following variables: %{communication_status}, %{engine_id}, %{director_name}

=item B<--warning-temperature-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{temperature_threshold_exceeded}, %{engine_id}, %{director_name}

=item B<--critical-temperature-status>

Define the conditions to match for the status to be CRITICAL (default: '%{temperature_threshold_exceeded} ne "false"').
You can use the following variables: %{temperature_threshold_exceeded}, %{engine_id}, %{director_name}

=item B<--warning-voltage-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{voltage_threshold_exceeded}, %{engine_id}, %{director_name}

=item B<--critical-voltage-status>

Define the conditions to match for the status to be CRITICAL (default: '%{voltage_threshold_exceeded} ne "false"').
You can use the following variables: %{voltage_threshold_exceeded}, %{engine_id}, %{director_name}

=item B<--warning-vplex-kdriver-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{vplex_kdriver_status}, %{engine_id}, %{director_name}

=item B<--critical-vplex-kdriver-status>

Define the conditions to match for the status to be CRITICAL (default: '%{vplex_kdriver_status} ne "ok"').
You can use the following variables: %{vplex_kdriver_status}, %{engine_id}, %{director_name}

=back

=cut
