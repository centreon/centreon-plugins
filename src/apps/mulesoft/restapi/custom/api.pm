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

package apps::mulesoft::restapi::custom::api;

use strict;
use warnings;
use DateTime;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use URI::Encode;
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
        $options{options}->add_options(arguments => {
            'api-username:s'        => { name => 'api_username' },
            'api-password:s'        => { name => 'api_password' },
            'client-id:s'           => { name => 'client_id' },
            'client-secret:s'       => { name => 'client_secret' },
            'environment-id:s'      => { name => 'environment_id' },
            'organization-id:s'     => { name => 'organization_id' },
            'hostname:s'            => { name => 'hostname' },
            'port:s'                => { name => 'port' },
            'proto:s'               => { name => 'proto' },
            'timeout:s'             => { name => 'timeout' },
            'reload-cache-time:s'   => { name => 'reload_cache_time' },
            'authent-endpoint:s'    => { name => 'authent_endpoint' },
            'monitoring-endpoint:s' => { name => 'monitoring_endpoint' }
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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : 'eu1.anypoint.mulesoft.com';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{monitoring_endpoint}->{arm} = (defined($self->{option_results}->{monitoring_endpoint})) ? $self->{option_results}->{monitoring_endpoint} : '/hybrid/api/v1';
    $self->{monitoring_endpoint}->{mq_admin} = (defined($self->{option_results}->{monitoring_endpoint})) ? $self->{option_results}->{monitoring_endpoint} : '/mq/admin/api/v1';
    $self->{monitoring_endpoint}->{mq_stats} = (defined($self->{option_results}->{monitoring_endpoint})) ? $self->{option_results}->{monitoring_endpoint} : '/mq/stats/api/v1';
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{client_id} = (defined($self->{option_results}->{client_id})) ? $self->{option_results}->{client_id} : '';
    $self->{client_secret} = (defined($self->{option_results}->{client_secret})) ? $self->{option_results}->{client_secret} : '';
    $self->{environment_id} = (defined($self->{option_results}->{environment_id})) ? $self->{option_results}->{environment_id} : '';
    $self->{organization_id} = (defined($self->{option_results}->{organization_id})) ? $self->{option_results}->{organization_id} : '';
    $self->{reload_cache_time} = (defined($self->{option_results}->{reload_cache_time})) ? $self->{option_results}->{reload_cache_time} : 180;
    $self->{cache}->check_options(option_results => $self->{option_results});

    if ($self->{environment_id} eq '' || $self->{organization_id} eq '' ) {
        $self->{output}->add_option_msg(short_msg => "--environment-id and --organization-id must be set");
        $self->{output}->option_exit();
    }
    if (! (
        ($self->{api_username} ne '' && $self->{api_password} ne '')
        ||
        ($self->{client_id} ne '' && $self->{client_secret} ne '' )
    ) ) {
        $self->{output}->add_option_msg(short_msg => "At least one of --api-username / --api-password (login) ; or --client-id and --client-secret (OAuth2), must be set");
        $self->{output}->option_exit();
    }
    if (! (
      ($self->{api_username} ne '' && $self->{api_password} ne '' && $self->{client_id} eq '' && $self->{client_secret} eq '' )
      ||
      ($self->{api_username} eq '' && $self->{api_password} eq '' && $self->{client_id} ne '' && $self->{client_secret} ne '' )
    ) ) {
        $self->{output}->add_option_msg(short_msg => "--api-username / --api-password (login), and --client-id / --client-secret (OAuth2), cannot be set both at the same time");
        $self->{output}->option_exit();
    }

    # Different endpoints based on whether we use classic login, or OAuth2
    # Cf https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/access-management-api/minor/1.0/pages/Authentication/
    # (Or: https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/?search=Access%20Management%20API and click on first result)
    if ($self->{api_username} ne '') {
        # Using the Login endpoint
        $self->{cache_key} = md5_hex($self->{api_username});
        $self->{authent_endpoint} = (defined($self->{option_results}->{authent_endpoint})) ? $self->{option_results}->{authent_endpoint} : '/accounts/login';
      } else {
        # Using the OAuth2 endpoint
        $self->{cache_key} = md5_hex($self->{client_id});
        $self->{authent_endpoint} = (defined($self->{option_results}->{authent_endpoint})) ? $self->{option_results}->{authent_endpoint} : '/accounts/api/v2/oauth2/token';
      }
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
    $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{access_token}) if (defined($self->{access_token}));
    $self->{http}->add_header(key => 'X-ANYPNT-ENV-ID', value => $self->{environment_id}) if (defined $options{environment_header});
    $self->{http}->add_header(key => 'X-ANYPNT-ORG-ID', value => $self->{organization_id}) if (defined $options{organization_header});
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_access_token {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'mulesoft_api_' . md5_hex($self->{hostname}) . '_' . $self->{cache_key});
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $access_token = $options{statefile}->get(name => 'access_token');
    if ( $has_cache_file == 0 || !defined($access_token) || (($expires_on - time()) < 10) ) {
        my $login;
        if ($self->{api_username} ne '') {
          $login = { username => $self->{api_username}, password => $self->{api_password} };
        } else {
          $login = { client_id => $self->{client_id}, client_secret => $self->{client_secret}, grant_type => "client_credentials" };
        }
        my $post_json = JSON::XS->new->utf8->encode($login);

        $self->settings();

        my $content = $self->{http}->request(
            method => 'POST',
            header => ['Content-type: application/json'],
            query_form_post => $post_json,
            url_path => $self->{authent_endpoint}
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
            $self->{output}->output_add(long_msg => $content, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
            $self->{output}->option_exit();
        }
        if (defined($decoded->{error_code})) {
            $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error}, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Authentication endpoint returns error code '" . $decoded->{error_code} . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }

        $access_token = $decoded->{access_token};
        my $datas = { last_timestamp => time(), access_token => $decoded->{access_token}, expires_on => time() + 3600 };
        $options{statefile}->write(data => $datas);
    }

    return $access_token;
}

sub request_api {
    my ($self, %options) = @_;

    if (!defined($self->{access_token})) {
        $self->{access_token} = $self->get_access_token(statefile => $self->{cache});
    }

    $self->settings(environment_header => 1, organization_header => 1);

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


sub list_objects {
    my ($self, %options) = @_;

    if ($options{api_type} eq 'arm') {
        my $url_path = $self->{monitoring_endpoint}->{arm} . $options{endpoint};
        my $response = $self->request_api(method => 'GET', url_path => $url_path);
        return $response->{data};
    };

    if ($options{api_type} eq 'mq') {
        my $url_path = $self->{monitoring_endpoint}->{mq_admin} .
            '/organizations/' . $self->{organization_id} .
            '/environments/' . $self->{environment_id} .
            '/regions/' . $options{region_id} .
            $options{endpoint};
        my $response = $self->request_api(method => 'GET', url_path => $url_path);
        return $response;
    };
}

sub get_objects_status {
    my ($self, %options) = @_;

    if ($options{api_type} eq 'arm') {
        my $url_path = $self->{monitoring_endpoint}->{arm} . $options{endpoint} . $options{object_id};
        my $response = $self->request_api(method => 'GET', url_path => $url_path);
        return $response->{data};
    };

    if ($options{api_type} eq 'mq') {
        my $url_path = $self->{monitoring_endpoint}->{mq_stats} .
            '/organizations/' . $self->{organization_id} .
            '/environments/' . $self->{environment_id} .
            '/regions/' . $options{region_id} .
            $options{endpoint} . '/' . $options{object_id};
        my $response = $self->request_api(method => 'GET', url_path => $url_path, get_param => $options{get_param});
        return $response;
    };

}

sub cache_hosts {
    my ($self, %options) = @_;

    $self->{cache_hosts} = centreon::plugins::statefile->new(%options);
    $self->{cache_hosts}->check_options(option_results => $self->{option_results});
    my $has_cache_file = $self->{cache_hosts}->read(statefile => 'cache_ovirt_hosts_' . md5_hex($self->{hostname}) . '_' . $self->{cache_key});
    my $timestamp_cache = $self->{cache_hosts}->get(name => 'last_timestamp');
    my $hosts = $self->{cache_hosts}->get(name => 'hosts');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{reload_cache_time}) * 60))) {
        $hosts = [];
        my $datas = { last_timestamp => time(), hosts => $hosts };
        my $list = $self->list_hosts();
        foreach (@{$list}) {
            push @{$hosts}, { id => $_->{id}, name => $_->{name} };
        }
        $self->{cache_hosts}->write(data => $datas);
    }

    return $hosts;
}

1;

__END__

=head1 NAME

Mulesoft Rest API

=head1 REST API OPTIONS

Mulesoft Rest API

=over 8

=item B<--hostname>

Mulesoft API hostname (default: anypoint.mulesoft.com).

=item B<--port>

Port used (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--api-username>

Mulesoft API username (mandatory).

=item B<--api-password>

Mulesoft API password (mandatory).

=item B<--environment-id>

Mulesoft API Environment ID (mandatory).

=item B<--organization-id>

Mulesoft API Organization ID (mandatory).

=item B<--timeout>

Set timeout in seconds (default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
