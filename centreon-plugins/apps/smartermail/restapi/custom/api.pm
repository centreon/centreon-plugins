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
# Authors : Roman Morandell - ivertix
#

package apps::smartermail::restapi::custom::api;

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
    # $options{options} = options object
    # $options{output} = output object
    # $options{exit_value} = integer
    # $options{noptions} = integer

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
            "hostname:s" => { name => 'hostname' },
            "port:s"     => { name => 'port' },
            "proto:s"    => { name => 'proto' },
            "url_path:s" => { name => 'url_path' },
            "username:s" => { name => 'username' },
            "password:s" => { name => 'password' },
            "timeout:s"  => { name => 'timeout' },
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode} = $options{mode};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

# Method to manage multiples
sub set_options {
    my ($self, %options) = @_;
    # options{options_result}

    $self->{option_results} = $options{option_results};
}

# Method to manage multiples
sub set_defaults {
    my ($self, %options) = @_;
    # options{default}

    # Manage default value
    foreach (keys %{$options{default}}) {
        if ($_ eq $self->{mode}) {
            for (my $i = 0; $i < scalar(@{$options{default}->{$_}}); $i++) {
                foreach my $opt (keys %{$options{default}->{$_}[$i]}) {
                    if (!defined($self->{option_results}->{$opt}[$i])) {
                        $self->{option_results}->{$opt}[$i] = $options{default}->{$_}[$i]->{$opt};
                    }
                }
            }
        }
    }
}

sub check_options {
    my ($self, %options) = @_;
    # return 1 = ok still customarg
    # return 0 = no customarg left

    $self->{hostname} = $self->{option_results}->{hostname};
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/api/v1';
    $self->{username} = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : undef;
    $self->{password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : undef;
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;

    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
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

sub get_endpoint {
    my ($self, %options) = @_;

    my $result = $self->request_api(%options);

    return $result;
}

sub json_decode {
    my ($self, $content) = @_;

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $content, debug => 1);
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
    $self->{option_results}->{url_path} = $self->{url_path};
    $self->{option_results}->{username} = $self->{username};
    $self->{option_results}->{password} = $self->{password};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();

    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    if (defined($self->{api_token})) {
        $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{api_token});
        $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_auth_token {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'smatermail_api_' . md5_hex($self->{option_results}->{hostname}) .
        '_' . md5_hex($self->{option_results}->{username}));
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $accessToken = $options{statefile}->get(name => 'accessToken');

    if ($has_cache_file == 0 || !defined($accessToken) || (($expires_on - time()) < 60)) {
        my $post_param = [ 'username=' . $self->{username}, 'password=' . $self->{password} ];

        $self->settings();
        my $url = $self->{url_path} . '/auth/authenticate-user';

        my $content = $self->{http}->request(method => 'POST', url_path => $url, post_param => $post_param);

        if ($self->{http}->get_code() != 200) {
            $self->{output}->add_option_msg(short_msg => "Authentication error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my $jsonResponse = $self->json_decode($content);

        if (!defined($jsonResponse->{"resultCode"}) || $jsonResponse->{"resultCode"} ne "200" || !defined($jsonResponse->{accessToken})) {
            $self->{output}->output_add(long_msg => $content, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Cannot get token");
            $self->{output}->option_exit();
        }

        $accessToken = $jsonResponse->{accessToken};
        my $datas = { last_timestamp => time(), accessToken => $jsonResponse->{accessToken}, expires_on => time() + 900 };
        $options{statefile}->write(data => $datas);
    }

    return $accessToken;
}

sub request_api {
    my ($self, %options) = @_;

    if (!defined($self->{api_token})) {
        $self->{api_token} = $self->get_auth_token(statefile => $self->{cache});
    }

    $self->settings();

    my $content = $self->{http}->request(
        method          => $options{method},
        url_path        => $self->{url_path} . $options{api_path},
        query_form_post => $options{query_form_post},
        critical_status => '', warning_status => '', unknown_status => '');


    my $jsonResponse = $self->json_decode($content);

    if (!$jsonResponse->{success}) {
        $self->{output}->output_add(long_msg => $content, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Request could not be processed: $jsonResponse->{message}");
        $self->{output}->option_exit();
    }

    return ($jsonResponse, JSON::XS->new->utf8->pretty->encode($jsonResponse));
}

1;

__END__

=head1 NAME

SmarterMail API

=head1 SYNOPSIS

smartermail api

=head1 API OPTIONS

=over 8

=item B<--hostname>

API hostname.

=item B<--url-path>

API url path (Default: '/api/v1')

=item B<--port>

API port (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--username>

Set API username

=item B<--password>

Set API password

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
