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
            'hostname:s'                  => { name => 'hostname', not_empty => 1 },
            'port:s'                      => { name => 'port', default => '443' },
            'proto:s'                     => { name => 'proto', default => 'https' },
            'username:s'                  => { name => 'username', not_empty => 1 },
            'password:s'                  => { name => 'password' },
            'timeout:s'                   => { name => 'timeout', default => 10 },
            'api-url:s'                   => { name => 'api_url', default => '/rest/v0/' },
            'header:s@'                   => { name => 'header' },
            'reload-cache-time:s'         => { name => 'reload_cache_time', default => 1440 },
            'create-xoa-read-only-user'   => {name => 'create_xoa_read_only_user'}
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
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{statefile_cache}->check_options(option_results => $self->{option_results});
    # set auth header
    $self->{auth_header} = MIME::Base64::encode_base64($self->{option_results}->{username} . ':' . $self->{option_results}->{password}, '');
    chomp($self->{auth_header});
    # registered through add_header (not passed to request()) so it merges with, instead of
    # overriding, any --header value supplied on the command line.
    $self->{http}->add_header(key => 'Authorization', value => 'Basic ' . $self->{auth_header});

    # allow to create an user in Xen orchestra api and exit once the user created.
    $self->create_user_and_exit() if ($self->{option_results}->{create_xoa_read_only_user});
    return 0;
}
# prompt_stdin(label => '...')
# Reads one line from STDIN, bounded by --timeout so a run without an attended
# terminal (cron, empty pipe) does not hang the plugin forever.
sub prompt_stdin {
    my ($self, %options) = @_;

    my $value;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n"; };
        alarm($self->{option_results}->{timeout});
        local $| = 1;
        print $options{label} . ': ';
        $value = <STDIN>;
        alarm(0);
    };
    alarm(0);
    if ($@) {
        $self->{output}->option_exit(
            short_msg => "No input received for '" . $options{label} . "' after " . $self->{option_results}->{timeout} . 's, aborting.'
        );
    }
    if (is_empty($value)) {
        $self->{output}->option_exit(short_msg => "No value provided for '" . $options{label} . "', aborting.");
    }
    chomp($value);
    return $value;
}

# create_user_and_exit()
# Interactively creates a read-only Xen Orchestra user: asks for the new
# user's name/password on STDIN (each bounded by --timeout, see prompt_stdin),
# creates it through the REST API, then duplicates the 'read only' ACL role
# template and attaches the copy to that user.
sub create_user_and_exit {
    my ($self) = @_;

    my $username = $self->prompt_stdin(label => 'Name of the read-only Xen Orchestra user to create');
    my $password = $self->prompt_stdin(label => 'Password for that user');

    my $created_user = json_decode(
        $self->request_api(
            endpoint        => 'users',
            method          => 'POST',
            unknown_status    => '',
            query_form_post => json_encode(
                { name => $username, password => $password, permission => 'none' },
                output => $self->{output}
            ),
            header => ['Content-Type: application/json']
        ),
        output => $self->{output}
    );
    if (is_not_empty($created_user->{error})) {
        if ($created_user->{error} =~ /the user .* already exists/) {
            $self->{output}->option_exit(
                short_msg => "user $username already exist, nothing to do.",
                exit_litteral => "ok");
        }
           $self->{output}->option_exit(
               short_msg => "API error : " . $created_user->{error},
               exit_litteral => "unknown");
    }
    if (is_empty($created_user) or is_empty($created_user->{id})) {
        $self->{output}->option_exit(short_msg => "Could not create user '$username' on the Xen Orchestra API (no id returned).");
    }
    print "User '$username' created (id: $created_user->{id}).\n";

    my $roles = $self->request_api_get(
        endpoint  => 'acl-roles',
        get_param => ['fields=id,name,isTemplate', 'filter=name:read only']
    );
    my $read_only_role;
    if (ref($roles) eq 'ARRAY') {
        for my $role (@$roles) {
            if (lc($role->{name}) eq 'read only') {
                $read_only_role = $role;
                last;
            }
        }
    }
    if (!defined($read_only_role)) {
        $self->{output}->option_exit(short_msg => "Could not find the 'read only' ACL role template on the Xen Orchestra API.");
    }
    print "'read only' ACL role template id: $read_only_role->{id}\n";

    # the template role itself cannot be assigned to a user: it has to be
    # duplicated into a plain (non-template) role first.
    my $copied_role = json_decode(
        $self->request_api(
            endpoint        => 'acl-roles/' . $read_only_role->{id} . '/actions/copy',
            method          => 'POST',
            get_param       => ['sync=true'],
            query_form_post => json_encode(
                { name => $username . ' - read only' },
                output => $self->{output}
            ),
            header => ['Content-Type: application/json']
        ),
        output => $self->{output}
    );
    if (is_empty($copied_role) or is_empty($copied_role->{id})) {
        $self->{output}->option_exit(short_msg => "Could not duplicate the 'read only' ACL role template on the Xen Orchestra API.");
    }
    print "'read only' role duplicated for '$username' (id: $copied_role->{id}).\n";

    $self->request_api(
        endpoint => 'acl-roles/' . $copied_role->{id} . '/users/' . $created_user->{id},
        method   => 'PUT'
    );
    print "Role '$copied_role->{id}' attached to user '$username' (id: $created_user->{id}). You can now use this user in Centreon Infra Monitoring configuration\n";
}
    exit 0;
