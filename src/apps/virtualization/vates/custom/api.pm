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

package apps::virtualization::vates::custom::api;
use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use centreon::plugins::misc qw/json_encode json_decode is_empty is_not_empty/;
use Digest::SHA 'sha1_hex';

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.");
    }

    $options{options}->add_options(
        arguments => {
            'hostname:s' => { name => 'hostname' },
            'port:s'     => { name => 'port', default => '443' },
            'proto:s'    => { name => 'proto', default => 'https' },
            'username:s' => { name => 'username' },
            'password:s' => { name => 'password' },
            'timeout:s'  => { name => 'timeout', default => 10 },
            'api-url:s'  => {name => 'api_url', default => '/rest/v0/' },
            'header:s@'  => { name => 'header' },
            'reload-cache-time:s'  => {name => 'reload_cache_time', default => 1440 },

        });

    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output}          = $options{output};
    $self->{http}            = centreon::plugins::http->new(%options, 'default_backend' => 'curl');
    $self->{statefile_cache}        = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub check_options {
    my $self = shift;
    if (!$self->{option_results}->{password} && !$self->{option_results}->{api_key}){
                $self->{output}->option_exit(short_msg => "Need to specify --password or --api-key option.");
    }
    if ($self->{option_results}->{hostname} eq '') {
        $self->{output}->option_exit(short_msg => "Need to specify --hostname option.");
    }
    if ($self->{option_results}->{username} eq '') {
        $self->{output}->option_exit(short_msg => "Need to specify --username option.");
    }
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{statefile_cache}->check_options(option_results => $self->{option_results});
    # set auth header
    $self->{auth_header} = MIME::Base64::encode_base64($self->{option_results}->{username} . ':' . $self->{option_results}->{password});
    chomp($self->{auth_header});
    # registered through add_header (not passed to request()) so it merges with, instead of
    # overriding, any --header value supplied on the command line.
    $self->{http}->add_header(key => 'Authorization', value => 'Basic ' . $self->{auth_header});

    return 0;
}
sub request_api {
    my ($self, %options) = @_;

     my ($content) = $self->{http}->request(
        method          => 'GET',
        url_path        => $self->{option_results}->{api_url} . $options{endpoint},
        get_param       => $options{get_param},
        header          => $options{header},
        # lets a caller inspect a non-2xx JSON error body instead of the http layer
        # auto-exiting on it (used by get_vm_stats to tell "vm halted" from a real error).
        silently_fail   => $options{silently_fail}
     );
    return json_decode($content, booleans_as_strings => 1);

}

sub request_api_get {
    my ($self, %options) = @_;

    my ($content) = $self->request_api(%options, method => "GET");

    return $content;
}

# get_name_and_uuid( type => 'pool', 'api_endpoint' => 'pools');
# check --{type}-name and --{type}-uuid and retrieve the other value from the api.
# it caches the mapping on disk for --reload-cache-time window second
# %options input :
#   type : the type of object fetching, used to construct the argument name (ex: pool, vm, host)
#   api_endpoint: optionnal api endpoint to collect data (ex: pools) use type if empty
sub get_name_and_uuid {
    my ($self, %options) = @_;

    my $obj_uuid = $options{type} . "_uuid";
    my $obj_name = $options{type} . "_name";

    my $vm_name = $self->{option_results}->{$obj_name};
    my $has_cache_file = $self->{statefile_cache}->read(
        statefile => 'vates_uuid_to_name' . sha1_hex(
            $self->{option_results}->{hostname} . '_' .
            $self->{option_results}->{$obj_name} .
            $self->{option_results}->{$obj_uuid})
    );
    my $cached_uuid = $self->{statefile_cache}->get(name => 'values');
    my $last_timestamp = $self->{statefile_cache}->get(name => 'last_timestamp');

    if ($has_cache_file == 0
        or !defined($cached_uuid)
        or (time() - $last_timestamp) > ($self->{option_results}->{reload_cache_time} * 60)
    ) {
        my $filter = '';

        if (is_not_empty($self->{option_results}->{$obj_name})) {

            $filter = "name_label:" . $self->{option_results}->{$obj_name};
        }
        else {
            $filter = "uuid:" . $self->{option_results}->{$obj_uuid};
        }
        my $response = $self->request_api_get(
            endpoint  => $options{api_endpoint} // $options{type},
            get_param => [ 'fields=uuid,name_label', 'filter=' . $filter]
        );
        if (!defined($response) or ref($response) ne 'ARRAY' or scalar @$response != 1) {
            $self->{output}->option_exit(short_msg => "no $options{type} found, api did not return an array with one element. Please check --$options{type}-uuid and --$options{type}-name parameter or --debug.");
        }
        $cached_uuid = {uuid => $response->[0]->{uuid}, name_label =>  $response->[0]->{name_label} };
        $self->{statefile_cache}->write(data => { values => $cached_uuid, last_timestamp => time() });
    }

    return $cached_uuid;
}

