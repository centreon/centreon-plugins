#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package cloud::openstack::restapi::mode::loadbalancer;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng catalog_status_calc);
use centreon::plugins::misc qw/flatten_arrays/;

# All filter parameters that can be used
my @_options = qw/include_name
                  exclude_name
                  include_operating_status
                  exclude_operating_status
                  include_provisioning_status
                  exclude_provisioning_status
                  include_admin_state_up
                  exclude_admin_state_up
                  include_vip_address
                  exclude_vip_address
                  include_description
                  exclude_description
                  include_id
                  exclude_id
                  include_provider
                  exclude_provider/;

my @_loadbalancer_keys = qw/id name operating_status provisioning_status admin_state_up
                      vip_address description provider pool_count listener_count
                      project_id/;

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        ( map { ($_ =~ s/_/-/gr).':s@' => { name => $_ } } @_options ),
        'exclude-no-listeners',      => { name => 'exclude_no_listeners' },
        'exclude-no-pools',          => { name => 'exclude_no_pools' },
        'filter-project-id:s'          => { name => 'filter_project_id', default => '' }
    });

    return $self;
}

sub custom_loadbalancer_output {
    my ($self, %options) = @_;
    sprintf('LoadBalancer %s has operating status %s and privisioning status %s',
        $self->{result_values}->{name}, $self->{result_values}->{operating_status}, $self->{result_values}->{provisioning_status});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'loadbalancer', type => 1, message_multiple => 'All load balancers are ok', skipped_code => { -11 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        {   label => 'count', nlabel => 'loadbalancer.count',
            set => {
                key_values => [ { name => 'count' } ],
                output_template => 'LoadBalancer count: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
              }
        }
    ];

    $self->{maps_counters}->{loadbalancer} = [
        {   label => 'operating-status', type => 2,
            critical_default => '%{operating_status} =~ /ERROR/',
            warning_default => '%{operating_status} =~ /DEGRADED|DRAINING|MONITOR/',
            set => {
                key_values => [ map { { name => $_ } } @_loadbalancer_keys, ],
                output_use => 'name',
                output_template => 'LoadBalancer name: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_output => $self->can('custom_loadbalancer_output'),
            },
        },
        (   map {       # define a counter for each other key
                    {   label => $_ =~ s/_/-/gr, type => 2, display_ok => 1,
                        set => {
                            key_values => [ map { { name => $_ } } @_loadbalancer_keys, ],
                            output_use => $_,
                            output_template => ucfirst $_ =~ s/_/-/gr.': %s',
                            closure_custom_threshold_check => \&catalog_status_threshold_ng,
                        },
                    }
                } grep { ! /operating_status|count/ } @_loadbalancer_keys,
        ), (
            map {       # threshold
                    {   label => $_ =~ s/_/-/gr,
                        nlabel => $_ =~ s/_/./gr,
                        type => 1,
                        instance_name => 'tata',
                        instance_use => 'name',
                        instances => 'loadbalancer',
                        set => {
                            key_values => [ { name => $_ }, { name => 'name' } ],
                            perfdatas => [
                                { template => '%d', min => 0, instance_use => 'name', label_extra_instance => 1, }
                            ]
                        },
                    }
                } qw/pool_count listener_count/,

        ),
    ];
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    foreach my $filter (qw/include exclude/) {
        foreach my $value (@{$self->{option_results}->{$filter."_admin_state_up"}}) {
            $self->{output}->option_exit(short_msg => "Invalid --$filter-state-up value: $value (True or False)")
                unless $value =~ /^(true|false)$/i;
        }
    }

    $self->{$_} = flatten_arrays($self->{option_results}->{$_})
        foreach @_options;

    $self->{$_} = $self->{option_results}->{$_}
        foreach qw/filter_project_id exclude_no_pools exclude_no_listeners/;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{loadbalancer} = {};

    # Retry to handle token expiration
    RETRY: for my $retry (1..2) {
        # Don't use the Keystone cache on the second try to force reauthentication
        my $authent = $options{custom}->keystone_authent( dont_read_cache => $retry > 1 );
        $options{custom}->other_services_check_options( keystone_services => $authent->{services} );

        my $loadbalancers = $options{custom}->octavia_list_loadbalancer( project_id => $self->{filter_project_id},
                                                                         exclude_no_pools => $self->{exclude_no_pools},
                                                                         exclude_no_listeners => $self->{exclude_no_listeners},
                                                                         ( map { $_ => $self->{$_} } @_options ) ) ;

        # Retry one time if unauthorized
        next RETRY if $loadbalancers->{http_status} == 401 && $retry == 1;
        $self->{output}->option_exit(short_msg => $loadbalancers->{message})
            if $loadbalancers->{http_status} != 200;

        foreach my $loadbalancer (@{$loadbalancers->{results}}) {
            $self->{loadbalancer}->{$loadbalancer->{id}} = { %$loadbalancer };
        }
        last RETRY;
    }

    $self->{global}->{count} = keys %{$self->{loadbalancer}};
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @_loadbalancer_keys ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(custom => $options{custom});
    foreach my $item ( sort { $a->{project_id} cmp $b->{project_id} ||
                              $a->{name} cmp $b->{name} ||
                              $a->{id} cmp $b->{id} }
                       values %{$self->{loadbalancer}}) {
        $self->{output}->add_disco_entry( map { $_ => $item->{$_} } @_loadbalancer_keys );
    }
}

