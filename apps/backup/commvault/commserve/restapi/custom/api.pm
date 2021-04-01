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
# Authors : Roman Morandell - ivertix
#

package apps::backup::commvault::commserve::restapi::custom::api;

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
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'hostname:s'     => { name => 'hostname' },
            'port:s'         => { name => 'port' },
            'proto:s'        => { name => 'proto' },
            'url-path:s'     => { name => 'url_path' },
            'api-username:s' => { name => 'api_username' },
            'api-password:s' => { name => 'api_password' },
            'user-domain:s'  => { name => 'user_domain' },
            'timeout:s'      => { name => 'timeout' }
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
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/webconsole/api';
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{user_domain} = (defined($self->{option_results}->{user_domain})) ? $self->{option_results}->{user_domain} : '';

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

    $options{content} =~ s/\r//mg;
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
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub clean_token {
    my ($self, %options) = @_;

    my $datas = {};
    $options{statefile}->write(data => $datas);
    $self->{access_token} = undef;
    $self->{http}->add_header(key => 'Authorization', value => undef);
}

sub get_auth_token {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'commvault_commserve_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{api_username}));
    my $access_token = $options{statefile}->get(name => 'access_token');

    # Token expires every 15 minutes
    if ($has_cache_file == 0 || !defined($access_token)) {
        my $json_request = {
            username => $self->{api_username},
            password => MIME::Base64::encode_base64($self->{api_password}, '')
        };
        $json_request->{domain} = $self->{user_domain} if ($self->{user_domain} ne '');

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
            url_path => $self->{url_path} . '/Login',
            query_form_post => $encoded,
            warning_status => '',
            unknown_status => '',
            critical_status => ''
        );

        if ($self->{http}->get_code() != 200) {
            $self->{output}->add_option_msg(short_msg => "Authentication error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my $decoded = $self->json_decode(content => $content);
        if (!defined($decoded->{token})) {
            $self->{output}->add_option_msg(short_msg => "Cannot get token");
            $self->{output}->option_exit();
        }

        $access_token = $decoded->{token};
        my $datas = {
            access_token => $access_token
        };
        $options{statefile}->write(data => $datas);
    }

    $self->{access_token} = $access_token;
    $self->{http}->add_header(key => 'Authtoken', value => $self->{access_token});
}

sub request_internal {
    my ($self, %options) = @_;

    $self->settings();
    if (!defined($self->{access_token})) {
        $self->get_auth_token(statefile => $self->{cache});
    }

    my $content = $self->{http}->request(
        url_path => $self->{url_path} . $options{endpoint},
        get_param => $options{get_param},
        warning_status => '',
        unknown_status => '',
        critical_status => ''
    );

    # Maybe there is an issue with the token. So we retry.
    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_token(statefile => $self->{cache});
        $self->get_auth_token(statefile => $self->{cache});
        $content = $self->{http}->request(
            url_path => $self->{url_path} . $options{endpoint},
            get_param => $options{get_param},
            warning_status => '',
            unknown_status => '',
            critical_status => ''
        );
    }

    my $decoded = $self->json_decode(content => $content);

    if (!defined($decoded)) {
        $self->{output}->add_option_msg(short_msg => 'Error while retrieving data (add --debug option for detailed message)');
        $self->{output}->option_exit();
    }

    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->{output}->add_option_msg(short_msg => 'api request error');
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub request {
    my ($self, %options) = @_;

    return $self->request_internal(
        endpoint => $options{endpoint}
    );
}

sub request_paging {
    my ($self, %options) = @_;

    my ($page_num, $page_count) = (1, 200);
    my $alerts = [];
    while (1) {
        my $results = $self->request_internal(
            endpoint => $options{endpoint},
            get_param => ['pageNo=' . $page_num, 'pageCount=' . $page_count]
        );

        push @$alerts, @{$results->{feedsList}};
        last if ($results->{totalNoOfAlerts} < ($page_num * $page_count));
        $page_num++;
    }

    return $alerts;
}

1;

__END__

=head1 NAME

Commvault API

=head1 SYNOPSIS

Commvault api

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

API hostname.

=item B<--url-path>

API url path (Default: '/webconsole/api')

=item B<--port>

API port (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--api-username>

Set API username

=item B<--api-password>

Set API password

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