sub request_api {
    my ($self, %options) = @_;

     my ($content) = $self->{http}->request(
         method          => $options{method},
         url_path        => $self->{option_results}->{api_url} . $options{endpoint},
         %options
     );
    return $content;

}

sub request_api_get {
    my ($self, %options) = @_;

    my ($content) = $self->request_api(%options, method => "GET");

    return json_decode($content, booleans_as_strings => 1, output => $self->{output});
}

# return one object from the Rest api by filtering on a parametrized field of the object
# The Xen Orchestra api does a substring match and not a strict match.
# options:
# fields : GET parameter of the same name to filter output format (define which property the vates api should send back)
# filter => [filter_name, filter_value]  array containing the field on which to filter object as first element, and the value expected as second element.
# other options : see centreon::plugins::http::request for other allowed parameters. Most useful are :
# endpoint  => $options{api_endpoint},
# get_param => [ 'fields=uuid,name_label', 'filter=' . $filter]
# silently_fail => 1
#
# return : either exit the plugin or one object (hashmap ref)
sub request_api_get_one {
    my ($self, %options) = @_;
    my $fields = $options{fields} // "*";
    my ($filter_field,$filter_value) = ('','');
    $filter_field = $options{filter}->[0] // '';
    $filter_value = $options{filter}->[1] // '';

    if (!defined($options{get_param})) {
        $options{get_param} = ['fields=' . $fields];
    }
    # Override api filtering only if not present.
    if (!grep(/^filter=/, @{$options{get_param}})) {
        push(@{$options{get_param}}, "filter=" . $filter_field . ":" . $filter_value);
    }
    my ($content) = $self->request_api(%options, method => "GET");
    my $response = json_decode($content, booleans_as_strings => 1);
    if (!defined($response) or ref($response) ne "ARRAY"){
        $self->{output}->option_exit(short_msg => "no object '$options{filter_value}' found, api did not return an array with one element. Please check filtering parameter or --debug.");
    }
    return $response->[0] if scalar @$response == 1;
    for my $obj (@$response) {
        return $obj if $obj->{$filter_field} eq $filter_value;
    }
    $self->{output}->option_exit(short_msg => "no object '$filter_value' found. Please check filtering parameter or --debug.");
}

# get_name_and_uuid( type => 'pool', 'api_endpoint' => 'pools');Z
# check --{type}-name and --{type}-uuid and retrieve the other value from the api.
# it caches the mapping on disk for --reload-cache-time second
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
        my ($filter_value, $filter_name);
        if (is_not_empty($self->{option_results}->{$obj_name})) {
            $filter_name = "name_label";
            $filter_value = $self->{option_results}->{$obj_name};
        }
        else {
            $filter_name = "uuid";
            $filter_value = $self->{option_results}->{$obj_uuid};
        }
        my $response = $self->request_api_get_one(
            endpoint  => $options{api_endpoint} // $options{type},
            fields    => 'uuid,name_label',
            filter  => [$filter_name, $filter_value],
        );

        $cached_uuid = {uuid => $response->{uuid}, name_label =>  $response->{name_label} };
        $self->{statefile_cache}->write(data => { values => $cached_uuid, last_timestamp => time() });
    }

    return $cached_uuid;
}

