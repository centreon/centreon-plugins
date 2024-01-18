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

package network::aruba::orchestrator::restapi::mode::appliances;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_appliance_output {
    my ($self, %options) = @_;

    return sprintf(
        "appliance '%s' [group: %s] ",
        $options{instance_value}->{hostname},
        $options{instance_value}->{group}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'appliances', type => 1, cb_prefix_output => 'prefix_appliance_output', message_multiple => 'All appliances are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'appliances-detected', nlabel => 'appliances.detected.count', set => {
                key_values => [ { name => 'num_appliances' } ],
                output_template => 'appliances detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{appliances} = [
        {
            label => 'status',
            type => 2,
            unknown_default => '%{state} =~ /unknown|unreachable/i',
            warning_default => '%{state} =~ /unsupportedVersion|outOfSynchronization/i',
            set => {
                key_values => [
                    { name => 'state' }, { name => 'hostname' }
                ],
                output_template => "state: %s",
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
        'filter-hostname:s' => { name => 'filter_hostname' },
        'filter-group:s'    => { name => 'filter_group' }
    });

    return $self;
}

sub get_groups {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(
        endpoint => '/gms/group'
    );
    my $groups = {};
    foreach (@$results) {
        $groups->{ $_->{id} } = { name => $_->{name}, parentId => $_->{parentId} }; 
    }

    return $groups;
}

sub get_group {
    my ($self, %options) = @_;

    my @groups = ();
    my $groupId = $options{groupId};
    while (defined($groupId)) {
        unshift(@groups, $options{groups}->{$groupId}->{name});
        $groupId = $options{groups}->{$groupId}->{parentId};
    }

    return join(' > ', @groups);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $map_state = {
        0 => 'unknown', 1 => 'normal', 2 => 'unreachable',
        3 => 'unsupportedVersion', 4 => 'outOfSynchronization', 5 => 'synchronizationInProgress'
    };

    my $appliances = $options{custom}->request_api(endpoint => '/appliance');
    my $groups = $self->get_groups(custom => $options{custom});

    $self->{global} = { num_appliances => 0 };
    $self->{appliances} = {};
    foreach my $appliance (@$appliances) {
        next if (defined($self->{option_results}->{filter_hostname}) && $self->{option_results}->{filter_hostname} ne '' &&
            $appliance->{hostName} !~ /$self->{option_results}->{filter_hostname}/);

        my $group = $self->get_group(groups => $groups, groupId => $appliance->{groupId});
        next if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '' &&
            $group !~ /$self->{option_results}->{filter_group}/);

        $self->{global}->{num_appliances}++;
        $self->{appliances}->{ $appliance->{uuid} } = {
            hostname => $appliance->{hostName},
            group => $group,
            state => $map_state->{ $appliance->{state} }
        };
    }
}

1;

__END__

=head1 MODE

Check appliances.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--filter-hostname>

Filter appliances by hostname.

=item B<--filter-group>

Filter appliances by group.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{state} =~ /unknown|unreachable/i').
You can use the following variables: %{state}, %{hostname}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{state} =~ /unsupportedVersion|outOfSynchronization/i').
You can use the following variables: %{state}, %{hostname}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{hostname}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'appliances-detected'.

=back

=cut
