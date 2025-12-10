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

package cloud::openstack::restapi::mode::port;

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
                  include_description
                  exclude_description
                  include_admin_state_up
                  exclude_admin_state_up
                  include_port_security_enabled
                  exclude_port_security_enabled
                  include_id
                  exclude_id/;

my @_port_keys = qw/id status name description admin_state_up port_security_enabled project_id admin_state_up port_security_enabled/;

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

sub custom_port_output {
    my ($self, %options) = @_;
    sprintf('Port %s is in %s state',
        $self->{result_values}->{name} || $self->{result_values}->{id}, $self->{result_values}->{status});
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'port', type => 1, message_multiple => 'All ports are ok', skipped_code => { -11 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        {   label => 'count', nlabel => 'port.count',
            set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Port count: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
              }
        }
    ];

    $self->{maps_counters}->{port} = [
        {   label => 'status', type => 2,
            critical_default => '%{status} !~ /ACTIVE/',
            set => {
                key_values => [ map { { name => $_ } } @_port_keys, ],
                output_use => 'name',
                output_template => 'Port name: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_output => $self->can('custom_port_output'),
            },
        },
        (   map {       # define a counter for each other key
                    {   label => $_ =~ s/_/-/gr, type => 2, display_ok => 1,
                        set => {
                            key_values => [ map { { name => $_ } } @_port_keys, ],
                            output_use => $_,
                            output_template => ucfirst $_ =~ s/_/-/gr.': %s',
                            closure_custom_threshold_check => \&catalog_status_threshold_ng,
                        },
                    }
                } grep { ! /name|status/ } @_port_keys
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

    $self->{port} = {};

    # Retry to handle token expiration
    RETRY: for my $retry (1..2) {
        # Don't use the Keystone cache on the second try to force reauthentication
        my $authent = $options{custom}->keystone_authent( dont_read_cache => $retry > 1 );
        $options{custom}->other_services_check_options( keystone_services => $authent->{services} );

        my $ports = $options{custom}->neutron_list_ports( project_id => $self->{filter_project_id},
                                                         ( map { $_ => $self->{$_} } @_options ) ) ;

        # Retry one time if unauthorized
        next RETRY if $ports->{http_status} == 401 && $retry == 1;
        $self->{output}->option_exit(short_msg => $ports->{message})
            if $ports->{http_status} != 200;

        foreach my $port (@{$ports->{results}}) {
            $self->{port}->{$port->{id}} = { %$port };
        }
        last RETRY;
    }

    $self->{global}->{count} = keys %{$self->{port}};
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @_port_keys ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(custom => $options{custom});
    foreach my $item ( sort { $a->{project_id} cmp $b->{project_id} ||
                              $a->{name} cmp $b->{name} ||
                              $a->{id} cmp $b->{id} }
                       values %{$self->{port}}) {
        $self->{output}->add_disco_entry( map { $_ => $item->{$_} } @_port_keys );
    }
}

1;


=head1 MODE

Manage OpenStack Ports

=over 8

=item B<--filter-project-id>

Filter by OpenStack project id (tenant id).
This filter is applied before any other filters and requires admin rights.
When unset ports are filtered based on the project used during authentication.

=item B<--include-name>

Filter by port name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-name>

Exclude by port name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-status>

Filter by port status (can be a regexp and can be used multiple times or for comma separated values).
Can be: ACTIVE, BUILD, DOWN or ERROR

=item B<--exclude-status>

Exclude by port status (can be a regexp and can be used multiple times or for comma separated values).
Can be: ACTIVE, BUILD, DOWN or ERROR

=item B<--include-description>

Filter by port description (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-description>

Exclude by port description (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-admin-state-up>

Filter by port admin state up flag (can be True or False).

=item B<--exclude-admin-state-up>

Exclude by port admin state up flag (can be True or False).

=item B<--include-port-security-enabled>

Filter by port security enabled flag (can be True or False).

=item B<--exclude-port-security-enabled>

Exclude by port security enabled flag (can be True or False).

=item B<--include-id>

Filter by port ID (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-id>

Exclude by port ID (can be a regexp and can be used multiple times or for comma separated values).

=item B<--warning-count>

Warning threshold for the number of ports returned.

=item B<--critical-count>

Critical threshold for the number of ports returned.

=item B<--warning-admin-state-up>

Define the conditions to match for the status to be WARNING based on the admin state up flag (can be True or False).
Example: --warning-admin-state-up='%{admin_state_up} eq "True"'

=item B<--critical-admin-state-up>

Define the conditions to match for the status to be CRITICAL based on the admin state up flag (can be True or False).
Example: --critical-admin-state-up='%{admin_state_up} eq "True"'

=item B<--warning-description>

Define the conditions to match for the status to be WARNING based on the port description.
Example: --warning-description='%{description} =~ /test port/'

=item B<--critical-description>

Define the conditions to match for the status to be CRITICAL based on the port description.
Example: --critical-description='%{description} =~ /test port/'

=item B<--warning-port-security-enabled>

Define the conditions to match for the status to be WARNING based on the port security enabled flag (can be True or False).
Example: --warning-port-security-enabled='%{port_security_enabled} eq "True"'

=item B<--critical-port-security-enabled>

Define the conditions to match for the status to be CRITICAL based on the port security enabled flag (can be True or False).
Example: --critical-port-security-enabled='%{port_security_enabled} eq "True"'

=item B<--warning-id>

Define the conditions to match for the status to be WARNING based on the port id.
Example: --warning-id='%{id} =~ /abcdef/'

=item B<--critical-id>

Define the conditions to match for the status to be CRITICAL based on the port id.
Example: --critical-id='%{id} =~ /abcdef/'

=item B<--warning-project-id>

Define the conditions to match for the status to be WARNING based on the port project id.
Example: --warning-project-id='%{project-id} =~ /abcdef/'

=item B<--critical-project-id>

Define the conditions to match for the status to be CRITICAL based on the port project id.
Example: --critical-project-id='%{project-id} =~ /abcdef/'

=item B<--warning-status>

Define the conditions to match for the status to be WARNING based on the port status.
Status can be: ACTIVE, BUILD, DOWN or ERROR
Example: --warning-status='%{status} =~ /ERROR/'

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL based on the port status.
Status can be: ACTIVE, BUILD, DOWN or ERROR
Default: --critical-status='%{status} !~ /ACTIVE/'
Example: --critical-status='%{status} =~ /ERROR/'

=back

=cut