# Storage repository don't show directly which host name it live on. Physical Block Devices are a glue between host and SR
# this allows to cache the PBD uuid and host name_label relation for easier access.
sub get_pbd_to_host {
    my ($self, %options) = @_;
    my $cache_time = $options{cache_time}  // 0;
    my $has_cache_file = $self->{statefile_cache}->read(
        statefile => 'vates_uuid_to_name' . sha1_hex(
            $self->{option_results}->{hostname} . '_' .
                $self->{option_results}->{username})
    );
    my $cached_pbd_host = $self->{statefile_cache}->get(name => 'values');
    my $last_timestamp = $self->{statefile_cache}->get(name => 'last_timestamp');

    if ($has_cache_file == 0
        or !defined($cached_pbd_host)
        or (time() - $last_timestamp) > ($cache_time * 60)) {

        my $hosts_response = $self->request_api_get(
            endpoint  => 'hosts',
            get_param => ['fields=name_label,uuid']
        );
        my $hosts = {};
        for my $host (@$hosts_response){
            $hosts->{$host->{uuid}} = $host->{name_label};
        }
        my $pbds_response = $self->request_api_get(
            endpoint  => 'PBDS',
            get_param => ['fields=uuid,host']
        );
        my $pbds = {};
        for my $pbd (@$pbds_response){
            $pbds->{$pbd->{uuid}} = $hosts->{$pbd->{host}};
        }
        $cached_pbd_host = $pbds;
        $self->{statefile_cache}->write(data => { values => $cached_pbd_host, last_timestamp => time() });

    }
    return $cached_pbd_host;
}

# used to get overview of one vm with power state, and uuid/name
sub get_vm_info {
    my ($self, %options) = @_;

    my $fields = "name_label,power_state,uuid,os_version";

    my ($filter_name, $filter_value) = ('uuid', $self->{option_results}->{vm_uuid});
    # default filter use uuid, or name if not present.
    if (is_empty($self->{option_results}->{vm_uuid})){
        ($filter_name, $filter_value) = ('name_label', $self->{option_results}->{vm_name});
    }
    my $response = $self->request_api_get_one(
        endpoint  => "vms",
        "fields" => $fields,
        "filter" => [$filter_name, $filter_value ],
    );
    return $response;
}

# used by the host modes to get one host's data, resolving --host-uuid or --host-name.
# %options input :
#   fields: comma separated list of fields to request from the API (defaults to the minimal status fields)
sub get_host_info {
    my ($self, %options) = @_;

    my $fields = $options{fields} // "name_label,enabled,power_state,uuid";

    # default filter use uuid, or name if not present.
    my ($filter_field, $filter_value) = ('uuid', $self->{option_results}->{host_uuid});
    if (is_empty($self->{option_results}->{host_uuid})) {
        ($filter_field, $filter_value) = ('name_label', $self->{option_results}->{host_name});
    }
    return $self->request_api_get_one(
        endpoint  => "hosts",
        fields => $fields,
        filter =>[$filter_field, $filter_value ],
    );

}
# Some api answers can contain empty value as tag, this remove them.
sub clean_tags_array {
    my ($self, $tags) = @_;
    my @result = ();
    for my $tag (@{$tags}) {
        if (is_not_empty($tag)) {
            push(@result, $tag);
        }
    }
    return @result;
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

=head2 get_pbd_to_host

    my $pbds = $api->get_pbd_to_host(cache_time => 0);

Resolves Physical Block Devices C<PBD> to the host name_label they are on.
Can cache result if C<cache_time> is set. (no cache by default).
Mainly useful for storage repository which don't output hosts name they are present on.

=head2 get_vm_info

    my $vm = $api->get_vm_info();

Resolves C<--vm-uuid>/C<--vm-name> and returns the matching VM's C<name_label>, C<power_state>,
C<uuid> and C<os_version> fields. Always live (not cached), since C<power_state> can change at
any time.

=head2 request_api_get_one

    my $obj = $api->request_api_get(
    endpoint => 'vms',
    fields => 'uuid,name_label',
    filter => ['name_label', 'name_in_XOA_app]);

Performs a GET request against C<< <api-url><endpoint> >> and decodes the JSON response.
Filter the returned array to return only one element. If filtering is not possible, exit the plugin.

=head2 get_host_info

    my $host = $api->get_host_info(fields => 'name_label,enabled,power_state,memory');

Resolves C<--host-uuid>/C<--host-name> and returns the matching host's fields (the caller picks
which fields to request, since the status/cpu/memory host modes each need a different subset).
Always live (not cached).

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

=item B<--create-xoa-read-only-user>

Allow to interactively create a read-only user in Xen Orchestra. exit upon user creation completion.

=back

=cut
