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

package storage::purestorage::flashblade::v2::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use JSON::XS;

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
            'api-token:s'       => { name => 'api_token' },
            'hostname:s'        => { name => 'hostname' },
            'port:s'            => { name => 'port' },
            'proto:s'           => { name => 'proto' },
            'timeout:s'         => { name => 'timeout' },
            'api-version:s'     => { name => 'api_version' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
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

    $self->{option_results}->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{option_results}->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{option_results}->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{option_results}->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{api_token} = (defined($self->{option_results}->{api_token})) ? $self->{option_results}->{api_token} : '';
    $self->{api_version} = (defined($self->{option_results}->{api_version})) ? $self->{option_results}->{api_version} : '2.4';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if ($self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_token} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-token option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_version} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-version option.');
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{settings_done} = 1;
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{option_results}->{hostname} . ':' . $self->{option_results}->{port};
}

sub get_token {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache}->read(statefile => 'purestorage_' . md5_hex($self->get_connection_info() . '_' . $self->{api_token}));
    my $token = $self->{cache}->get(name => 'token');
    my $md5_secret_cache = $self->{cache}->get(name => 'md5_secret');
    my $md5_secret = md5_hex($self->{api_token});

    if ($has_cache_file == 0 ||
        !defined($token) ||
        (defined($md5_secret_cache) && $md5_secret_cache ne $md5_secret)
        ) {
        my ($content) = $self->{http}->request(
            method => 'POST',
            url_path => '/api/login',
            query_form_post => '',
            header => [
                'api-token: ' . $self->{api_token}
            ],
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );

        $token = $self->{http}->get_header(name => 'x-auth-token');

        if (!defined($token) || $token eq '') {
            $self->{output}->add_option_msg(short_msg => 'Cannot get token');
            $self->{output}->option_exit();
        }

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

sub request {
    my ($self, %options) = @_;

    $self->settings();
    my $token = $self->get_token();

    my $decoded;
    my $items = [];
    my $num_items = 0;
    while (1) {
        my $get_param = ['limit=1000'];
        push @$get_param, @{$options{get_param}} if (defined($options{get_param}));
        push @$get_param, 'continuation_token=' . $decoded->{continuation_token} if (defined($decoded) && defined($decoded->{continuation_token}));

        my ($content) = $self->{http}->request(
            url_path => '/api/' . $self->{api_version} . $options{endpoint},
            get_param => $options{get_param},
            header => ['X-Auth-Token: ' . $token],
            unknown_status => '',
            warning_status => '',
            critical_status => ''
        );

        # Maybe token is invalid. so we retry
        if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
            $self->clean_token();
            $token = $self->get_token();
            ($content) = $self->{http}->request(
                url_path => '/api/' . $self->{api_version} . $options{endpoint},
                get_param => $options{get_param},
                header => ['X-Auth-Token: ' . $token],
                unknown_status => $self->{unknown_http_status},
                warning_status => $self->{warning_http_status},
                critical_status => $self->{critical_http_status}
            );
        }

        eval {
            $decoded = decode_json($content);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
            $self->{output}->option_exit();
        }

        $num_items += scalar(@{$decoded->{items}});
        push @$items, @{$decoded->{items}};

        last if (
            !defined($decoded->{total_item_count}) ||
            $num_items >= $decoded->{total_item_count} ||
            !defined($decoded->{continuation_token})
        );
    }

    return $items;
}

1;

__END__

=head1 NAME

Pure Storage API

=head1 API OPTIONS

Pure Storage API

=over 8

=item B<--hostname>

Set hostname.

=item B<--port>

Port used (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--api-token>

API token.

=item B<--api-version>

API version (default: 2.4).

=item B<--timeout>

Set timeout in seconds (default: 30).

=back

=head1 DESCRIPTION

B<custom>.

=cut
