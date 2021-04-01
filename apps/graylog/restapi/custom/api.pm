#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package apps::graylog::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
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
        $options{options}->add_options(arguments =>  {
            'hostname:s'             => { name => 'hostname' },
            'url-path:s'             => { name => 'url_path' },
            'port:s'                 => { name => 'port' },
            'proto:s'                => { name => 'proto' },
            'api-username:s'         => { name => 'api_username' },
            'api-password:s'         => { name => 'api_password' },
            'timeout:s'              => { name => 'timeout' },
            'requested-by:s'         => { name => 'requested_by' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 9000;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'http';
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/api/';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{requested_by} = (defined($self->{option_results}->{requested_by})) ? $self->{option_results}->{requested_by} : 'cli';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-username option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-password option.');
        $self->{output}->option_exit();
    } 

    $self->{cache}->check_options(option_results => $self->{option_results});
    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'X-Requested-By', value => $self->{requested_by});
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

sub json_decode {
    my ($self, %options) = @_;

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($options{content});
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub clean_session_token {
    my ($self, %options) = @_;

    my $datas = {};
    $options{statefile}->write(data => $datas);
    $self->{session_token} = undef;
}

sub authenticate {
    my ($self, %options) = @_;
   
    my $has_cache_file = $options{statefile}->read(statefile => 'graylog_api_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{api_username}));
    my $session_token = $options{statefile}->get(name => 'session_token');

    if ($has_cache_file == 0 || !defined($session_token)) {
        my $json_request = {
            username => $self->{api_username},
            password => $self->{api_password},
            host => $self->{hostname}
        };

        my $encoded;
        eval {
            $encoded = encode_json($json_request);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => 'cannot encode json request');
            $self->{output}->option_exit();
        }

        my ($content) = $self->{http}->request(
            method => 'POST',
            url_path => $self->{url_path} . 'system/sessions/',
            query_form_post => $encoded, 
            warning_status => '',
            unknown_status => '',
            critical_status => ''
        );

        if ($self->{http}->get_code() != 200) {
            $self->{output}->add_option_msg(short_msg => "login error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my $decoded = $self->json_decode(content => $content);

        if (!defined($decoded) || !defined($decoded->{session_id})) {
            $self->{output}->add_option_msg(short_msg => 'error retrieving session_token');
            $self->{output}->option_exit();
        }
       
        $session_token = $decoded->{session_id};

        my $datas = { session_token => $session_token };
        $options{statefile}->write(data => $datas);
    }

    $self->{session_token} = $session_token;
}

sub query_relative {
    my ($self, %options) = @_;

    my $content = $self->request_api(
        endpoint => 'search/universal/relative',
        get_param => ['query=' . $options{query}, 'range=' . $options{timeframe}]
    );

    return $content;
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    if (!defined($self->{session_token})) {
        $self->authenticate(statefile => $self->{cache});
    }
    
    my $content = $self->{http}->request(
        url_path => $self->{url_path} . $options{endpoint},
        get_param => $options{get_param},
        username => $self->{session_token},
        password => 'session',
        credentials => 1,
        basic => 1,
        warning_status => '',
        unknown_status => '',
        critical_status => ''
    );

    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_session_token(statefile => $self->{cache});
        $self->authenticate(statefile => $self->{cache});
        $content = $self->{http}->request(
            url_path => $self->{url_path} . $options{endpoint},
            get_param => $options{get_param},
            username => $self->{session_token},
            password => 'session',
            credentials => 1,
            basic => 1,
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );
    }

    my $decoded = $self->json_decode(content => $content);
    if (!defined($decoded)) {
        $self->{output}->add_option_msg(short_msg => 'error while retrieving data (add --debug option for detailed message)');
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

Graylog Rest API

=head1 REST API OPTIONS

Graylog Rest API

=over 8

=item B<--hostname>

Graylog hostname.

=item B<--url-path>

API url path (Default: '/api/')

=item B<--port>

API port (Default: 9000)

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--username>

Specify username for authentication (Mandatory if --credentials is specified)

=item B<--password>

Specify password for authentication (Mandatory if --credentials is specified)

=item B<--timeout>

Set HTTP timeout

=item B<--requested-by>

Set request HTTP header (Default: 'cli')

=back

=head1 DESCRIPTION

B<custom>.

=cut
