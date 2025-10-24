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

package cloud::openstack::restapi::mode::instance;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc qw/flatten_arrays json_encode/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

# All filter parameters that can be used
my @_options = qw/include_name
                  exclude_name
                  include_status
                  exclude_status
                  include_image
                  exclude_image
                  include_flavor
                  exclude_flavor
                  include_host
                  exclude_host
                  include_id
                  exclude_id
                  include_instance_name
                  exclude_instance_name
                  include_zone
                  exclude_zone
                  include_vm_state
                  exclude_vm_state
                  include_ip
                  exclude_ip/;

my @_instance_keys = qw/id host name status image flavor ip bookmark project_id instance_name zone vm_state/;

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        ( map { ($_ =~ s/_/-/gr).':s@' => { name => $_ } } @_options ),

        'filter-project-id:s'          => { name => 'filter_project_id', default => '' },
        'exclude-no-ip:s'              => { name => 'exclude_no_ip', default => 1 },

	# to handle host disovery mode
	'host-discovery'               => { name => 'host_discovery' },
        'prettify'                     => { name => 'prettify', default => 0 }
    });


    return $self;
}

sub custom_server_output {
    my ($self, %options) = @_;
    sprintf('Instance %s is in %s state (vm_state: %s)',
        $self->{result_values}->{name}, $self->{result_values}->{status}, $self->{result_values}->{vm_state});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'server', type => 1, message_multiple => 'All instances are ok', skipped_code => { -11 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        {   label => 'count', nlabel => 'instance.count',
            set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Instance count: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
              }
        }
    ];

    $self->{maps_counters}->{server} = [
        {   label => 'status', type => 2,
            critical_default => '%{status} !~ /active/i',
            set => {
                key_values => [ map { { name => $_ } } @_instance_keys, ],
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_output => $self->can('custom_server_output'),
            },
        },
        (   map {       # define a counter for each other key
                    {   label => $_, type => 2, display_ok => 1,
                        set => {
                            key_values => [ map { { name => $_ } } @_instance_keys, ],
                            output_use => $_,
                            output_template => ucfirst $_.': %s',
                            closure_custom_threshold_check => \&catalog_status_threshold_ng,
                        },
                    }
                } grep { ! /^name|^status|vm_state/ } @_instance_keys
        )
    ];

}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    $self->{$_} = flatten_arrays($self->{option_results}->{$_})
        foreach @_options;

    $self->{$_} = $self->{option_results}->{$_}
        foreach qw/exclude_no_ip prettify filter_project_id prettify host_discovery/;

    $self->{output}->option_exit(short_msg => '--prettify only allowed with --host-discovery')
	if $self->{prettify} and not $self->{host_discovery};
}

sub manage_selection {
    my ($self, %options) = @_;

    my $start_time = time();

    $self->{server} = {};

    # Retry to handle token expiration
    RETRY: for my $retry (1..2) {
        # Don't use the Keystone cache on the second try to force reauthentication
        my $authent = $options{custom}->keystone_authent( dont_read_cache => $retry > 1 );
        $options{custom}->other_services_check_options( keystone_services => $authent->{services} );

        my $instances = $options{custom}->nova_list_instances( project_id => $self->{filter_project_id},
                                                   ( map { $_ => $self->{$_} } @_options ) ) ;

        # Retry one time if unauthorized
        next RETRY if $instances->{http_status} == 401 && $retry == 1;
        $self->{output}->option_exit(short_msg => $instances->{message})
            if $instances->{http_status} != 200;

        foreach my $instance (@{$instances->{results}}) {
            $self->{server}->{$instance->{id}} = { %$instance };
        }
        last RETRY;
    }

    $self->{global}->{count} = keys %{$self->{server}};


    $self->host_discovery(%options, start_time => $start_time)
        if $self->{option_results}->{host_discovery};
}

sub host_discovery {
    my ($self, %options) = @_;

    my $disco_stats;
    $disco_stats->{start_time} = $options{start_time};

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = keys %{$self->{server}};
    $disco_stats->{results} = $self->{server};

    my $encoded_data = json_encode($disco_stats, prettify => $self->{prettify},
                                                 output => $options{output},
                                                 no_exit => 1);

    $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}'
        unless $encoded_data;

    $self->{output}->output_add(short_msg => $encoded_data);

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @_instance_keys ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(custom => $options{custom});
    foreach my $item ( sort { $a->{project_id} cmp $b->{project_id} ||
                              $a->{name} cmp $b->{name} ||
                              $a->{id} cmp $b->{id} }
                       values %{$self->{server}}) {
        $self->{output}->add_disco_entry( map { $_ => $item->{$_} } @_instance_keys );
    }
}

1;

__END__

=head1 MODE

OpenStack Instance mode

=over 8

=item B<--filter-project-id>

Filter by OpenStack project id (tenant id).
This filter is applied before any other filters and requires admin rights.
When unset volumes are filtered based on the project used during authentication.

=item B<--include-name>

Filter by instance name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-name>

Exclude by instance name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-id>

Filter by instance id (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-id>

Exclude by instance id (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-status>

Filter by instance status (can be a regexp and can be used multiple times or for comma separated values).
Please refer to https://docs.openstack.org/api-guide/compute/server_concepts.html for more information about status.

=item B<--exclude-status>

Exclude by instance status (can be a regexp and can be used multiple times or for comma separated values).
Please refer to https://docs.openstack.org/api-guide/compute/server_concepts.html for more information about status.

=item B<--include-image>

Filter by instance image type name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-image>

Exclude by instance image type name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-flavor>

Filter by instance flavor type name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-flavor>

Exclude by instance flavor type name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-host>

Filter by instance host name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-host>

Exclude by instance host name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-instance-name>

Filter by instance Nova instance name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-instance-name>

Exclude by instance Nova instance name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-zone>

Filter by instance placement (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-zone>

Exclude by instance placement (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-vm-state>

Filter by instance vm state (can be a regexp and can be used multiple times or for comma separated values).
Please refer to https://docs.openstack.org/nova/latest/reference/vm-states.html for more information about vm states.

=item B<--exclude-vm-state>

Exclude by instance vm state (can be a regexp and can be used multiple times or for comma separated values).
Please refer to https://docs.openstack.org/nova/latest/reference/vm-states.html for more information about vm states.

=item B<--include-ip>

Filter by instance IP (can be a regexp and can be used multiple times or for comma separated values).
If a instance has multiple IP addresses this parameter must match at least one of them.

=item B<--exclude-ip>

Exclude by instance IP (can be a regexp and can be used multiple times or for comma separated values).
If a instance has multiple IP addresses this parameter must match at least one of them.

=item B<--exclude-no-ip>

Exclude instance that do not have any IP address assigned (default: 1).
Set to 0 to include them in the list.

=back

=cut
