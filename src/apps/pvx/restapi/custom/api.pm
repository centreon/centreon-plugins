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

package apps::pvx::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use DateTime;
use URI::Encode;
use centreon::plugins::misc qw/is_empty json_decode value_of/;
use centreon::plugins::statefile;
use Digest::SHA qw(sha256_hex);

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
        $options{options}->add_options(arguments => {
            'api-key:s'          => { name => 'api_key',          default => '' },
            'default-value:s'    => { name => 'default_value' },
            'hostname:s'         => { name => 'hostname',         default => '' },
            'url-path:s'         => { name => 'url_path',         default => '/api' },
            'auth-service-url:s' => { name => 'auth_service_url', default => '/api/v1/auth/login' },
            'port:s'             => { name => 'port',             default => 443 },
            'proto:s'            => { name => 'proto',            default => 'https' },
            'credentials'        => { name => 'credentials' },
            'basic'              => { name => 'basic' },
            'username:s'         => { name => 'username',         default => '' },
            'password:s'         => { name => 'password',         default => '' },
            'use-auth-service'   => { name => 'use_auth_service' },
            'timeout:s'          => { name => 'timeout',          default => 10 },
            'timeframe:s'        => { name => 'timeframe',        default => 1 },
            'timezone:s'         => { name => 'timezone',         default => 'UTC' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{$_} = $self->{option_results}->{$_}
        foreach qw/api_key hostname port proto url_path timeout username password timeframe timezone auth_service_url/;

    $self->{credentials} = (defined($self->{option_results}->{credentials})) ? 1 : undef;
    $self->{basic} = (defined($self->{option_results}->{basic})) ? 1 : undef;

    $self->{output}->option_exit(short_msg => "Need to specify hostname option.")
        if is_empty($self->{hostname});

    $self->{cache}->check_options(option_results => $self->{option_results});

    # Three authentication methods are supported: legacy username/password, API key, and username/password via
    # the authentication server
    $self->{use_auth_service} = $self->{option_results}->{use_auth_service} // 0;

    $self->{output}->option_exit(short_msg => "You must provide either username/password or an API key.")
        unless ($self->{username} && $self->{password}) || $self->{api_key};

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{$_} = $self->{$_}
        foreach qw/hostname timeout port proto/;

    unless ($self->{use_auth_service}) {
        # Those options are no longer used by the plugin when we use auth service
        $self->{option_results}->{$_} = $self->{$_}
            foreach qw/credentials basic username password/;
    }

    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
}

sub auth_service_login {
    my ($self, %options) = @_;
    my $content = $self->{http}->request( url_path => $self->{auth_service_url},
                                          method => 'POST',
                                          post_params => { username => $self->{username},
                                                           password => $self->{password}
                                                         }
                                        );

    my $key = $self->{http}->get_header(name => 'authorization');

    $self->{output}->option_exit(short_msg => "Authentication failed")
        if $self->{http}->get_code() == 401;

    $self->{output}->option_exit(short_msg => "Authentication error: ". ($self->{http}->get_message() || "Unknown error"))
        if is_empty($key);

    $self->{bearer_token} = $key // '';

    $self->{cache}->write(data => { bearer_token => $self->{bearer_token} });
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib(%options);
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'PVX-Authorization', value => $self->{api_key})
        unless $self->{use_auth_service};
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{hostname} . ":" . $self->{port};
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub get_port {
    my ($self, %options) = @_;

    return $self->{port};
}

sub query_range {
    my ($self, %options) = @_;

    my $tz = centreon::plugins::misc::set_timezone(name => $self->{timezone});
    my $dt = DateTime->now(%$tz);
    my $start_time = $dt->epoch() - $options{timeframe};
    my $end_time = $dt->epoch();
    my $uri = URI::Encode->new({encode_reserved => 1});

    my $query = sprintf('%s SINCE %s UNTIL %s', $options{query}, $start_time, $end_time);
    $query .= sprintf(' BY %s', $options{instance}) if (defined($options{instance}) && $options{instance} ne '');
    $query .= sprintf(' WHERE %s', $options{filter}) if (defined($options{filter}) && $options{filter} ne '');
    $query .= sprintf(' FROM %s', $options{from}) if (defined($options{from}) && $options{from} ne '');
    $query .= sprintf(' TOP %s', $options{top}) if (defined($options{top}) && $options{top} ne '');

    my $result = $self->get_endpoint(url_path => '/query?expr=' . $uri->encode($query));

    if (defined($self->{option_results}->{default_value}) && $options{filter} ne '' && !exists($result->{data})) {
        $options{filter} =~ /\s*([^\s\\]+)\s*=\s*\"(.*)\"/;
        $result->{data} = [
            { key => [ { value => $2 } ] },
            { values => [ { value => $self->{option_results}->{default_value} } ] }
        ];
    }

    return $result->{data};
}

sub get_endpoint {
    my ($self, %options) = @_;

    $self->settings;

    if ($self->{use_auth_service} && is_empty($self->{bearer_token})) {
        $self->{cache}->read(statefile => 'pvx_restapi_' . sha256_hex($self->{hostname}.'_'.$self->{username}));
        $self->{bearer_token} = $self->{cache}->get(name => 'bearer_token');
    }

    my $retry = ! is_empty($self->{bearer_token});
    my $response;

    while (1) {
        if ($self->{use_auth_service} && is_empty($self->{bearer_token})) {
            $self->auth_service_login(%options);

            $self->{output}->option_exit(short_msg => "Authentication failed: No token received.")
                if is_empty($self->{bearer_token});
            $self->{http}->add_header(key => 'Authorization', value => $self->{bearer_token});
        }

        $response = $self->{http}->request(url_path => $self->{url_path} . $options{url_path},
                                           header => [ 'content-type:application/x-www-form-urlencoded' ],
                                           unknown_status => '');

        if ($self->{use_auth_service} && $retry && $self->{http}->get_code() == 401) {
            undef $self->{bearer_token};
            undef $retry;
            next
        }

        last
    }

    $self->{output}->option_exit(short_msg => "Cannot get data: " . $self->{http}->get_message())
        if $self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300;

    my $content = json_decode($response, output => $self->{output});

    $self->{output}->option_exit(short_msg => "Cannot get data: " . value_of($content, "->{error}", "Unknown error"))
        if ref $content ne 'HASH' || ($content->{type} && $content->{type} eq 'error');

    return $content->{result};
}

1;

__END__

=head1 NAME

Skylight Performance Analytics (previously PVX) REST API

=head1 SYNOPSIS

Skylight Performance Analytics (previously PVX) Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--default-value>

Set a default value when nothing returned by PVX API

=item B<--timeframe>

Set timeframe in seconds (i.e. 3600 to check last hour).

=item B<--timezone>

Set your timezone. 
Can use format: 'Europe/London' or '+0100'.

=item B<--use-auth-service>

Three authentication methods are supported: legacy username/password, API key, and username/password via the authentication server.
Starting with Accedian Skylight version 17 and later authentication must be performed via the authentication server using this --use-auth-service parameter.

=item B<--auth-service-url>

Authentication service URL (default: '/api/v1/auth/login')

=item B<--api-key>

PVX API key.

=item B<--hostname>

PVX hostname.

=item B<--url-path>

PVX url path (default: '/api')

=item B<--port>

API port (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--username>

Specify the username for authentication

=item B<--password>

Specify the password for authentication

=item B<--basic>

Specify this option if you access the API over basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your web server.

Specify this option if you access the API over hidden basic authentication or you'll get a '404 NOT FOUND' error.

(use with --credentials)

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
