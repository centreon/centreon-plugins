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

package apps::sailpoint::identitynow::restapi::custom::api;

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
            'tenant:s'        => { name => 'tenant' },
            'domain:s'        => { name => 'domain' },
            'port:s'          => { name => 'port' },
            'proto:s'         => { name => 'proto' },
            'api-version:s'   => { name => 'api_version' },
            'client-id:s'     => { name => 'client_id' },
            'client-secret:s' => { name => 'client_secret' },
            'timeout:s'       => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'SAILPOINT IDENTITYNOW REST API OPTIONS', once => 1);

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

    $self->{tenant} = (defined($self->{option_results}->{tenant})) ? $self->{option_results}->{tenant} : '';
    $self->{domain} = (defined($self->{option_results}->{domain})) ? $self->{option_results}->{domain} : 'identitynow';
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{api_version} = (defined($self->{option_results}->{api_version})) ? $self->{option_results}->{api_version} : 'v3';
    $self->{client_id} = (defined($self->{option_results}->{client_id})) ? $self->{option_results}->{client_id} : '';
    $self->{client_secret} = (defined($self->{option_results}->{client_secret})) ? $self->{option_results}->{client_secret} : '';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;

    if ($self->{tenant} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --tenant option.');
        $self->{output}->option_exit();
    }
    if ($self->{client_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --client-id option.");
        $self->{output}->option_exit();
    }
    if ($self->{client_secret} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --client-secret option.");
        $self->{output}->option_exit();
    }

    $self->{hostname} = $self->{tenant} . '.api.' . $self->{domain} . '.com';

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

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
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
        statefile => 'sailpoint_identitynow_api_' . md5_hex($self->{option_results}->{tenant}) . '_' . md5_hex($self->{option_results}->{client_id})
    );
    my $access_token = $options{statefile}->get(name => 'access_token');
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $md5_secret_cache = $self->{cache}->get(name => 'md5_secret');
    my $md5_secret = md5_hex($self->{client_id} . $self->{client_secret});

    if ($has_cache_file == 0 || !defined($access_token) || (time() > $expires_on) ||
        (defined($md5_secret_cache) && $md5_secret_cache ne $md5_secret)) {
        my ($content) = $self->{http}->request(
            method => 'POST',
            hostname => $self->{hostname},
            url_path => '/oauth/token',
            post_param => [
                'grant_type=client_credentials',
                'client_id=' . $self->{client_id},
                'client_secret=' . $self->{client_secret}
            ],
            unknown_status => '',
            warning_status => '',
            critical_status => ''
        );

        if (!defined($content) || $content eq '') {
            $self->{output}->add_option_msg(short_msg => "Authentication endpoint returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $@, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
            $self->{output}->option_exit();
        }
        if (ref($decoded) eq 'HASH' && defined($decoded->{error})) {
            $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error_description}, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Authentication endpoint returns error code '" . $decoded->{error} . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }
        if (ref($decoded) eq 'HASH' && defined($decoded->{detailCode})) {
            $self->{output}->add_option_msg(short_msg => "Authentication endpoint returns error code '" . $decoded->{detailCode} . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }

        if (!defined($decoded->{access_token})) {
            $self->{output}->add_option_msg(short_msg => "Cannot get token");
            $self->{output}->option_exit();
        }

        $access_token = $decoded->{access_token};
        my $datas = {
            access_token => $access_token,
            expires_on => time() + $decoded->{expires_in},
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

    my @results;
    my $decoded;

    my @get_param;
    @get_param = (@get_param, @{$options{get_param}}) if (defined($options{get_param}) && scalar(@{$options{get_param}}));
    # Dealing with pagination without using count parameter as recommended
    # here https://developer.sailpoint.com/idn/api/standard-collection-parameters#paginating-results
    my $limit = 250;
    push @get_param, 'limit=' . $limit;
    my $offset = 0;
    push @get_param, 'offset=' . $offset;

    do {
        my $content = $self->{http}->request(
            method => 'GET',
            hostname => $self->{hostname},
            url_path => $options{endpoint},
            get_param => \@get_param,
            unknown_status => '',
            warning_status => '',
            critical_status => ''
        );

        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $@, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
            $self->{output}->option_exit();
        }
        if (ref($decoded) eq 'HASH' && defined($decoded->{error})) {
            $self->{output}->add_option_msg(short_msg => "Endpoint returns error code '" . $decoded->{error} . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }
        if (ref($decoded) eq 'HASH' && defined($decoded->{detailCode})) {
            $self->{output}->add_option_msg(short_msg => "Endpoint returns error code '" . $decoded->{detailCode} . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }
        if ($self->{http}->get_code() != 200) {
            $self->{output}->add_option_msg(short_msg => "Endpoint error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "'] (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }

        push @results, @$decoded if (ref($decoded) eq 'ARRAY');
        push @results, $decoded if (ref($decoded) ne 'ARRAY');
        pop @get_param;
        $offset += $limit;
        push @get_param, 'offset=' . $offset;
    } while (ref($decoded) eq 'ARRAY' && scalar(@$decoded) eq $limit);

    return \@results;
}

sub get_sources {
    my ($self, %options) = @_;

    my $result;

    if (defined($options{id}) && $options{id} ne '') {
        $result = $self->request_api(
            endpoint => '/' . $self->{api_version} . '/sources/' . $options{id}
        );
    } else {
        $result = $self->request_api(
            endpoint => '/' . $self->{api_version} . '/sources'
        );
    }

    return $result;
}

sub search_count {
    my ($self, %options) = @_;

    $self->settings();
    if (!defined($self->{access_token})) {
        $self->get_auth_token(statefile => $self->{cache});
    }
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');

    my ($content) = $self->{http}->request(
        method => 'POST',
        hostname => $self->{hostname},
        url_path => '/' . $self->{api_version} . '/search/count',
        query_form_post => $options{query},
        unknown_status => '%{http_code} < 200 or %{http_code} >= 300',
        warning_status => '',
        critical_status => ''
    );
    
    if ($self->{http}->get_code() != 204) {
        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $@, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
            $self->{output}->option_exit();
        }
        if (ref($decoded) eq 'HASH' && defined($decoded->{detailCode})) {
            $self->{output}->add_option_msg(short_msg => "Endpoint returns error code '" . $decoded->{detailCode} . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        } else {
            $self->{output}->add_option_msg(short_msg => "Endpoint error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "'] (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }
    }
    
    return $self->{http}->get_header(name => 'X-Total-Count');
}

1;

__END__

=head1 NAME

SailPoint IdentityNow API

=head1 SYNOPSIS

SailPoint IdentityNow API

=head1 SAILPOINT IDENTITYNOW REST API OPTIONS

=over 8

=item B<--tenant>

SailPoint IdentityNow API tenant.

=item B<--domain>

SailPoint IdentityNow API domain  (default: identitynow)

=item B<--port>

SailPoint IdentityNow API port (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--client-id>

SailPoint IdentityNow Client ID

=item B<--client-secret>

SailPoint IdentityNow Client Secret

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