1;

__END__

=head1 MODE

Manage OpenStack Load Balancers

=over 8

=item B<--filter-project-id>

Filter by OpenStack project id (tenant id).
This filter is applied before any other filters and requires admin rights.
When unset load balancers are filtered based on the project used during authentication.

=item B<--include-name>

Filter by load balancer name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-name>

Exclude by load balancer name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-operating-status>

Filter by load balancer operating status (can be a regexp and can be used multiple times or for comma separated values).
Valid values are: ONLINE, DRAINING, OFFLINE, DEGRADED, ERROR, NO_MONITOR

=item B<--exclude-operating-status>

Exclude by load balancer operating status (can be a regexp and can be used multiple times or for comma separated values).
Valid values are: ONLINE, DRAINING, OFFLINE, DEGRADED, ERROR, NO_MONITOR

=item B<--include-provisioning-status status>

Filter by load balancer provisioning status (can be a regexp and can be used multiple times or for comma separated values).
Valid values are: ACTIVE, ERROR, PENDING_CREATE, PENDING_UPDATE, PENDING_DELETE

=item B<--exclude-privisioning-status status>

Exclude by load balancer provisioning status (can be a regexp and can be used multiple times or for comma separated values).
Valid values are: ACTIVE, ERROR, PENDING_CREATE, PENDING_UPDATE, PENDING_DELETE

=item B<--include-description>

