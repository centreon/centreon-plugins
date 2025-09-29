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

package apps::vmware::vsphere8::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use MIME::Base64;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(
            arguments => {
                'hostname:s'        => { name => 'hostname' },
                'port:s'            => { name => 'port',                default => '443' },
                'proto:s'           => { name => 'proto',               default => 'https' },
                'username:s'        => { name => 'username' },
                'password:s'        => { name => 'password' },
                'vstats-interval:s' => { name => 'vstats_interval',     default => 60 },
                'vstats-duration:s' => { name => 'vstats_duration',     default => 2764800 }, # 2764800 seconds in 32 days
                'timeout:s'         => { name => 'timeout',             default => 10 }
            }
        );
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output}          = $options{output};
    $self->{http}            = centreon::plugins::http->new(%options, 'default_backend' => 'curl');
    $self->{token_cache}     = centreon::plugins::statefile->new(%options);
    $self->{acq_specs_cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname}        = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port}            = $self->{option_results}->{port};
    $self->{proto}           = $self->{option_results}->{proto};
    $self->{timeout}         = $self->{option_results}->{timeout};
    $self->{username}        = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : '';
    $self->{password}        = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : '';
    $self->{vstats_interval} = $self->{option_results}->{vstats_interval};
    $self->{vstats_duration} = $self->{option_results}->{vstats_duration};

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if ($self->{username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --username option.");
        $self->{output}->option_exit();
    }
    if ($self->{password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --password option.");
        $self->{output}->option_exit();
    }

    $self->{token_cache}->check_options(option_results => $self->{option_results});
    $self->{acq_specs_cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    # add options of this api
    $self->{option_results}->{username} = $self->{username};
    $self->{option_results}->{password} = $self->{password};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = $self->{http_unknown_status};
}

sub settings {
    my ($self, %options) = @_;

    return 1 if (defined($self->{settings_done}));
    $self->build_options_for_httplib();

    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;

    return 1;
}

sub get_token {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{token_cache}->read(
            statefile => 'vsphere8_api_token_' . md5_hex(
                    $self->{hostname}
                    . ':' . $self->{port}
                    . '_' . $self->{username})
    );
    my $token = $self->{token_cache}->get(name => 'token');

    if (
        $has_cache_file == 0
        || !defined($token)
        || $options{force_authentication}
    ) {
        my $auth_string = MIME::Base64::encode_base64($self->{username} . ':' . $self->{password});
        chomp $auth_string;

        $self->settings();
        my $content = $self->{http}->request(
            method          => 'POST',
            url_path        => '/api/session',
            query_form_post => '',
            header          => [
                'Authorization: Basic ' . $auth_string,
                'Content-Type: application/x-www-form-urlencoded'
            ]
        );

        $content =~ s/^"(.*)"$/$1/;
        $token = $content;

        $self->{token_cache}->write(data => { updated => time(), token => $token });
    }

    return $token;
}

sub try_request_api {
    my ($self, %options) = @_;

    my $token = $self->get_token(%options);
    my $method = centreon::plugins::misc::is_empty($options{method}) ? 'GET' : $options{method};
    my $headers = [ 'vmware-api-session-id: ' . $token ];
    if ($method =~ /^(PATCH|POST)$/) {
        push @$headers, 'content-type: application/json';
    }

    my $unknown_status = (defined($options{unknown_status})) ? $options{unknown_status} : undef;

    my ($content) = $self->{http}->request(
        method          => $method,
        url_path        => '/api' . $options{endpoint},
        get_param       => $options{get_param},
        header          => $headers,
        query_form_post => $options{query_form_post},
        unknown_status   => $unknown_status,
        insecure        => (defined($self->{option_results}->{insecure}) ? 1 : 0)
    );

    if (!defined($content)) {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '"
                . $self->{http}->get_code() . "'] [message: '"
                . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    return {} if ($method eq 'PATCH' && $self->{http}->get_code() == 204
        || $method eq 'POST' && $self->{http}->get_code() == 201);

    my $decoded = centreon::plugins::misc::json_decode($content, booleans_as_strings => 1);
    if (!defined($decoded)) {
        $self->{output}->add_option_msg(short_msg => "API returns empty/invalid content [code: '"
                . $self->{http}->get_code() . "'] [message: '"
                . $self->{http}->get_message() . "'] [content: '"
                . $content . "']");
        $self->{output}->option_exit();
    }

    if (ref($decoded) eq "HASH" && defined($decoded->{error_type})) {
        $self->{output}->add_option_msg(short_msg => "API returned an error: " . $decoded->{error_type} . " - " . $decoded->{messages}->[0]->{default_message});
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();

    # first call using the available token with unknown_status = 0 in order to avoid exiting at first attempt in case it has expired
    my $api_response = $self->try_request_api(%options, unknown_status => '0');

    # if the token is invalid, we try to authenticate again
    if (ref($api_response) eq 'HASH'
            && defined($api_response->{error_type})
            && $api_response->{error_type} eq 'UNAUTHENTICATED') {
        # if the first attempt failed, try again forcing to authenticate
        $api_response = $self->try_request_api('force_authentication' => 1, %options);
    }

    # if we could not authenticate, we exit (unless no_fail option is true)
    if (ref($api_response) eq 'HASH' && defined($api_response->{error_type}) && ! $options{no_fail}) {
        my $full_message = '';
        for my $error_item (@{$api_response->{messages}}) {
            $full_message .= '[Id: ' . $error_item->{id} . ' - Msg: ' . $error_item->{default_message} . ' (' . join(', ', @{$error_item->{args}}) . ')]';
        }
        $self->{output}->add_option_msg(short_msg => "API returns error of type " . $api_response->{error_type} . ": " . $full_message);
        $self->{output}->option_exit();
    }


    return $api_response;
}

sub get_folder_ids_by_names {
    my ($self, %options) = @_;

    my $api_response = $self->request_api(
        %options,
        'endpoint' => '/vcenter/folder?names=' . $options{names},
        'method' => 'GET');
    my @folders = map { $_->{folder} } @{$api_response};
    return join(',', @folders);
}

sub get_vm_guest_identity {
    my ($self, %options) = @_;

    my $api_response = $self->request_api(
        'endpoint' => '/vcenter/vm/' . $options{vm_id} . '/guest/identity',
        'method'   => 'GET',
        no_fail    => 1);

    return $api_response;
}

sub get_all_acq_specs {
    my ($self, %options) = @_;

    # if we already have it in memory, we return what we have
    return $self->{all_acq_specs} if ($self->{all_acq_specs} && @{$self->{all_acq_specs}});

    # if we can get it from the cache, we return it
    if ($self->{acq_specs_cache}->read(
        statefile => 'vsphere8_api_acq_specs_' . md5_hex($self->{hostname} . ':' . $self->{port} . '_' . $self->{username})
    )) {
        $self->{all_acq_specs} = $self->{acq_specs_cache}->get(name => 'acq_specs');
        return $self->{all_acq_specs};
    }
    # Get all acq specs (first page)
    my $response =  $self->request_api(endpoint => '/stats/acq-specs') ;
    $self->{all_acq_specs} = $response->{acq_specs};

    # If the whole acq-specs takes more than one page, the API will return a "next" value
    while ($response->{next}) {
        $response = $self->request_api(endpoint => '/stats/acq-specs', get_param => [ 'page=' . $response->{next} ] );
        push @{$self->{all_acq_specs}}, @{$response->{acq_specs}};
    }

    # store it in the cache for future runs
    $self->{acq_specs_cache}->write(data => { updated => time(), acq_specs => $self->{all_acq_specs} });
    return $self->{all_acq_specs};
}

sub compose_type_from_rsrc_id {
    my ($self, $rsrc_id) = @_;

    if ($rsrc_id =~ /^([a-z]+)-(\d+)$/) {
        return uc($1);
    } else {
        $self->{output}->add_option_msg(short_msg => "compose_type_from_rsrc_id: cannot extract type from '$rsrc_id'");
        $self->{output}->option_exit();
    }
}

sub compose_acq_specs_json_payload {
    my ($self, %options) = @_;

    my $payload = {
            counters   => {
                    cid_mid => {
                            cid => $options{cid}
                    }
            },
            resources  => [
                    {
                            predicate => 'EQUAL',
                            scheme    => 'moid',
                            type      => $self->compose_type_from_rsrc_id($options{rsrc_id}),
                            id_value  => $options{rsrc_id}
                    }
            ],
            expiration => time() + $self->{vstats_duration},
            interval   => $self->{vstats_interval}
    };

    return(centreon::plugins::misc::json_encode($payload));
}

sub create_acq_spec {
    my ($self, %options) = @_;

    if (centreon::plugins::misc::is_empty($options{cid})) {
        $self->{output}->add_option_msg(short_msg => "ERR: need a cid to create an acq_spec");
        $self->{output}->option_exit();
    }
    if (centreon::plugins::misc::is_empty($options{rsrc_id})) {
        $self->{output}->add_option_msg(short_msg => "ERR: need a rsrc_id to create an acq_spec");
        $self->{output}->option_exit();
    }

    $self->request_api(
        method          => 'POST',
        endpoint        => '/stats/acq-specs/',
        query_form_post => $self->compose_acq_specs_json_payload(%options)
    ) or return undef;
    $self->{output}->add_option_msg(long_msg => "The counter $options{cid} was not recorded for resource $options{rsrc_id} before. It will now (creating acq_spec).");

    return 1;
}

sub extend_acq_spec {
    my ($self, %options) = @_;

    if (centreon::plugins::misc::is_empty($options{cid})) {
        $self->{output}->add_option_msg(short_msg => "ERR: need a cid to extend an acq_spec");
        $self->{output}->option_exit();
    }
    if (centreon::plugins::misc::is_empty($options{rsrc_id})) {
        $self->{output}->add_option_msg(short_msg => "ERR: need a rsrc_id to extend an acq_spec");
        $self->{output}->option_exit();
    }

    if (centreon::plugins::misc::is_empty($options{acq_spec_id})) {
        $self->{output}->add_option_msg(long_msg => "ERR: need a acq_spec_id to extend an acq_spec_id") ;
        $self->{output}->option_exit();
    }
    $self->{output}->add_option_msg(long_msg => "The acq_spec entry has to be extended to get more stats for $options{rsrc_id} / $options{cid}");

    my $json_payload = $self->compose_acq_specs_json_payload(%options);
    my $response = $self->request_api(
        method          => 'PATCH',
        endpoint        => '/stats/acq-specs/' . $options{acq_spec_id},
        query_form_post => $json_payload
    );

    # The response must be empty if the patch succeeds
    return undef if (defined($response) && ref($response) eq 'HASH' && scalar(keys %$response) > 0);

    # reset stored acq_specs since it's no longer accurate
    $self->{all_acq_specs} = [];

    return 1;
}

sub get_acq_spec {
    my ($self, %options) = @_;

    # If it is not available in cache call get_all_acq_specs()
    my $acq_specs = $self->get_all_acq_specs();
    for my $spec (@$acq_specs) {
        # Ignore acq_specs not related to the counter_id
        next if ($options{cid} ne $spec->{counters}->{cid_mid}->{cid});
        # Check if this acq_spec is related to the given resource
        my @matching_rsrcs = grep {
            $_->{id_value} eq $options{rsrc_id}
            && $_->{predicate} eq 'EQUAL'
            && $_->{scheme} eq 'moid'
        } @{$spec->{resources}};
        return $spec if (@matching_rsrcs > 0);
    }

    return undef;
}

sub check_acq_spec {
    my ($self, %options) = @_;

    my $acq_spec = $self->get_acq_spec(%options);

    if ( !defined($acq_spec) ) {
        # acq_spec not found => we need to create it
        $self->create_acq_spec(%options) or return(undef);
        # acq_spec is created => check is ok
        return 1;
    } elsif ($acq_spec->{status} eq 'EXPIRED' || $acq_spec->{expiration} <= time() + 3600) {
        # acq_spec exists but expired => we need to extend it
        $self->extend_acq_spec(%options, acq_spec_id => $acq_spec->{id}) or return(undef);
        # acq_spec is extended => check is ok
        return 1;
    }
    # acq_spec exists and is not expired => check is ok
    return 1;
}

sub get_stats {
    my ($self, %options) = @_;

    if ( centreon::plugins::misc::is_empty($options{rsrc_id})) {
        $self->{output}->add_option_msg(short_msg => "get_stats method called without rsrc_id, won't query");
        $self->{output}->option_exit();
    }

    if ( centreon::plugins::misc::is_empty($options{cid}) ) {
        $self->{output}->add_option_msg(short_msg => "get_stats method called without cid, will get all available stats for resource");
        $self->{output}->option_exit();
    }

    if ( !$self->check_acq_spec(%options) ) {
        $self->{output}->add_option_msg(short_msg => "get_stats method failed to check_acq_spec()");
        $self->{output}->option_exit();
    }

    # compose the endpoint
    my $endpoint = '/stats/data/dp?'
        . 'rsrcs=type.' . $self->compose_type_from_rsrc_id($options{rsrc_id}) . '.moid=' . $options{rsrc_id}
        . '&cid=' . $options{cid}
        . '&start=' . (time() - 120); # get the last two minutes to be sure to get at least one value

    my $result = $self->request_api(
            method => 'GET',
            endpoint   => $endpoint
    );

    if (defined($result->{messages})) {
        # Example of what can happen when a VM has no stats
        # {
        #   "messages": [
        #     {
        #       "args": [],
        #       "default_message": "Invalid data points filter: found empty set of Resource Addresses for provided set of (types,resources)",
        #       "localized": "Invalid data points filter: found empty set of Resource Addresses for provided set of (types,resources)",
        #       "id": "com.vmware.vstats.data_points_invalid_resource_filter"
        #     }
        #   ]
        # }
        $self->{output}->add_option_msg(short_msg => "No stats found. Error: " . $result->{messages}->[0]->{default_message});
        $self->{output}->option_exit();
    }

    # return only the last value (if there are several)
    if ( !defined($result->{data_points}) || scalar(@{ $result->{data_points} }) == 0 ) {
        $self->{output}->add_option_msg(short_msg => "no data for resource " . $options{rsrc_id} . " counter " . $options{cid} . " at the moment.");
        return undef;
    }

    # Return the `val` field of the last object of the array
    return $result->{data_points}->[ @{ $result->{data_points} } - 1 ]->{val};
    # FIXME: handle arrays in get_stats and check_acq_specs
}

1;
__END__

=head1 NAME

apps::vmware::vsphere8::custom::api - Custom module for VMware vSphere 8 API.

=head1 SYNOPSIS

    use apps::vmware::vsphere8::custom::api;

    my $api = apps::vmware::vsphere8::custom::api->new(
        output => $output,
        options => $options
    );

    $api->set_options(option_results => $option_results);
    $api->check_options();
    my $response = $api->request_api(endpoint => '/vcenter/host');
    my $host_cpu_capacity = $api->get_stats(
                                cid     => 'cpu.capacity.provisioned.HOST',
                                rsrc_id => 'host-18');

=head1 DESCRIPTION

This module provides methods to interact with the VMware vSphere 8 REST API. It handles authentication, caching, and API requests.

=head1 METHODS

=head2 new

    my $api = apps::vmware::vsphere8::custom::api->new(%options);

Creates a new C<apps::vmware::vsphere8::custom::api> object.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<output> - An output object for messages.

=item * C<options> - An options object for adding command-line options.

=back

=back

=head2 set_options

    $api->set_options(option_results => $option_results);

Sets the options for the API module.

=over 4

=item * C<option_results> - A hash of option results.

=back

=head2 set_defaults

    $api->set_defaults();

Sets the default options for the API module.

=head2 check_options

    $api->check_options();

Checks and processes the provided options.

=head2 build_options_for_httplib

    $api->build_options_for_httplib();

Builds the options for the HTTP library.

=head2 settings

    $api->settings();

Configures the HTTP settings for the API requests.

=head2 get_token

    my $token = $api->get_token(%options);

Retrieves the authentication token from the cache or requests a new one if necessary.

=over 4

=item * C<%options> - A hash of options.

=back

=head2 try_request_api

    my $response = $api->try_request_api(%options);

Attempts to make an API request with the provided options.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<endpoint> - The API endpoint to request.

=item * C<get_param> - Additional GET parameters for the request.

=item * C<force_authentication> - Force re-authentication if set to true.

=back

=back

=head2 request_api

    my $response = $api->request_api(%options);

Calls try_request_api and recalls it forcing authentication if the first call fails.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<method> - The HTTP method to use (examples: GET, POST).

=item * C<endpoint> - The API endpoint to request.

=item * C<get_param> - Additional GET parameters for the request.

=back

=back

=head2 get_folder_ids_by_names

    my $folder_ids = $self->get_folder_ids_by_names(names => $folder_names);

Retrieves the IDs of folders based on their names.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<names> - A comma-separated string of folder names to search for. This option is required.

=back

=back

Returns a comma-separated string of folder IDs corresponding to the provided folder names.

=cut

=head2 get_vm_guest_identity

    my $identity = $self->get_vm_guest_identity(vm_id => $vm_id);

Retrieves the guest identity information for a specific virtual machine (VM) using its ID.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<vm_id> - The ID of the virtual machine for which to retrieve the guest identity. This option is required.

=back

=back

Returns the guest identity information as a hash reference if successful, or undef if the request fails.

=cut

=head2 get_acq_spec

    my $spec = $self->get_acq_spec(%options);

Retrieves the acquisition specification (acq_spec) for the given counter ID (C<cid>) and resource ID (rsrc_id).

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<cid> - The counter ID for which to retrieve the acq_spec. This option is required.

=item * C<rsrc_id> - The resource ID for which to retrieve the acq_spec. This option is required.

=back

=back

Returns the matching acq_spec if found, otherwise returns undef.

=cut

=head2 create_acq_spec

    $api->create_acq_spec(%options);

Creates a new acquisition specification (acq_spec) for the given options.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<cid> - The counter ID for which to create the acq_spec. This option is required.

=item * C<rsrc_id> - The resource ID for which to create the acq_spec. This option is required.

=back

=back

Returns 1 if the acq_spec is successfully created, otherwise returns undef.

=cut

=head2 extend_acq_spec

    $api->extend_acq_spec(%options);

Extends the acquisition specification (acq_spec) for the given options.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<cid> - The counter ID for which to extend the acq_spec. This option is required.

=item * C<rsrc_id> - The resource ID for which to extend the acq_spec. This option is required.

=item * C<acq_spec_id> - The acquisition specification ID to extend. This option is required.

=back

=back

Returns 1 if the acq_spec is successfully extended, otherwise returns undef.

=cut

=head2 check_acq_spec

    $api->check_acq_spec(%options);

Checks the acquisition specification (acq\_spec) for the given options. If the acq\_spec does not exist, it creates a new one. If the acq\_spec exists but is expired or about to expire, it extends the acq\_spec.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<cid> - The counter ID for which to check the acq\_spec. This option is required.

=item * C<rsrc_id> - The resource ID for which to check the acq\_spec. This option is required.

=back

=back

Returns 1 if the acq\_spec is valid or has been successfully created/extended, undef otherwise.

=cut

=head2 get_stats

    my $value = $api->get_stats(%options);

Retrieves the latest statistics for a given resource and counter.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<rsrc_id> - The resource ID for which to retrieve statistics. This option is required.

=item * C<cid> - The counter ID for which to retrieve statistics. This option is required.

=back

=back

Returns the latest value for the specified resource and counter.

=cut

=head1 REST API OPTIONS

Command-line options for VMware vSphere 8 API:

=over 8

=item B<--hostname>

Define the hostname of the vSphere server.

=item B<--port>

Define the port of the vSphere server (default: 443).

=item B<--proto>

Define the protocol to use (default: https).

=item B<--username>

Define the username for authentication.

=item B<--password>

Define the password for authentication.

=item B<--vstats-interval>

Define the interval (in seconds) at which the C<vstats> must be recorded (default: 300).
Used to create entries at the C</api/stats/acq-specs> endpoint.

=item B<--vstats-duration>

Define the time (in seconds) after which the C<vstats> will stop being recorded (default: 2764800, meaning 32 days).
Used to create entries at the C</api/stats/acq-specs> endpoint.

=item B<--timeout>

Define the timeout for API requests (default: 10 seconds).

=back

=head1 AUTHOR

Centreon

=head1 LICENSE

Licensed under the Apache License, Version 2.0.

=cut
