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

package hardware::devices::cisco::ces::restapi::custom::api;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use XML::LibXML::Simple;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
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
            'hostname:s'     => { name => 'hostname' },
            'port:s'         => { name => 'port'},
            'proto:s'        => { name => 'proto' },
            'api-username:s' => { name => 'api_username' },
            'api-password:s' => { name => 'api_password' },
            'timeout:s'      => { name => 'timeout', default => 30 },
            'no-session'     => { name => 'no_session' }
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
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{no_session} = (defined($self->{option_results}->{no_session})) ? 1 : 0;

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
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

    $self->{cache}->check_options(option_results => $self->{option_results}) if ($self->{no_session} == 0);
    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};
    if ($self->{no_session} == 1) {
        $self->{option_results}->{credentials} = 1;
        $self->{option_results}->{basic} = 1;
        $self->{option_results}->{username} = $self->{api_username};
        $self->{option_results}->{password} = $self->{api_password};
    }
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Content-Type', value => 'text/xml');
    $self->{http}->add_header(key => 'Accept', value => 'text/xml');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub clean_session_cookie {
    my ($self, %options) = @_;

    my $datas = { last_timestamp => time() };
    $options{statefile}->write(data => $datas);
    $self->{session_cookie} = undef;
    $self->{http}->add_header(key => 'Cookie', value => undef);
}

sub authenticate {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'cces_api_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{api_username}));
    my $session_cookie = $options{statefile}->get(name => 'session_cookie');

    if ($has_cache_file == 0 || !defined($session_cookie)) {
        my $content = $self->{http}->request(
            method => 'POST',
            url_path => '/xmlapi/session/begin',
            credentials => 1, basic => 1,
            username => $self->{api_username},
            password => $self->{api_password},
            warning_status => '', unknown_status => '', critical_status => '',
            curl_backend_options => { header => ['Content-Length: 0'] },
        );
        if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
            $self->{output}->add_option_msg(short_msg => "Login error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        ($session_cookie) = $self->{http}->get_header(name => 'Set-Cookie');
        if (!defined($session_cookie)) {
            $self->{output}->add_option_msg(short_msg => "Error retrieving cookie");
            $self->{output}->option_exit();
        }

        my $datas = { last_timestamp => time(), session_cookie => $session_cookie };
        $options{statefile}->write(data => $datas);
    }

    $self->{session_cookie} = $session_cookie;
    $self->{http}->add_header(key => 'Cookie', value => $self->{session_cookie});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    if ($self->{no_session} == 0 && !defined($self->{session_cookie})) {
        $self->authenticate(statefile => $self->{cache});
    }

    my $content = $self->{http}->request(
        %options, 
        warning_status => '', unknown_status => '', critical_status => ''
    );

    # Maybe there is an issue with the session_cookie. So we retry.
    if ($self->{no_session} == 0 && ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300)) {
        $self->clean_session_cookie(statefile => $self->{cache});
        $self->authenticate(statefile => $self->{cache});
        $content = $self->{http}->request(
            %options,
            warning_status => '', unknown_status => '', critical_status => ''
        );
    }

    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->{output}->add_option_msg(short_msg => 'api request error. use --debug.');
        $self->{output}->option_exit();
    }

    my $result;
    eval {
        $SIG{__WARN__} = sub {};
        $result = XMLin($content, ForceArray => $options{ForceArray}, KeyAttr => []);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode xml response: $@");
        $self->{output}->option_exit();
    }

    return $result;
}

1;

__END__

=head1 NAME

CCES Rest API

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Set hostname.

=item B<--port>

Set port (Default: '443').

=item B<--proto>

Specify https if needed (Default: 'https').

=item B<--api-username>

Set username.

=item B<--api-password>

Set password.

=item B<--timeout>

Threshold for HTTP timeout (Default: '30').

=item B<--no-session>

To be used for legacy version (before CE 8.0).

=back

=cut
