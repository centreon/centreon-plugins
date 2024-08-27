#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package centreon::common::protocols::actuator::custom::centreonmap;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self = {};
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
            'hostname:s'       => { name => 'hostname' },
            'port:s'           => { name => 'port' },
            'proto:s'          => { name => 'proto' },
            'url-path:s'       => { name => 'url_path' },
            'api-username:s'   => { name => 'api_username' },
            'api-password:s'   => { name => 'api_password' },
            'client-version:s' => { name => 'client_version' },
            'timeout:s'        => { name => 'timeout' }
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
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'http';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 8080;
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/centreon-studio/api/beta';
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300' ;
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';
    $self->{client_version} = (defined($self->{option_results}->{client_version})) ? $self->{option_results}->{client_version} : '21.04.0';

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-username option.");
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-password option.");
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});
    return 0;
}

sub get_connection_infos {
    my ($self, %options) = @_;

    return $self->{hostname} . '_' . $self->{http}->get_port();
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

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'X-Client-Version', value => $self->{client_version});
    $self->{http}->set_options(%{$self->{option_results}});
}

sub clean_session {
    my ($self, %options) = @_;

    my $datas = {};
    $options{statefile}->write(data => $datas);
}

sub get_session {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'centreonmap_session_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{api_username}));
    my $studio_session = $options{statefile}->get(name => 'studioSession');
    my $jwt_token = $options{statefile}->get(name => 'jwtToken');
    my $md5_secret_cache = $self->{cache}->get(name => 'md5_secret');
    my $md5_secret = md5_hex($self->{api_username} . $self->{api_password});

    if ($has_cache_file == 0 ||
        (!defined($studio_session) && !defined($jwt_token)) || 
        (defined($md5_secret_cache) && $md5_secret_cache ne $md5_secret)
        ) {
        my $login = { login => $self->{api_username}, password => $self->{api_password} };
        my $post_json = JSON::XS->new->utf8->encode($login);

        my @urls = ('/auth/sign-in', '/authentication');
        my $content;
        for my $endpoint (@urls) {
            ($content) = $self->{http}->request(
                method => 'POST',
                url_path => $self->{url_path} . $endpoint,
                header => ['Content-type: application/json'],
                query_form_post => $post_json,
                warning_status => '', unknown_status => '', critical_status => ''
            );
            last if ($self->{http}->get_code() == 200);
        }

        if ($self->{http}->get_code() != 200) {
            $self->{output}->add_option_msg(short_msg => "All authentication URLs failed");
            $self->{output}->option_exit();
        }

        my $decoded = $self->json_decode(content => $content);
        if (!defined($decoded->{studioSession}) && !defined($decoded->{jwtToken})) {
            $self->{output}->add_option_msg(short_msg => 'Cannot get session token');
            $self->{output}->option_exit();
        }

        if (defined($decoded->{studioSession})) {
            $studio_session = $decoded->{studioSession};
            $options{statefile}->write(data => { studio_session => $studio_session, md5_secret => $md5_secret });
        } else {
            $jwt_token = $decoded->{jwtToken};
            $options{statefile}->write(data => { jwtToken => $jwt_token, md5_secret => $md5_secret });
        }
    }

    return defined($studio_session) ? 'studio-session: ' . $studio_session : 'Authorization: Bearer ' . $jwt_token;
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my $header = $self->get_session(statefile => $self->{cache});

    my $content = $self->{http}->request(
        url_path => $self->{url_path} . '/actuator' . $options{endpoint},
        get_param => $options{get_param},
        header => [ $header ],
        warning_status => '',
        unknown_status => '',
        critical_status => ''
    );

    # Maybe there is an issue with the token. So we retry.
    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_session(statefile => $self->{cache});
        $header = $self->get_session(statefile => $self->{cache});

        $content = $self->{http}->request(
            url_path => $self->{url_path} . '/actuator' . $options{endpoint},
            get_param => $options{get_param},
            header => [ $header ],
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );
    }

    my $decoded = $self->json_decode(content => $content);
    if (!defined($decoded)) {
        $self->{output}->add_option_msg(short_msg => 'Error while retrieving data (add --debug option for detailed message)');
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

Centreon Map API

=head1 SYNOPSIS

Centreon Map API

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

API hostname.

=item B<--url-path>

API url path (default: '/centreon-studio/api/beta')

=item B<--port>

API port (default: 8080)

=item B<--proto>

Specify https if needed (default: 'http')

=item B<--api-username>

Set API username

=item B<--api-password>

Set API password

=item B<--timeout>

Set HTTP timeout

=item B<--client-version>

Set the client version (default: '21.04.0')

=back

=head1 DESCRIPTION

B<custom>.

=cut