# used to get overview of one vm with power state, and uuid/name
sub get_vm_info {
    my ($self, %options) = @_;

    my $fields = "name_label,power_state,uuid,os_version";

    # default filter use uuid, or name if not present.
    my $filter = "uuid:". $self->{option_results}->{vm_uuid};
    if (is_empty($self->{option_results}->{vm_uuid})){
        $filter = "name_label:". $self->{option_results}->{vm_name};
    }
    my $response = $self->request_api_get(
        endpoint  => "vms",
        get_param => [ "fields=" . $fields, "filter=" . $filter ],
    );
    if (!defined($response) or ref($response) ne "ARRAY" or scalar @$response != 1){
        $self->{output}->option_exit(short_msg => "no vm found, api did not return an array with one element. Please check --vm-uuid and --vm-name parameter or --debug.");
    }
    return $response->[0];
}
1;

__END__

=head1 NAME

apps::virtualization::vates::custom::api - Custom module for the Vates Xen Orchestra REST API.

=head1 DESCRIPTION

This module provides methods to interact with the Vates Xen Orchestra REST API (Basic Auth). It
handles authentication, on-disk caching of name/uuid lookups, and API requests.

=head1 METHODS

=head2 request_api / request_api_get

    my $response = $api->request_api_get(endpoint => 'vms', get_param => ['fields=uuid']);

Performs a GET request against C<< <api-url><endpoint> >> and decodes the JSON response.
C<silently_fail> may be passed through so the (possibly non-200) response body is returned
instead of letting the HTTP layer exit on error.

=head2 get_name_and_uuid

    my $ids = $api->get_name_and_uuid(type => 'pool', api_endpoint => 'pools');

Resolves C<--E<lt>typeE<gt>-name>/C<--E<lt>typeE<gt>-uuid> (whichever was provided) to
C<{ uuid =E<gt> ..., name_label =E<gt> ... }>, caching the mapping on disk so it is only
re-fetched once per C<--reload-cache-time> window instead of on every plugin execution.

=head2 get_vm_info

    my $vm = $api->get_vm_info();

Resolves C<--vm-uuid>/C<--vm-name> and returns the matching VM's C<name_label>, C<power_state>,
C<uuid> and C<os_version> fields. Always live (not cached), since C<power_state> can change at
any time.

=head1 REST API OPTIONS

Command-line options for the Vates Xen Orchestra API:

=over 8

=item B<--hostname>

Define the hostname of the Vates server.

=item B<--port>

Define the port of the Vates server (default: 443).

=item B<--proto>

Define the protocol to use (default: https).

=item B<--username>

Define the username for authentication.

=item B<--password>

Define the password for authentication.

=item B<--timeout>

Define the http timeout in second (default: 10).

=item B<--api-url>

Define the API prefix (default: /rest/v0/).

=item B<--header>

Define an optional additional header to send with every HTTP request (repeatable).

=back

=cut
