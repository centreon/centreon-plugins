#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package hardware::server::cisco::ucs::redfish::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);
use MIME::Base64;

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        print "Class Custom: Need to specify 'options' argument.\n";
        exit 3;
    }

    $self->{output}  = $options{output};
    $self->{options} = $options{options};
    $self->{http}    = centreon::plugins::http->new(%options);
    $self->{cache}   = centreon::plugins::statefile->new(%options);
    $self->{token}   = undef;

    $options{options}->add_options(arguments => {
        'hostname:s' => { name => 'hostname' },
        'port:s'     => { name => 'port' },
        'proto:s'    => { name => 'proto' },
        'username:s' => { name => 'username' },
        'password:s' => { name => 'password' },
        'timeout:s'  => { name => 'timeout' },
        'api-path:s' => { name => 'api_path', default => '/redfish/v1' },
        'ssl-opt:s@' => { name => 'ssl_opt' },
    });

    return $self;
}

sub set_options {
    my ($self, %options) = @_;
    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = $self->{option_results}->{hostname} // '';
    $self->{port}     = $self->{option_results}->{port}     // 443;
    $self->{proto}    = $self->{option_results}->{proto}    // 'https';
    $self->{username} = $self->{option_results}->{username} // '';
    $self->{password} = $self->{option_results}->{password} // '';
    $self->{timeout}  = $self->{option_results}->{timeout}  // 30;
    $self->{api_path} = $self->{option_results}->{api_path} // '/redfish/v1';

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{username} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --username option.');
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});
    return 0;
}

sub _authenticate {
    my ($self, %options) = @_;

    my $json_body = JSON::XS->new->encode({
        UserName => $self->{username},
        Password => $self->{password},
    });

    my $content = $self->{http}->request(
        method          => 'POST',
        hostname        => $self->{hostname},
        port            => $self->{port},
        proto           => $self->{proto},
        url_path        => $self->{api_path} . '/SessionService/Sessions',
        timeout         => $self->{timeout},
        header          => ['Content-Type: application/json', 'Accept: application/json'],
        query_form_post => $json_body,
        unknown_status  => '',
        warning_status  => '',
        critical_status => '',
    );

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => 'Redfish: no response during authentication.');
        $self->{output}->option_exit();
    }

    # X-Auth-Token is normally returned as a response header
    my $token = $self->{http}->get_header(name => 'X-Auth-Token');

    # Fallback: some UCS implementations return the token in the JSON body
    if (!defined($token) || $token eq '') {
        eval {
            my $data = JSON::XS->new->decode($content);
            $token = $data->{'Token'} // $data->{'X-Auth-Token'};
        };
    }

    if (!defined($token) || $token eq '') {
        # Last resort: fall back to HTTP Basic Auth (no session tokens)
        $self->{use_basic_auth} = 1;
        return undef;
    }

    $self->{cache}->write(data => {
        token      => $token,
        expires_in => time() + 1740,  # 29 min
    });

    return $token;
}

sub _get_token {
    my ($self, %options) = @_;

    return undef if $self->{use_basic_auth};

    my $has_cache  = $self->{cache}->read(statefile => 'cisco_ucs_redfish_' . md5_hex($self->{hostname} . $self->{username}));
    my $token      = $self->{cache}->get(name => 'token');
    my $expires_in = $self->{cache}->get(name => 'expires_in');

    if ($has_cache == 0 || !defined($token) || $token eq '' || (defined($expires_in) && time() > $expires_in)) {
        $token = $self->_authenticate();
    }

    return $token;
}

# GET a Redfish endpoint, return the decoded JSON as a hashref
sub request {
    my ($self, %options) = @_;
    # options: endpoint => '/Systems'  (relative to api_path)

    my $token = $self->_get_token();

    my @headers = ('Accept: application/json');
    if (defined $token) {
        push @headers, "X-Auth-Token: $token";
    } else {
        my $b64 = encode_base64("$self->{username}:$self->{password}", '');
        push @headers, "Authorization: Basic $b64";
    }

    my $url = $self->{api_path} . $options{endpoint};

    my $content = $self->{http}->request(
        method          => 'GET',
        hostname        => $self->{hostname},
        port            => $self->{port},
        proto           => $self->{proto},
        url_path        => $url,
        timeout         => $self->{timeout},
        header          => \@headers,
        unknown_status  => '',
        warning_status  => '',
        critical_status => '',
    );

    my $http_code = $self->{http}->get_code();

    # Token expired -> re-authenticate once and retry
    if (defined($http_code) && $http_code == 401) {
        $self->{cache}->write(data => { token => '', expires_in => 0 });
        $token = $self->_authenticate();
        @headers = ('Accept: application/json');
        if (defined $token) {
            push @headers, "X-Auth-Token: $token";
        } else {
            my $b64 = encode_base64("$self->{username}:$self->{password}", '');
            push @headers, "Authorization: Basic $b64";
        }

        $content = $self->{http}->request(
            method          => 'GET',
            hostname        => $self->{hostname},
            port            => $self->{port},
            proto           => $self->{proto},
            url_path        => $url,
            timeout         => $self->{timeout},
            header          => \@headers,
            unknown_status  => '',
            warning_status  => '',
            critical_status => '',
        );
    }

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "Redfish: no response for endpoint '$url'.");
        $self->{output}->option_exit();
    }

    my $data;
    eval { $data = JSON::XS->new->decode($content); };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Redfish: cannot parse JSON for '$url': $@");
        $self->{output}->option_exit();
    }

    return $data;
}

# Fetch a collection and return an arrayref of fully resolved member objects
sub get_collection {
    my ($self, %options) = @_;
    # options: endpoint => '/Systems'

    my $collection = $self->request(endpoint => $options{endpoint});
    my @members;

    for my $member (@{$collection->{'Members'} // []}) {
        my $member_url = $member->{'@odata.id'} // '';
        next if $member_url eq '';

        # Strip api_path prefix if present (request() re-adds it)
        $member_url =~ s{^\Q$self->{api_path}\E}{};

        my $obj = $self->request(endpoint => $member_url);
        push @members, $obj;
    }

    return \@members;
}

1;

__END__

=head1 NAME

hardware::server::cisco::ucs::redfish::custom::api - Cisco UCS Redfish API custom mode.

=head1 SYNOPSIS

Handles the Redfish session (X-Auth-Token, with HTTP Basic Auth fallback),
GET requests and collection navigation.

=head1 REDFISH API OPTIONS

=over 8

=item B<--hostname>

UCS server / CIMC IP address or FQDN.

=item B<--port>

HTTPS port (default: 443).

=item B<--proto>

Protocol: http or https (default: https).

=item B<--username>

Redfish username.

=item B<--password>

Redfish password.

=item B<--api-path>

Base Redfish path (default: /redfish/v1).

=item B<--timeout>

HTTP request timeout in seconds (default: 30).

=back

=cut
