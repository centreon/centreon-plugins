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

package cloud::openstack::restapi::mode::network;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng catalog_status_calc);
use centreon::plugins::misc qw/flatten_arrays/;

# All filter parameters that can be used
my @_options = qw/include_name
                  exclude_name
                  include_status
                  exclude_status
                  include_admin_state_up
                  exclude_admin_state_up
                  include_shared
                  exclude_shared
                  include_port_security_enabled
                  exclude_port_security_enabled
                  include_id
                  exclude_id
                  include_router_external
                  exclude_router_external/;

my @_network_keys = qw/id status name admin_state_up shared port_security_enabled router_external project_id/;

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        ( map { ($_ =~ s/_/-/gr).':s@' => { name => $_ } } @_options ),

        'filter-project-id:s'          => { name => 'filter_project_id', default => '' }
    });

    return $self;
}

sub custom_network_output {
    my ($self, %options) = @_;
    sprintf('Network %s is in %s state',
        $self->{result_values}->{name}, $self->{result_values}->{status});
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'network', type => 1, message_multiple => 'All networks are ok', skipped_code => { -11 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        {   label => 'count', nlabel => 'network.count',
            set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Network count: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
              }
        }
    ];

    $self->{maps_counters}->{network} = [
        {   label => 'status', type => 2,
            critical_default => '%{status} !~ /ACTIVE/',
            #  ACTIVE, BUILD, DOWN, or ERROR
            set => {
                key_values => [ map { { name => $_ } } @_network_keys, ],
                output_use => 'name',
                output_template => 'Network name: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_output => $self->can('custom_network_output'),
            },
        },
        (   map {       # define a counter for each other key
                    {   label => $_ =~ s/_/-/gr, type => 2, display_ok => 1,
                        set => {
                            key_values => [ map { { name => $_ } } @_network_keys, ],
                            output_use => $_,
                            output_template => ucfirst $_ =~ s/_/-/gr.': %s',
                            closure_custom_threshold_check => \&catalog_status_threshold_ng,
                        },
                    }
                } grep { ! /name|status/ } @_network_keys
        ),
    ];
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    $self->{$_} = flatten_arrays($self->{option_results}->{$_})
        foreach @_options;

    $self->{filter_project_id} = $self->{option_results}->{filter_project_id};
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{network} = {};

    # Retry to handle token expiration
    RETRY: for my $retry (1..2) {
        # Don't use the Keystone cache on the second try to force reauthentication
        my $authent = $options{custom}->keystone_authent( dont_read_cache => $retry > 1 );
        $options{custom}->other_services_check_options( keystone_services => $authent->{services} );

        my $networks = $options{custom}->neutron_list_networks( project_id => $self->{filter_project_id},
                                                         ( map { $_ => $self->{$_} } @_options ) ) ;

        # Retry one time if unauthorized
        next RETRY if $networks->{http_status} == 401 && $retry == 1;
        $self->{output}->option_exit(short_msg => $networks->{message})
            if $networks->{http_status} != 200;

        foreach my $network (@{$networks->{results}}) {
            $self->{network}->{$network->{id}} = { %$network };
        }
        last RETRY;
    }

    $self->{global}->{count} = keys %{$self->{network}};
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @_network_keys ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(custom => $options{custom});
    foreach my $item ( sort { $a->{project_id} cmp $b->{project_id} ||
                              $a->{name} cmp $b->{name} ||
                              $a->{id} cmp $b->{id} }
                       values %{$self->{network}}) {
        $self->{output}->add_disco_entry( map { $_ => $item->{$_} } @_network_keys );
    }
}

1;

__END__

=head1 MODE

Manage OpenStack Networks

=over 8

=item B<--filter-project-id>

Filter by OpenStack project id (tenant id).
This filter is applied before any other filters and requires admin rights.
When unset networks are filtered based on the project used during authentication.

=item B<--include-name>

Filter by network name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-name>

Exclude by network name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-status>

Filter by network status (can be a regexp and can be used multiple times or for comma separated values).
Can be:  ACTIVE, BUILD, DOWN, or ERROR.

