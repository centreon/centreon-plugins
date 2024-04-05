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

package apps::vmware::horizon::api::custom::restapi;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use JSON::WebToken;
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
            'hostname:s'      => { name => 'hostname' },
            'port:s'          => { name => 'port' },
            'proto:s'         => { name => 'proto' },
            'api-version:s'   => { name => 'api_version' },
            'api-domain:s'    => { name => 'api_domain' },
            'api-username:s'  => { name => 'api_username' },
            'api-password:s'  => { name => 'api_password' },
            'api-page-size:s' => { name => 'api_page_size' },
            'timeout:s'       => { name => 'timeout' }
        });
    }

    $options{options}->add_help(package => __PACKAGE__, sections => 'VMWARE HORIZON REST API OPTIONS', once => 1);

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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{api_version} = (defined($self->{option_results}->{api_version})) ?
        $self->{option_results}->{api_version} : '';
    $self->{api_domain} = (defined($self->{option_results}->{api_domain})) ?
        $self->{option_results}->{api_domain} : '';
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ?
        $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ?
        $self->{option_results}->{api_password} : '';
    $self->{api_page_size} = (defined($self->{option_results}->{api_page_size})) && 
        $self->{option_results}->{api_page_size} =~ /(\d+)/ ? $1 : 1000;
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_domain} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-domain option.");
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

    my $has_cache_file = $options{statefile}->read(
        statefile => 'vmware_horizon_api_' . md5_hex($self->{option_results}->{hostname}) .
            '_' . md5_hex($self->{option_results}->{api_username})
    );
    my $access_token = $options{statefile}->get(name => 'access_token');
    my $refresh_token = $options{statefile}->get(name => 'refresh_token');
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $md5_secret_cache = $self->{cache}->get(name => 'md5_secret');
    my $md5_secret = md5_hex($self->{api_username} . $self->{api_password});

    if ($has_cache_file == 0 || !defined($access_token)|| (($expires_on - time()) < 10) ||
        (defined($md5_secret_cache) && $md5_secret_cache ne $md5_secret)) {
        my $content = '';
        if (defined($refresh_token)) {
            $content = $self->{http}->request(
                method => 'POST',
                hostname => $self->{hostname},
                url_path => '/rest/refresh',
                query_form_post => encode_json(
                    {
                        refresh_token => $refresh_token
                    }
                ),
                warning_status => '',
                unknown_status => '',
                critical_status => ''
            );
        } else {
            $content = $self->{http}->request(
                method => 'POST',
                hostname => $self->{hostname},
                url_path => '/rest/login',
                query_form_post => encode_json(
                    {
                        domain => $self->{api_domain},
                        username => $self->{api_username},
                        password => $self->{api_password}
                    }
                ),
                warning_status => '',
                unknown_status => '',
                critical_status => ''
            );
        }

        if ($self->{http}->get_code() != 200) {
            $self->{output}->add_option_msg(
                short_msg => sprintf("Authentication error [code: '%s'] [message: '%s']",
                    $self->{http}->get_code(),
                    $self->{http}->get_message()
                )
            );
        }

        my $decoded = $self->json_decode(content => $content);
        if (!defined($decoded->{access_token})) {
            $self->{output}->add_option_msg(
                short_msg => sprintf("Cannot get token [status: '%s']",
                    $decoded->{status}
                )
            );
            $self->{output}->option_exit();
        }

        $access_token = $decoded->{access_token};
        
        # Decode the token to get its expiration date
        my $decoded_access_token = JSON::WebToken->decode($access_token, '', 0);

        my $datas = {
            access_token => $access_token,
            expires_on => $decoded_access_token->{exp},
            refresh_token => $decoded->{refresh_token},
            md5_secret => $md5_secret
        };
        $options{statefile}->write(data => $datas);
    }

    $self->{access_token} = $access_token;
    $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{access_token});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    if (!defined($self->{access_token})) {
        $self->get_auth_token(statefile => $self->{cache});
    }

    my $content = $self->{http}->request(
        method => 'GET',
        hostname => $self->{hostname},
        url_path => $options{endpoint},
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
            method => 'GET',
            hostname => $self->{hostname},
            url_path => $options{endpoint},
            get_param => $options{get_param},
            warning_status => '',
            unknown_status => '',
            critical_status => ''
        );
    }

    my $decoded = $self->json_decode(content => $content);
    if (!defined($decoded)) {
        $self->{output}->add_option_msg(
            short_msg => 'Error while retrieving data (add --debug option for detailed message)'
        );
        $self->{output}->option_exit();
    }

    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        my $message = 'API request error';
        if (defined($decoded->{message})) {
            $message .= ': ' . $decoded->{status};
        }
        $self->{output}->add_option_msg(short_msg => $message);
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub request_api_paginate {
    my ($self, %options) = @_;

    my @items;

    my $page = 1;
    my @get_param = (
        'size=' . $self->{api_page_size},
        'page=' . $page
    );
    push @get_param, @{$options{get_param}} if (defined($options{get_param}) && scalar(@{$options{get_param}}) > 0);

    while (1) {
        my $response = $self->request_api(
            endpoint => $options{endpoint},
            get_param => \@get_param
        );
        
        push @items, @{$response};

        last if (!defined($self->{http}->get_header(name => 'X-TOTAL-COUNT')) ||
            scalar(@items) >= $self->{http}->get_header(name => 'X-TOTAL-COUNT'));

        $page++;
        @get_param = (
            'size=' . $self->{api_page_size},
            'page=' . $page
        );
        push @get_param, @{$options{get_param}} if (defined($options{get_param}) && scalar(@{$options{get_param}}) > 0);        
    }

    return \@items;
}

sub get_inventory_machines {
    my ($self, %options) = @_;

    my $version = 'v5';
    $version = $self->{api_version} if (defined($self->{api_version}) && $self->{api_version} ne '');

    return $self->request_api_paginate(
        endpoint => '/rest/inventory/' . $version . '/machines',
        get_param => []
    );
}

1;

__END__

=head1 NAME

VMWARE HORIZON REST API

=head1 SYNOPSIS

VMware Horizon Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

VMware Horizon API hostname.

=item B<--port>

VMware Horizon API port (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--api-domain>

VMware Horizon API username's domain.

=item B<--api-username>

VMware Horizon API username.

=item B<--api-password>

VMware Horizon API password.

=item B<--api-version>

VMware Horizon API version (Example: v5).

=item B<--api-page-size>

VMware Horizon API page size (Default: '1000').

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut