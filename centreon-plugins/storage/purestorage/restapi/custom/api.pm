#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package storage::purestorage::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

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
            'hostname:s' => { name => 'hostname' },
            'username:s' => { name => 'username' },
            'password:s' => { name => 'password' },
            'timeout:s'  => { name => 'timeout' },
            'api-path:s' => { name => 'api_path' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname}   = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : undef;
    $self->{username}   = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : undef;
    $self->{password}   = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : undef;
    $self->{timeout}    = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_path}   = (defined($self->{option_results}->{api_path})) ? $self->{option_results}->{api_path} : '/api/1.11';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';
 
    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{username})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify username option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{password})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify password option.");
        $self->{output}->option_exit();
    }

    return 0;
}

sub get_connection_infos {
    my ($self, %options) = @_;
    
    return $self->{hostname}  . '_' . $self->{http}->get_port();
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = 443;
    $self->{option_results}->{proto} = 'https';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    if (defined($self->{session_id})) {
        $self->{http}->add_header(key => 'Cookie', value => 'session=' . $self->{session_id});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request_api {
    my ($self, %options) = @_;

    my $content = $self->{http}->request(
        method => $options{method},
        url_path => $options{url_path},
        query_form_post => $options{query_form_post},
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status}
    );

    my $decoded;
    eval {
        $decoded = decode_json($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub get_api_token {
    my ($self, %options) = @_;
    
    my $json_request = { username => $self->{username}, password => $self->{password} };
    my $encoded;
    eval {
        $encoded = encode_json($json_request);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode json request");
        $self->{output}->option_exit();
    }

    $self->settings();
    my $decoded = $self->request_api(
        method => 'POST',
        url_path => $self->{api_path} . '/auth/apitoken',
        query_form_post => $encoded
    );
    if (!defined($decoded->{api_token})) {
        $self->{output}->add_option_msg(short_msg => "Cannot get api token");
        $self->{output}->option_exit();
    }
    
    return $decoded->{api_token};
}

sub get_session {
    my ($self, %options) = @_;
    
    my $json_request = { api_token => $options{api_token} };
    my $encoded;
    eval {
        $encoded = encode_json($json_request);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode json request");
        $self->{output}->option_exit();
    }

    $self->settings();
    my $decoded = $self->request_api(method => 'POST', url_path => $self->{api_path} . '/auth/session', query_form_post => $encoded);
    my ($cookie) = $self->{http}->get_header(name => 'Set-Cookie');
    if (!defined($cookie)) {
        $self->{output}->add_option_msg(short_msg => "Cannot get session");
        $self->{output}->option_exit();
    }
    
    $cookie =~ /session=(.*);/;
    return $1;
}

sub connect {
    my ($self, %options) = @_;

    my $api_token = $self->get_api_token();
    $self->{session_id} = $self->get_session(api_token => $api_token);
}

sub get_object {
    my ($self, %options) = @_;

    if (!defined($self->{api_token})) {
        $self->connect();
    }

    $self->settings();
    return $self->request_api(method => 'GET', url_path => $self->{api_path} . $options{path});
}

sub DESTROY {
    my $self = shift;

    if (defined($self->{session_id})) {
        $self->request_api(method => 'DELETE', url_path => $self->{api_path} . '/auth/session');
    }
}

1;

__END__

=head1 NAME

Pure Storage REST API

=head1 SYNOPSIS

Pure Storage Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Pure Storage hostname.

=item B<--username>

Pure Storage username.

=item B<--password>

Pure Storage password.

=item B<--timeout>

Set HTTP timeout in seconds (Default: '10').

=item B<--api-path>

API base url path (Default: '/api/1.11').

=back

=head1 DESCRIPTION

B<custom>.

=cut