=item B<--exclude-status>

Exclude by network status (can be a regexp and can be used multiple times or for comma separated values).
Can be:  ACTIVE, BUILD, DOWN, or ERROR.

=item B<--include-admin-state-up>

Filter by network admin state up flag (can be 0 or 1).

=item B<--exclude-admin-state-up

Exclude by network admin state up flag (can be 0 or 1).

=item B<--include-shared>

Filter by network shared flag (can be 0 or 1).

=item B<--exclude-shared>

Exclude by network shared flag (can be 0 or 1).

=item B<--include-port-security-enabled>

Filter by network port security enabled flag (can be 0 or 1).

=item B<--exclude-port-security-enabled>

Exclude by network port security enabled flag (can be 0 or 1).

=item B<--include-router-external>

Filter by network router external flag (can be 0 or 1).

=item B<--exclude-router-external>

Exclude by network router external flag (can be 0 or 1).

=item B<--include-id>

Filter by network ID (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-id>

Exclude by network ID (can be a regexp and can be used multiple times or for comma separated values).

=item B<--warning-count>

Warning threshold for the number of networks returned.

=item B<--critical-count>

Critical threshold for the number of networks returned.

=item B<--warning-name>

Define the conditions to match for the status to be WARNING based on the network name.
Example: --warning-name='%{name} =~ /test network/'

=item B<--critical-name>

Define the conditions to match for the status to be CRITICAL based on the network name.
Example: --critical-name='%{name} =~ /test network/'

=item B<--warning-status>

Define the conditions to match for the status to be WARNING based on the network status.
Status can be:  ACTIVE, BUILD, DOWN, or ERROR.
Example: --warning-status='%{status} =~ /DOWN/'

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL based on the network status.
Status can be:  ACTIVE, BUILD, DOWN, or ERROR.
Example: --critical-status='%{status} =~ /ERROR/'
Default: --critical-status='%{status} !~ /ACTIVE/'

=item B<--warning-admin-state-up>

Define the conditions to match for the status to be WARNING based on the admin stat up flag (can be 0 or 1).
Example: --warning-admin-state-up='%{admin_state_up} eq "1"'

=item B<--critical-admin-state-up>

Define the conditions to match for the status to be CRITICAL based on the admin state up flag (can be 0 or 1).
Example: --warning-admin-state-up='%{admin_state_up} eq "1"'

=item B<--warning-shared>

Define the conditions to match for the status to be WARNING based on the shared flag (can be 0 or 1).
Example: --warning-shared='%{shared} eq "1"'

=item B<--critical-shared>

Define the conditions to match for the status to be CRITICAL based on the shared flag (can be 0 or 1).
Example: --warning-shared='%{shared} eq "1"'

=item B<--warning-port-security-enabled>

Define the conditions to match for the status to be WARNING based on the port-security-enabled flag (can be 0 or 1).
Example: --warning-port-security-enabled='%{port_security_enabled} eq "1"'

=item B<--critical-port-security-enabled>

Define the conditions to match for the status to be CRITICAL based on the port-security-enabled flag (can be 0 or 1).
Example: --warning-port-security-enabled='%{port_security_enabled} eq "1"'

=item B<--warning-router-external>

Define the conditions to match for the status to be WARNING based on the router-external flag (can be 0 or 1).
Example: --warning-router-external='%{router_external} eq "1"'

=item B<--critical-router-external>

Define the conditions to match for the status to be CRITICAL based on the router-external flag (can be 0 or 1).
Example: --warning-router-external='%{router_external} eq "1"'

=item B<--warning-id>

Define the conditions to match for the status to be WARNING based on the network ID.
Example: --warning-id='%{id} =~ /abcdef/'

=item B<--critical-id>

Define the conditions to match for the status to be CRITICAL based on the network ID.
Example: --critical-id='%{id} =~ /abcdef/'

=item B<--warning-project-id>

Define the conditions to match for the status to be WARNING based on the network project ID.

=item B<--critical-project-id>

Define the conditions to match for the status to be CRITICAL based on the network project ID.

=back

=cut
