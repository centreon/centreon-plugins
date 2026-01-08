#
# Copyright 2025-Present Centreon (http://www.centreon.com/)
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

package apps::vmware::vsphere8::vcsa::mode::services;

use base qw(apps::vmware::vsphere8::vcsa::mode);

use strict;
use warnings;
use centreon::plugins::misc qw(is_excluded);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my @_options = qw/service_id include_id exclude_id include_description exclude_description/;
my @_service_keys = qw/id state description/;

sub custom_uptime_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'Last repository update was done %s, %d day(s) ago',
        $self->{result_values}->{latest_query_time},
        $self->{result_values}->{age_in_days}
    );

    return $msg;
}

sub custom_service_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "service '%s' (%s) is '%s'",
        $self->{result_values}->{id},
        $self->{result_values}->{description},
        $self->{result_values}->{state}
    );
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'services', type => 1, message_multiple => 'All services are OK' },
    ];

    $self->{maps_counters}->{services} = [
        {
            label  => 'status',
            type   => 2,
            warning_default  => '%{state} ne "STARTED"',
            critical_default => '%{state} eq "STOPPED"',
            unknown_default  => '%{state} eq ""',
            set    => {
                key_values      => [ { name => 'state' }, { name => 'id' }, { name => 'description' } ],
                closure_custom_output => $self->can('custom_service_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);

    $options{options}->add_options(arguments => {
        ( map { ($_ =~ s/_/-/gr).':s' => { name => $_, default => '' } } @_options )
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $id = $self->{option_results}->{service_id};
    # Retrieve the data
    my $response = $options{custom}->request_api(
        'endpoint' => '/appliance/services/' . $id,
        'method' => 'GET');

    if ($id ne '') {
        $self->{services}->{$id} = {
            id          => $id,
            description => $response->{description},
            state       => $response->{state}
        };
    } else {
        foreach my $service_id (keys %$response) {
            # apply filters
            next if is_excluded(
                $service_id,
                $self->{option_results}->{include_id},
                $self->{option_results}->{exclude_id});
            next if is_excluded(
                $response->{$service_id}->{description},
                $self->{option_results}->{include_description},
                $self->{option_results}->{exclude_description});
            # store result
            $self->{services}->{$service_id} = {
                id          => $service_id,
                description => $response->{$service_id}->{description},
                state       => $response->{$service_id}->{state}
            };
        }
    }

    $self->{output}->option_exit(short_msg => 'No service found with current filters.') if (keys(%{$self->{services}}) == 0);

}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @_service_keys ], prettify => 0);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(custom => $options{custom});
    foreach my $item ( sort { $a->{id} cmp $b->{id} }
                       values %{$self->{services}}) {
        $self->{output}->add_disco_entry( map { $_ => $item->{$_} } @_service_keys );
    }
}

1;

__END__

=head1 MODE

Discover and monitor the VMware vCenter services VMs through vSphere 8 REST API.

=over 8

=item B<--service-id>

Define the exact ID of the service to monitor. Using this option is recommended to monitor one service because it will
only retrieve the data related to the targeted service.

Service IDs examples are: C<vmtoolsd>, C<vmware-vmon>, C<vmware-pod>...

=item B<--include-id>

Regular expression to include services to monitor by their ID. Using this option is not recommended to monitor
one service because it will first retrieve the list of all services and then filter to get the targeted service.

=item B<--exclude-id>

Regular expression to exclude services to monitor by their ID. Using this option is not recommended to monitor
one service because it will first retrieve the list of all services and then filter to get the targeted service.

=item B<--include-description>

Regular expression to include services to monitor by their description. Using this option is not recommended to monitor
one service because it will first retrieve the list of all services and then filter to get the targeted service.

=item B<--exclude-description>

Regular expression to exclude services to monitor by their description. Using this option is not recommended to monitor
one service because it will first retrieve the list of all services and then filter to get the targeted service.

=item B<--warning-status>

Define the condition to match for the status to be WARNING. Available macros: C<%(state)>, C<%(id)> and C<%(description)>.
Default: C<%{state} ne "STARTED">

State can be STARTED or STOPPED.

=item B<--critical-status>

Define the condition to match for the status to be CRITICAL. Available macros: C<%(state)>, C<%(id)> and C<%(description)>.
Default: C<%{state} eq "STOPPED">

State can be STARTED or STOPPED.

=back

=cut
