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

package storage::dell::me4::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);
use Digest::SHA;

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
            'api-username:s' => { name => 'api_username' },
            'api-password:s' => { name => 'api_password' },
            'hostname:s'     => { name => 'hostname' },
            'port:s'         => { name => 'port' },
            'proto:s'        => { name => 'proto' },
            'timeout:s'      => { name => 'timeout' },
            'digest-sha256'  => { name => 'digest_sha256' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);
    $self->{set_lang} = 0;

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
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';

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

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = '%{http_code} < 200 or %{http_code} > 400';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'datatype', value => 'json');
    if (defined($self->{session_key})) {
        $self->{http}->add_header(key => 'sessionKey', value => $self->{session_key});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub get_session_key {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'dell_me4_api_' . md5_hex($self->{hostname}) . '_' . md5_hex($self->{api_username}));
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $session_key = $options{statefile}->get(name => 'session_key');

    if ($has_cache_file == 0 || !defined($session_key) || (($expires_on - time()) < 10)) {
        my $digest_data = $self->{api_username} . '_' . $self->{api_password};
        my $digest_hash = defined($self->{option_results}->{digest_sha256}) ? Digest::SHA::sha256_hex($digest_data) : md5_hex($digest_data);

        $self->settings();

        my $content = $self->{http}->request(
            method => 'GET',
            url_path => '/api/login/' . $digest_hash
        );

        if (!defined($content) || $content eq '') {
            $self->{output}->add_option_msg(short_msg => "Login endpoint returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $content, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
            $self->{output}->option_exit();
        }
        if ($decoded->{status}[0]->{'response-type'} ne 'Success') {
            $self->{output}->add_option_msg(short_msg => "Login endpoint returns an error: '" . $decoded->{status}[0]->{response} . "'");
            $self->{output}->option_exit();
        }

        $session_key = $decoded->{status}[0]->{response};
        my $datas = { last_timestamp => time(), session_key => $decoded->{status}[0]->{response}, expires_on => 3600 };
        $options{statefile}->write(data => $datas);
    }
    
    return $session_key;
}

sub request_api {
    my ($self, %options) = @_;

    if (!defined($self->{session_key})) {
        $self->{session_key} = $self->get_session_key(statefile => $self->{cache});
    }

    $self->settings();

    if ($self->{set_lang} == 0) {
        $self->{http}->request(method => 'GET', url_path => '/api/set/cli-parameters/locale/English');
        $self->{set_lang} = 1;
    }
    my $content = $self->{http}->request(%options);
    
    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

Dell ME4 Rest API

=head1 REST API OPTIONS

Dell ME4 Rest API

=over 8

=item B<--hostname>

Dell ME4 hostname.

=item B<--port>

Port used (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--api-username>

API username.

=item B<--api-password>

API password.

=item B<--digest-sha256>

New digest to use since firmware GT280R010-01 (md5 deprecated).

=item B<--timeout>

Set timeout in seconds (default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
