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

package apps::wazuh::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5;

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
            'token:s'    => { name => 'token' },
            'timeout:s'  => { name => 'timeout' },
            'port:s'    => { name => 'port' },
            'proto:s'    => { name => 'proto' },
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
    $self->{api_username} = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : '';
    $self->{api_password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : '';
    $self->{timeout}  = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{port}     = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 55000;
    $self->{proto}    = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';
    $self->{token} = $self->{option_results}->{token};
 
    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify hostname option.');
        $self->{output}->option_exit();
    }

    if ($self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --username option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --password option.');
        $self->{output}->option_exit();
    }
    if (defined($self->{token})) {
        $self->{cache}->check_options(option_results => $self->{option_results});
    }

    return 0;
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub get_port {
    my ($self, %options) = @_;

    return $self->{port};
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub get_token {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache}->read(statefile => 'wazuh_api_' . Digest::MD5::md5_hex($self->{hostname} . '_' . $self->{api_username}));
    my $token = $self->{cache}->get(name => 'token');
    my $md5_secret_cache = $self->{cache}->get(name => 'md5_secret');
    my $md5_secret = Digest::MD5::md5_hex($self->{api_username} . $self->{api_password});

    if ($has_cache_file == 0 ||
        !defined($token) ||
        (defined($md5_secret_cache) && $md5_secret_cache ne $md5_secret)
        ) {
        $self->settings();
        my $content = $self->{http}->request(
            method => 'GET',
            url_path => '/security/user/authenticate',
            credentials => 1,
            basic => 1,
            username => $self->{api_username},
            password => $self->{api_password}
        );

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
            $self->{output}->option_exit();
        }
        if (!defined($decoded->{data}->{token})) {
            $self->{output}->add_option_msg(short_msg => 'Cannot get token');
            $self->{output}->option_exit();
        }

        $token = $decoded->{data}->{token};
        my $datas = {
            updated => time(),
            token => $token,
            md5_secret => $md5_secret
        };
        $self->{cache}->write(data => $datas);
    }

    return $token;
}

sub clean_token {
    my ($self, %options) = @_;

    my $datas = { updated => time() };
    $self->{cache}->write(data => $datas);
}

sub credentials {
    my ($self, %options) = @_;

    my $token = $self->{token};
    if (defined($self->{token})) {
        $token = $self->get_token();
    }

    my $creds = {};
    if (defined($self->{token})) {
        $creds = {
            header => ['Authorization: Bearer ' . $token],
            unknown_status => '',
            warning_status => '',
            critical_status => ''
        };
    } else {
        $creds = {
            credentials => 1,
            basic => 1,
            username => $self->{api_username},
            password => $self->{api_password},
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        };
    }

    return $creds;
}

sub request {
    my ($self, %options) = @_;

    $self->settings();
    my $creds = $self->credentials();
    my $content = $self->{http}->request(
        url_path => $options{path},
        %$creds
    );

    # Maybe token is invalid. so we retry
    if (defined($self->{token}) && $self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_token();
        $creds = $self->credentials();
        $content = $self->{http}->request(
            url_path => $options{path},
            %$creds,
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );
    }

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'Cannot decode json response');
        $self->{output}->option_exit();
    }
    if ($decoded->{error} != 0) {
        $self->{output}->add_option_msg(short_msg => "api error $decoded->{error}: " . $decoded->{message});
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

Wazuh REST API

=head1 SYNOPSIS

Wazuh Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Wazuh hostname.

=item B<--username>

Wazuh username.

=item B<--password>

Wazuh password.

=item B<--token>

Use token authentication.

=item B<--timeout>

Set HTTP timeout in seconds (default: 30).

=item B<--proto>

Set protocol (default: 'https')

=item B<--port>

Set HTTP port (default: 55000)

=back

=head1 DESCRIPTION

B<custom>.

=cut
