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

package cloud::openstack::restapi::mode::listvms;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw/flatten_arrays/;

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
                  include_instance_name
                  exclude_instance_name
                  include_zone
                  exclude_zone
                  include_ip
                  exclude_ip/;

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        ( map { ($_ =~ s/_/-/gr).':s@' => { name => $_ } } @_options ),

        'filter-project-id:s'          => { name => 'filter_project_id', default => '' },
        'exclude-no-ip:s'              => { name => 'exclude_no_ip', default => 1 }
    });


    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::init(%options);

    $self->{$_} = flatten_arrays($self->{option_results}->{$_})
        foreach @_options;

    $self->{$_} = $self->{option_results}->{$_}
        foreach qw/exclude_no_ip prettify filter_project_id/;
}

my @labels = qw/name status image flavor host ip bookmark tenant_id tenant_name instance_name zone/;

sub manage_selection {
    my ($self, %options) = @_;

    # Retry to handle token expiration
    RETRY: for my $retry (1..2) {
        # Don't use the Keystone cache on the second try to force reauthentication
        my $authent = $options{custom}->keystone_authent( dont_read_cache => $retry > 1 );
        $options{custom}->other_services_check_options( keystone_services => $authent->{services} );

        my $vms = $options{custom}->nova_list_vms( project_id => $self->{filter_project_id},
                                                   ( map { $_ => $self->{$_} } @_options ) ) ;

        # Retry one time if unauthorized
        next RETRY if $vms->{http_status} == 401 && $retry == 1;
        $self->{output}->option_exit(short_msg => $vms->{message})
            if $vms->{http_status} != 200;

        return $vms->{results};
    }
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});

    $self->{output}->output_add(severity => 'OK', short_msg => 'List VMs:');
    foreach my $vm (@{$results}) {
        $self->{output}->output_add(long_msg => join '', map { "[$_ = ".($vm->{$_} // 'N/A')."]" } @labels);
    }

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [@labels]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $item (@{$results}) {
        $self->{output}->add_disco_entry( map { $_ => $item->{$_} } @labels );
    }
}

1;

__END__

=head1 MODE

List Virtual Machines (VM) hosted by OpenStack

=over 8

=item B<--filter-project-id>

Filter by OpenStack project id (tenant id).

=item B<--include-name>

Filter by VM name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-name>

Exclude by VM name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-status>

Filter by VM status (can be a regexp and can be used multiple times or for comma separated values).
Please refer to https://docs.openstack.org/api-guide/compute/server_concepts.html for more information about status.

=item B<--exclude-status>

Exclude by VM status (can be a regexp and can be used multiple times or for comma separated values).
Please refer to https://docs.openstack.org/api-guide/compute/server_concepts.html for more information about status.

=item B<--include-image>

Filter by VM image type name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-image>

Exclude by VM image type name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-flavor>

Filter by VM flavor type name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-flavor>

Exclude by VM flavor type name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-host>

Filter by VM host name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-host>

Exclude by VM host name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-instance-name>

Filter by VM Nova instance name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-instance-name>

Exclude by VM Nova instance name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-zone>

Filter by VM placement (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-zone>

Exclude by VM placement (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-ip>

Filter by VM IP (can be a regexp and can be used multiple times or for comma separated values).
If a VM has multiple IP addresses this parameter must match at least one of them.

=item B<--exclude-ip>

Exclude by VM IP (can be a regexp and can be used multiple times or for comma separated values).
If a VM has multiple IP addresses this parameter must match at least one of them.

=item B<--exclude-no-ip>

Exclude VM that do not have any IP address assigned (default: 1).
Set to 0 to include them in the list.

=back

=cut