Filter by load balancer description (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-description>

Exclude by load balancer description (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-state-up>

Filter by load balancer state up flag (can be 0 or 1).

=item B<--exclude-state-up>

Exclude by load balancer state up flag (can be true or false).

=item B<--include-vip-address>

Filter by load balancer VIP IP address (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-vip-address>

Exclude by load balancer VIP IP address (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-provider>

Filter by load balancer provider (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-provider>

Exclude by load balancer provider (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-id>

Filter by load balancer ID (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-id>

Exclude by load balancer ID (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-no-listeners>

Exclude load balancer that do not have any listeners (default: 0).
Set to 0 to include them in the list.

=item B<--exclude-no-pools>

Exclude load balancer that do not have any pools (default: 0).
Set to 0 to include them in the list.

=item B<--warning-count>

Warning threshold for the number of load balancers returned.

=item B<--critical-count>

Critical threshold for the number of load balancers returned.

=item B<--warning-pool-count>

Warning threshold for the number of pools per load balancers.

=item B<--critical-pool-count>

Critical threshold for the number of pools per load balancers.

=item B<--warning-listener-count>

Warning threshold for the number of listeners per load balancers.

=item B<--critical-listener-count>

Critical threshold for the number of listeners per load balancers.

=item B<--warning-name>

Define the conditions to match for the status to be WARNING based on the load balancer name.
Example: --critical-name='%{name} =~ /abcd/'

=item B<--critical-name>

Define the conditions to match for the status to be CRITICAL based on the load balancer name.
Example: --critical-name='%{name} =~ /abcd/'

=item B<--warning-operating-status>

Define the conditions to match for the status to be WARNING based on the load balancer operating status.
Valid operating status are: ONLINE, DRAINING, OFFLINE, DEGRADED, ERROR, NO_MONITOR
Example: --warning-operating-status='%{operating_status} =~ /DEGRADED/'
Default: --warning-operating-status='%{operating_status} =~ /DEGRADED|DRAINING|MONITOR/'

=item B<--critical-operating-status>

Define the conditions to match for the status to be CRITICAL based on the load balancer operating status.
Valid operating status are: ONLINE, DRAINING, OFFLINE, DEGRADED, ERROR, NO_MONITOR
Example: --critical-operating-status='%{operating_status} =~ /ERROR/'
Default: --critical-operating-status='%{operating_status} =~ /ERROR/'

=item B<--warning-provisioning-status>

Define the conditions to match for the status to be WARNING based on the load balancer provisioning status.
Valid provisioning status are: ACTIVE, ERROR, PENDING_CREATE, PENDING_UPDATE, PENDING_DELETE
Example: --warning-provisioning-status='%{provisioning_status} =~ /DEGRADED/'

=item B<--critical-provisioning-status>

Define the conditions to match for the status to be CRITICAL based on the load balancer provisioning status.
Valid provisioning status are: ONLINE, DRAINING, OFFLINE, DEGRADED, ERROR, NO_MONITOR
Example: --critical-provisioning-status='%{provisioning_status} =~ /ERROR/'

=item B<--warning-description>

Define the conditions to match for the status to be WARNING based on the load balancer description.
Example: --warning-description='%{description} =~ /test lb/'

=item B<--critical-description>

Define the conditions to match for the status to be CRITICAL based on the load balancer description.
Example: --critical-description='%{description} =~ /test lb/'

=item B<--warning-admin-state-up>

Define the conditions to match for the status to be WARNING based on the admin state up flag (can be true or false).
Example: --warning-state-up='%{admin_state_up} =~ /false/'

=item B<--critical-admin-state-up>

Define the conditions to match for the status to be CRITICAL based on the admin state up flag (can be true or false).
Example: --critical-state-up='%{admin_state_up} =~ /false/'

=item B<--warning-vip-address>

Define the conditions to match for the status to be WARNING based on the VIP Address.
Example: --warning-vip-address='%{vip_address} =~ /127.0.0.1/'

=item B<--critical-vip-address>

Define the conditions to match for the status to be CRITICAL based on the VIP Address.
Example: --critical-vip-addressr='%{vip_address} =~ /127.0.0.1/'

=item B<--warning-provider>

Define the conditions to match for the status to be WARNING based on the provider.
Example: --warning-provider='%{provider} =~ /octavia/'

=item B<--critical-provider>

Define the conditions to match for the status to be CRITICAL based on the provider.
Example: --critical-provider='%{provider} =~ /octavia/'

=item B<--warning-id>

Define the conditions to match for the status to be WARNING based on the load balancer ID.
Example: --warning-id='%{id} =~ /abcdef/'

=item B<--critical-id>

Define the conditions to match for the status to be CRITICAL based on the load balancer ID.
Example: --critical-id='%{id} =~ /abcdef/'

=item B<--warning-project_id>

Define the conditions to match for the status to be WARNING based on the load balancer project ID.
Example: --warning-project-id='%{project-id} =~ /abcdef/'

=item B<--critical-project_id>

Define the conditions to match for the status to be CRITICAL based on the load balancer project ID.
Example: --critical-project-id='%{project-id} =~ /abcdef/'

=back

=cut
