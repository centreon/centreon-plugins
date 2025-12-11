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

package apps::vmware::vsphere8::esx::mode;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use strict;
use warnings;

use base qw(centreon::plugins::templates::counter);

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);

    $options{options}->add_options(
        arguments => {
            'esx-id:s'   => { name => 'esx_id' },
            'esx-name:s' => { name => 'esx_name' }
        }
    );
    $options{options}->add_help(package => __PACKAGE__, sections => 'VMWARE 8 HOST OPTIONS', once => 1);
    $self->{cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub get_esx_id {
    my ($self, %options) = @_;

    # return the id if we already have it in memory
    return $self->{esx_id} if (!centreon::plugins::misc::is_empty($self->{esx_id}));

    if ( centreon::plugins::misc::is_empty($self->{esx_name}) ) {
        $self->{output}->option_exit(short_msg => "get_esx_id method called without esx_name option. Please check configuration.");
    }

    # return it from the cache if it is available
    if ($self->{cache}->read(statefile => 'vsphere8_api_esx_info_' . md5_hex($self->{esx_name}))) {
        my $esx_id = $self->{cache}->get(name => 'esx_id');
        # store it to avoid re-reading the cache the next time it is asked
        $self->{esx_id} = $esx_id;
        return $self->{esx_id};
    }

    my $response = $options{custom}->request_api(
        'endpoint' => '/vcenter/host',
        'get_param' => [ 'names='. $self->{esx_name} ],
        'method' => 'GET'
    );

    for my $rsrc (@$response) {
        next if ($rsrc->{name} ne $self->{esx_name});
        $self->{esx_id} = $rsrc->{host};
        $self->{output}->add_option_msg(long_msg => "get_esx_id method called to get " . $self->{esx_name}
            . "'s id: " . $self->{esx_id} . ". Prefer using --esx-id to spare a query to the API.");
        # store it in the cache for future runs
        $self->{cache}->write(data => {updated => time(), esx_id => $self->{esx_id}});
        return $rsrc->{host};
    }

    return undef;

}

sub get_esx_stats {
    my ($self, %options) = @_;

    if ( centreon::plugins::misc::is_empty($options{esx_id}) && !$self->get_esx_id(%options) ) {
        $self->{output}->option_exit(short_msg => "get_esx_stats method cannot get host ID from host name");
    }

    return $options{custom}->get_stats(
        %options,
        rsrc_id   => $self->{esx_id}
    );
}

sub request_api {
    my ($self, %options) = @_;

    return $options{custom}->request_api(%options);
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);
    $self->{cache}->check_options(option_results => $self->{option_results});

    if (centreon::plugins::misc::is_empty($self->{option_results}->{esx_id})
        && centreon::plugins::misc::is_empty($self->{option_results}->{esx_name})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify either --esx-id or --esx-name option.');
        $self->{output}->option_exit();
    }

    $self->{esx_id}   = $self->{option_results}->{esx_id};
    $self->{esx_name} = $self->{option_results}->{esx_name};

}

1;

__END__

=head1 VMWARE 8 HOST OPTIONS

=over 4

=item B<--esx-id>

Define which physical server to monitor based on its resource ID (example: C<host-16>).

=item B<--esx-name>

Define which physical server to monitor based on its name (example: C<esx01.mydomain.tld>).
When possible, it is recommended to use C<--esx-id> instead.

=back

=cut

=head1 NAME

apps::vmware::vsphere8::esx::mode - Template for modes monitoring VMware physical hosts

=head1 SYNOPSIS

    use base apps::vmware::vsphere8::esx::mode;

    sub set_counters {...}
    sub manage_selection {
        my ($self, %options) = @_;


    $api->set_options(option_results => $option_results);
    $api->check_options();
    my $response = $api->request_api(endpoint => '/vcenter/host');
    my $host_cpu_capacity = $self->get_esx_stats(
                                cid     => 'cpu.capacity.provisioned.HOST',
                                rsrc_id => 'host-18');

=head1 DESCRIPTION

This module provides methods to interact with the VMware vSphere 8 REST API. It handles authentication, caching, and API requests.

=head1 METHODS

=head2 get_esx_stats

    $self->get_esx_stats(%options);

Retrieves the ESX statistics for the given options using package apps::vmware::vsphere8::custom::api::get_stats()

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<cid> - The C<cid> (counter id) of the desired metric.

=item * C<esx_id> - The ESX's C<rsrc_id> (resource ID) for which to retrieve the statistics. This option is optional if C<esx_name> is provided.

=item * C<esx_name> - The ESX's name for which to retrieve the statistics. This option is not used if C<esx_id> is provided, which is the nominal usage of this function.

=back

=back

Returns the statistics for the specified ESX.

=cut

