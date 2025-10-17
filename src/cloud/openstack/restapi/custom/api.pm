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

package cloud::openstack::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use centreon::plugins::misc qw/json_encode json_decode value_of/;
use Digest::MD5 qw(md5_hex);
use DateTime::Format::Strptime;

# Define all specific options for a service
sub _services_options {
    my (%options) = @_;
    my $name = $options{name};

    ( $name.'-url:s'      => { name => $name.'_url', default => '' },
      $name.'-hostname:s' => { name => $name.'_hostname', default => '' },
      $name.'-proto:s'    => { name => $name.'_proto', default => 'https' },
      $name.'-port:s'     => { name => $name.'_port', default => $options{port} // '' },
      $name.'-endpoint:s' => { name => $name.'_endpoint', default => $options{endpoint} // '' },
      $name.'-insecure'   => { name => $name.'_insecure', default => '0' },
      $name.'-timeout:s'  => { name => $name.'_timeout' }
  )
}

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.")
        unless $options{options};

    $options{options}->add_options(arguments => {
        'hostname:s'        => { name => 'hostname', default => '' },
        'proto:s'           => { name => 'proto', default => 'http' },
        'insecure'          => { name => 'insecure', default => 0 },

        _services_options(name=>'keystone', port => 5000, endpoint => '/v3/auth/tokens'),

        'username:s'        => { name => 'username', default => '' },
        'password:s'        => { name => 'password', default => '' },
        'user-domain:s'     => { name => 'user_domain', default => 'default' },
        'project-name:s'    => { name => 'project_name', default => 'admin' },
        'project_domain:s'  => { name => 'project_domain', default => 'default' },
        'authent-by-env:s'  => { name => 'authent_by_env', default => '0' },
        'authent-by-file:s' => { name => 'authent_by_file', default => '' },

        'timeout:s'         => { name => 'timeout', default => 10 } } )
            unless $options{noptions};

    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');

    $self->{cache_authent} = centreon::plugins::statefile->new(%options);

    return $self;
}

# Mapping between some OptnStack environment variables and our options
my %_external_conf_equiv = ( OS_USERNAME => 'username',
                             OS_PASSWORD => 'password',
                             OS_PROJECT_DOMAIN => 'project_domain',
                             OS_USER_DOMAIN => 'user_domain',
                             OS_PROJECT_NAME => 'project_name',
                             OS_AUTH_URL => 'keystone_url',
                           );
sub apply_external_conf {
    my ($self, %options) = @_;

    # Some options can be taken from OpenStack environement variables already defined or
    # taken from a file that has been generated for OpenStack CLI tools

    if ($options{apply_conf_from_env}) {
        foreach (keys %_external_conf_equiv) {
            $self->{$_external_conf_equiv{$_}} = $ENV{$_}
                if exists $ENV{$_};
        }
    }

    if ($options{apply_conf_from_file}) {
        open(my $file, "<".$options{apply_conf_from_file})
            or $self->{output}->option_exit(short_msg => "Cannot open file '".$options{apply_conf_from_file}."': $!");
        foreach my $line (<$file>) {
            next unless $line =~ /^[\s\t]*export[\t\s]+(\w+)=["']?(.*?)["']?$/;

            # Only handle variables defined using 'export variable="value"'
            $self->{$_external_conf_equiv{$1}} = $2
                if exists $_external_conf_equiv{$1};
        }
        close($file);
    }
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{cache_authent}->check_options(option_results => $self->{option_results});

    $self->{$_} = $self->{option_results}->{$_}
        foreach qw/authent_by_env authent_by_file user_domain project_name project_domain username password insecure proto hostname timeout/;

    # Defines connection parameters for each services
    foreach my $service ('keystone_') {
        $self->{$service.$_} = $self->{option_results}->{$service.$_}
            foreach qw/url insecure endpoint port/;

        if ($self->{$service.'url'} eq '') {
            my %desc;
            $desc{$_} = $self->{option_results}->{$_}
                foreach qw/hostname proto port/;

            foreach (qw/hostname proto timeout/) {
                $desc{$_} = $self->{option_results}->{$service.$_}
                    if $self->{option_results}->{$service.$_};
            }

            $self->{$service.'url'} = $desc{proto}.'://'.$desc{hostname}.':'.$self->{$service.'port'}.$self->{$service.'endpoint'};
        } elsif ($self->{$service.'endpoint'} ne '' && $self->{$service.'url'} !~ /\Q$self->{$service.'endpoint'}\E$/) {
            $self->{$service.'url'} .= $self->{$service.'endpoint'};
        }
        $self->{$service.'insecure'} = $self->{insecure}
            unless defined $self->{$service.'insecure'};
    }
    $self->apply_external_conf(apply_conf_from_env => $self->{authent_by_env},
                               apply_conf_from_file => $self->{authent_by_file});

    # A valid keystone URL is always required since it is the authentication service
    # First part of Keystone URL is also used to define cache filename
    $self->{output}->option_exit(short_msg => 'A valid --keystone-url option is required')
        unless $self->{keystone_url} =~ /^(https?:\/\/[-\.\w:]+)/;
    $self->{keystone_base_url} = $1;
    $self->{keystone_cache_filename} = 'openstack_restapi_keystone_'.md5_hex($1);
    return 0;
}

sub settings {
    my ($self, %options) = @_;

    $self->{http}->set_options(%{$self->{option_results}});
}

sub connect_info {
    my ($self, %options) = @_;

    my $url = $options{url};

    ( full_url => $url, proto=> $url =~ s/^(https?).+/$1/r )
}

sub keystone_authent {
    my ($self, %options) = @_;

    # Authenticate to Keystone service
    # keystone also returns service list endpoints

    $self->settings();

    $self->{cache_authent}->read(statefile => $self->{keystone_cache_filename});
    my $cache_authent_data = $self->{cache_authent}->{datas};

    return $cache_authent_data
        if !$options{dont_read_cache} && ref $cache_authent_data eq 'HASH' && $cache_authent_data->{token} && $cache_authent_data->{expires_at} > time() + 60;

    my $query = {
        auth => {
            identity => {
                methods => ['password'],
                password => {
                    user => {
                        name => $self->{username},
                        domain => { id => $self->{user_domain} },
                        password => $self->{password}
                    }
                }
            },
            scope => {
                project => {
                    domain => { id => $self->{project_domain} },
                    name => $self->{project_name},
                }
            }
        }
    };
    $query = json_encode($query);

    my $response_brut = $self->{http}->request(
        method => 'POST',
        header => ['Content-Type: application/json'],
        $self->connect_info(url => $self->{keystone_url}),
        insecure => $self->{keystone_insecure},

        query_form_post => $query,

        critical_status => '',
        warning_status => '',
        unknown_status => '%{http_code} < 200 or %{http_code} >= 300'
    );

    my $response = json_decode($response_brut, output => $self->{output});

    if (ref $response ne 'HASH' || $response->{error} || not $response->{token}) {
        return { token => '', expires_at => 0, services => [] }
            if $options{discover_mode};

        $self->{output}->option_exit(short_msg => value_of($response, "->{error}->{title}", 'Bad request').': '.value_of($response, "->{error}->{message}", "Unknown error"));
    }

    my $token = $self->{http}->get_header(name => 'X-Subject-Token');

    $self->{output}->option_exit(short_msg => 'Bad request: Cannot find X-Subject-Token header')
        unless $token;
    my $expires_at = DateTime::Format::Strptime->new(
        pattern  => "%Y-%m-%dT%H:%M:%S.%N%Z",
        on_error => "undef"
    );
    $expires_at = $expires_at->parse_datetime($response->{token}->{expires_at});
    $expires_at = $expires_at->epoch();

    my %data = ( token => $token,
                 expires_at => $expires_at,
                 services => $response->{token}->{catalog}
               );

    $self->{cache_authent}->write(data => \%data);

    return \%data;
}

# Extra suffix to append to the endpoint URL for service health check
# Goal is to get a small response who requires authentication token
my %_endpoint_suffix = ( 'volumev2' => '/volumes?limit=1',
                         'volumev3' => '/volumes?limit=1',
                         'image'    => '/v2/images?limit=1',
                         'compute'  => '/v2.1',
                         'placement'=> '/resource_providers?name=ping',
                         'identity' => '/users?limit=1' );

# Horizon returns a HTML web page not JSON, so we check that it contains those strings
my %_expected_data = ( 'horizon'    => 'OpenStack Dashboard',
                       'dashboard'  => 'OpenStack Dashboard' );

sub ping_service
{
    # Heath check of an OpenStack service
    # We test HTTP status code and the content of the data returned by the service
    # (is valid JSON or that it contains specific strings).
    my ($self, %options) = @_;

    $options{$_} //= '' foreach qw/endpoint_suffix expected_data/;

    my $service_url = $options{service_url};

    my $endpoint_suffix = $options{endpoint_suffix} eq 'auto' ?
                            $_endpoint_suffix{$options{type}} // '' :
                            $options{endpoint_suffix} eq 'none' ?
                                '' :
                                $options{endpoint_suffix};

    $service_url .= $endpoint_suffix
            if $endpoint_suffix ne '' && $service_url !~ /\Q$endpoint_suffix\E$/;

    my $expected_data = '';
    if ($options{expected_data} eq 'auto') {
        $expected_data = $_expected_data{$options{type}} // '';
    } elsif ($options{expected_data} ne '') {
        $expected_data = $options{expected_data};
    }

    my $response_brut = eval {$self->{http}->request(
        method => 'GET',
        $self->connect_info(url => $service_url),
        insecure => $options{insecure} || 0,
        silently_fail => 1,
        header => [ 'X-Auth-Token: '.$options{token} ],
        critical_status => '',
        warning_status => '',
        unknown_status => ''
    ) };

    my $valid;
    if ($expected_data ne '') {
        $valid = $response_brut =~ /$expected_data/ ? 1 : 0;
    } else {
        $valid = json_decode($response_brut, silence => 1) ? 1 : 0;
    }

    my $data = { http_status => $self->{http}->get_code(),
                 http_status_message => $self->{http}->get_message(),
                 valid_content => $valid
    };

    return $data;
}

1;

__END__

=head1 NAME

Openstack REST API

=head1 SYNOPSIS

Openstack Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--username>

OpenStack username.

=item B<--password>

OpenStack password.

=item B<--user-domain>

OpenStack user domain to use with authentication (default: 'default').

=item B<--project-name>

OpenStack project name to use with authentication (default: 'default').

=item B<--project-domain>

OpenStack project domain to use with authentication (default: 'default').

=item B<--timeout>

Set HTTP timeout in seconds (default: '10').
This timeout will only be used for other services if a more specific one is not already defined with other options.

=item B<--insecure>

Allow insecure TLS connection (default: '0').
This value will only be used for other services if a more specific one is not already defined with other options.

=item B<--authent-by-env>

Set to 1 to use OpenStack environment variables if they are defined (default: 0).
Used environment variables are OS_USERNAME, OS_PASSWORD, OS_PROJECT_DOMAIN, OS_USER_DOMAIN, OS_PROJECT_NAME, OS_AUTH_URL.

=item B<--authent-by-file>

Read OpenStack environment variables from a file.
Handled environment variables are OS_USERNAME, OS_PASSWORD, OS_PROJECT_DOMAIN, OS_USER_DOMAIN, OS_PROJECT_NAME, OS_AUTH_URL.
Those variables must be defined using 'export VARIABLE="value"' syntax.

=item B<--hostname>

Set default OpenStack service hostname. This hostname will only be used for other services if a more specific one is not already defined with other options.

=item B<--proto>

Set default protocol to use (default: 'https').
This protocol will only be used for other services if a more specific one is not already defined with other options.

=item B<--keystone-url>

Set the URL to use for the OpenStack Keystone service.
A valid Keystone URL is required since it is the authentication service.
The first part of the Keystone URL is also used to define the cache filename.

Example: C<--keystone-url="https://myopenstack.local:5000">

This URL can alos be construct with options (--keystone-hostname, --keystone-proto, --keystone-port, --keystone-endpoint).

=item B<--keystone-hostname>

Set the hostname part of the Keystone service URL.

=item B<--keystone-proto>

Set the protocol to use in the Keystone service URL (default: 'https').

=item B<--keystone-port>

Set the port to use in the Keystone service URL (default: 5000).

=item B<--keystone-endpoint>

Set the endpoint to use in the Keystone service URL (default: '/v3/auth/tokens').

=item B<--keystone-insecure>

Allow insecure TLS connection (default: '0').
When set to 0 the default insecure value passed with --insecure is used.

=item B<--keystone-timeout>
Set HTTP timeout in seconds (default: '0').
When set to 0 the default timeout value passed with --timeout is used.

=back

=head1 DESCRIPTION

B<custom>.

=cut
