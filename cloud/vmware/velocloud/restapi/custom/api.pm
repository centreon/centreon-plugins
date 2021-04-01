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

package cloud::vmware::velocloud::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::statefile;
use DateTime;

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
            'hostname:s'             => { name => 'hostname' },
            'port:s'                 => { name => 'port' },
            'proto:s'                => { name => 'proto' },
            'username:s'             => { name => 'username' },
            'password:s'             => { name => 'password' },
            'operator-user'          => { name => 'operator_user' },
            'api-path:s'             => { name => 'api_path' },
            'timeframe:s'            => { name => 'timeframe' },
            'timeout:s'              => { name => 'timeout' },
            'cache-expires-in:s'     => { name => 'cache_expires_in' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache_cookie} = centreon::plugins::statefile->new(%options);
    $self->{cache_app} = centreon::plugins::statefile->new(%options);

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
    $self->{username} = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : '';
    $self->{password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : '';
    $self->{api_path} = (defined($self->{option_results}->{api_path})) ? $self->{option_results}->{api_path} : '/portal/rest';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{cache_expires_in} = (defined($self->{option_results}->{cache_expires_in})) && $self->{option_results}->{cache_expires_in} =~ /(\d+)/ ?
        $1 : 7200;
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if ($self->{username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --username option.");
        $self->{output}->option_exit();
    }
    if ($self->{password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --password option.");
        $self->{output}->option_exit();
    }

    $self->{cache_cookie}->check_options(option_results => $self->{option_results});
    $self->{cache_app}->check_options(option_results => $self->{option_results});

    return 0;
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

sub get_connection_infos {
    my ($self, %options) = @_;
    
    return $self->{hostname}  . '_' . $self->{http}->get_port();
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
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

sub clean_session {
    my ($self, %options) = @_;

    my $datas = {};
    $options{statefile}->write(data => $datas);
    $self->{session_cookie} = undef;
    $self->{http}->add_header(key => 'Cookie', value => undef);
}

sub get_session_cookie {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'vmware_velocloud_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{username}));
    my $session_cookie = $options{statefile}->get(name => 'session_cookie');

    if ($has_cache_file == 0 || !defined($session_cookie)) {
        my $form_post = { username => $self->{username}, password => $self->{password} };
        my $encoded;
        eval {
            $encoded = JSON::XS->new->utf8->encode($form_post);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => 'Cannot encode json request');
            $self->{output}->option_exit();
        }

        my $login_url = (defined($self->{option_results}->{operator_user})) ? '/login/operatorLogin' : '/login/enterpriseLogin';
        $self->{http}->request(
            method => 'POST',
            url_path => $self->{api_path} . $login_url,
            query_form_post => $encoded,
            warning_status => '',
            unknown_status => '',
            critical_status => ''
        );

        if ($self->{http}->get_code() != 200) {
            $self->{output}->add_option_msg(short_msg => "Authentication error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my (@cookies) = $self->{http}->get_header(name => 'Set-Cookie');
        my $message = '';
        foreach my $cookie (@cookies) {
            $message = $1 if ($cookie =~ /^velocloud\.message=(.+?);/);
            $session_cookie = $1 if ($cookie =~ /^velocloud\.session=(.+?);/);
        }

        if (!defined($session_cookie) || $session_cookie eq '') {
            $self->{output}->add_option_msg(short_msg => "Cannot get session cookie: " . $message);
            $self->{output}->option_exit();
        }

        $options{statefile}->write(data => { session_cookie => $session_cookie });
    }

    $self->{session_cookie} = $session_cookie;
    $self->{http}->add_header(key => 'Cookie', value => 'velocloud.session=' . $self->{session_cookie});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    if (!defined($self->{session_cookie})) {
        $self->get_session_cookie(statefile => $self->{cache_cookie});
    }

    my $encoded_form_post;
    if (defined($options{query_form_post})) {
        eval {
            $encoded_form_post = JSON::XS->new->utf8->encode($options{query_form_post});
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot encode json request");
            $self->{output}->option_exit();
        }
    }

    my ($content) = $self->{http}->request(
        method => $options{method},
        url_path => $self->{api_path} . $options{endpoint},
        query_form_post => $encoded_form_post,
        unknown_status => '',
        warning_status => '',
        critical_status => ''
    );

    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_session(statefile => $self->{cache_cookie});
        $self->get_session_cookie(statefile => $self->{cache_cookie});
        ($content) = $self->{http}->request(
            method => $options{method},
            url_path => $self->{api_path} . $options{endpoint},
            query_form_post => $encoded_form_post,
            unknown_status => '',
            warning_status => '',
            critical_status => ''
        );
    }

    my $decoded = $self->json_decode(content => $content);
    if (!defined($decoded)) {
        $self->{output}->add_option_msg(short_msg => 'error while retrieving data (add --debug option for detailed message)');
        $self->{output}->option_exit();
    }
    if (ref($decoded) ne 'ARRAY' && defined($decoded->{error})) {
        $self->{output}->add_option_msg(
            short_msg => sprintf(
                "API returned error code '%s', message '%s'",
                $decoded->{error}->{code},
                $decoded->{error}->{message}
            )
        );
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub get_entreprise_id {
    my ($self, %options) = @_;

    return if (defined($self->{entreprise_id}));

    my $response = $self->request_api(
        method => 'POST',
        endpoint => '/enterprise/getEnterprise'
    );

    $self->{entreprise_id} = $response->{id};
}

sub list_edges {
    my ($self, %options) = @_;

    $self->get_entreprise_id();

    my $response = $self->request_api(
        method => 'POST',
        endpoint => '/enterprise/getEnterpriseEdges',
        query_form_post => { enterpriseId => int($self->{entreprise_id}) }
    );

    return $response;
}

sub list_links {
    my ($self, %options) = @_;

    $self->get_entreprise_id();

    my $start_time = DateTime->now->subtract(seconds => $options{timeframe})->iso8601.'Z';

    my $response = $self->request_api(
        method => 'POST',
        endpoint => '/metrics/getEdgeLinkMetrics',
        query_form_post => {
            enterpriseId => int($self->{entreprise_id}),
            edgeId => $options{edge_id},
            metrics => [ 'bytesRx' ],
            interval => {
                start => $start_time
            }
        }
    );

    return $response;
}

sub get_links_metrics {
    my ($self, %options) = @_;

    $self->get_entreprise_id();

    my $start_time = DateTime->now->subtract(seconds => $options{timeframe})->iso8601.'Z';

    my $response = $self->request_api(
        method => 'POST',
        endpoint => '/metrics/getEdgeLinkMetrics',
        query_form_post => {
            enterpriseId => int($self->{entreprise_id}),
            edgeId => $options{edge_id},
            metrics => [
                'bytesRx', 'bytesTx', 'bestJitterMsRx', 'bestJitterMsTx',
                'bestLatencyMsRx', 'bestLatencyMsTx', 'bestLossPctRx', 'bestLossPctTx'
            ],
            interval => {
                start => $start_time
            }
        }
    );

    return $response;
}

sub get_application_name {
    my ($self, %options) = @_;

    $self->get_entreprise_id();

    my $has_cache_file = $self->{cache_app}->read(statefile => 'vmware_velocloud_app_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{entreprise_id}));
    my $updated = $self->{cache_app}->get(name => 'updated');
    my $applications = $self->{cache_app}->get(name => 'applications');

    if ($has_cache_file == 0 || !defined($updated) || (time() > ($updated + $self->{cache_expires_in}))) {
        my $response = $self->request_api(
            method => 'POST',
            endpoint => '/configuration/getIdentifiableApplications',
            query_form_post => {
                enterpriseId => int($self->{entreprise_id})
            }
        );

        $applications = {};
        foreach (@{$response->{applications}}) {
            $applications->{ $_->{id} } = $_->{name};
        }

        $self->{cache_app}->write(data => {
            applications => $applications,
            updated => time()
        });
    }

    return defined($applications->{ $options{app_id} }) ? $applications->{ $options{app_id} } : undef;
}

sub get_apps_metrics {
    my ($self, %options) = @_;

    $self->get_entreprise_id();

    my $start_time = DateTime->now->subtract(seconds => $options{timeframe})->iso8601.'Z';

    my $response = $self->request_api(
        method => 'POST',
        endpoint => '/metrics/getEdgeAppMetrics',
        query_form_post => {
            enterpriseId => int($self->{entreprise_id}),
            edgeId => $options{edge_id},
            metrics => [ 'bytesRx', 'bytesTx', 'packetsRx', 'packetsTx' ],
            interval => {
                start => $start_time
            }
        }
    );

    return $response;
}

sub get_links_qoe {
    my ($self, %options) = @_;

    $self->get_entreprise_id();

    my $start_time = DateTime->now->subtract(seconds => $options{timeframe})->iso8601.'Z';

    my $response = $self->request_api(
        method => 'POST',
        endpoint => '/linkQualityEvent/getLinkQualityEvents',
        query_form_post => {
            enterpriseId => int($self->{entreprise_id}),
            edgeId => $options{edge_id},
            debug => 'false',
            individualScores => 'false',
            maxSamples => '15',
            interval => {
                start => $start_time
            }
        }
    );

    return $response;
}

sub get_categories_metrics {
    my ($self, %options) = @_;

    $self->get_entreprise_id();

    my $start_time = DateTime->now->subtract(seconds => $options{timeframe})->iso8601.'Z';

    my $response = $self->request_api(
        method => 'POST',
        endpoint => '/metrics/getEdgeCategoryMetrics',
        query_form_post => { 
            id => $options{edge_id},
            metrics => [ 'bytesRx', 'bytesTx', 'packetsRx', 'packetsTx' ],
            interval => {
                start => $start_time
            }
        }
    );

    return $response;
}

1;

__END__

=head1 NAME

VMware VeloCloud Orchestrator REST API

=head1 SYNOPSIS

VMware VeloCloud Orchestrator Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

VMware VeloCloud Orchestrator hostname.

=item B<--port>

Port used (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--cache-expires-in>

Cache (application) expires each X secondes (Default: 7200)

=item B<--username>

VMware VeloCloud Orchestrator username.

=item B<--password>

VMware VeloCloud Orchestrator password.

=item B<--operator-user>

Set if the user is an operator.

=item B<--api-path>

API base url path (Default: '/portal/rest').

=item B<--timeframe>

Set timeframe in seconds (Default: 900).

=item B<--timeout>

Set HTTP timeout in seconds (Default: '10').

=back

=head1 DESCRIPTION

B<custom>.

=cut
