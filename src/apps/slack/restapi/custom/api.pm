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

package apps::slack::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;
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
            'hostname:s'  => { name => 'hostname' },
            'port:s'      => { name => 'port' },
            'proto:s'     => { name => 'proto' },
            'timeout:s'   => { name => 'timeout' },
            'api-path:s'  => { name => 'api_path' },
            'api-token:s' => { name => 'api_token' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : 'slack.com';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_path} = (defined($self->{option_results}->{api_path})) ? $self->{option_results}->{api_path} : '/api';
    $self->{api_token} = (defined($self->{option_results}->{api_token})) ? $self->{option_results}->{api_token} : '';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300' ;
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';
 
    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }
    
    return 0;
}

sub get_connection_infos {
    my ($self, %options) = @_;

    return md5_hex($self->{option_results}->{api_token});
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request_web_api {
    my ($self, %options) = @_;

    if ($self->{api_token} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify api-token option.");
        $self->{output}->option_exit();
    }

    $self->settings();
    my $content = $self->{http}->request(
        method => defined($options{method}) ? $options{method} : 'GET',
        url_path => $self->{api_path} . $options{endpoint},
        post_param => $options{post_param},
        header => [
            'Authorization: Bearer ' . $self->{api_token}
        ],
        critical_status => '',
        warning_status => '',
        unknown_status => ''
    );
    my $decoded;
    eval {
        $decoded = decode_json($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'Cannot decode json response');
        $self->{output}->option_exit();
    }
    if ($decoded->{ok} !~ /1|true/i) {
        $self->{output}->add_option_msg(short_msg => "Error: " . $decoded->{error});
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub get_services {
    my ($self, %options) = @_;

    my $services = {
        'Login/SSO' => 1,
        'Messaging' => 1,
        'Posts/Files' => 1,
        'Calls' => 1,
        'Apps/Integrations/APIs' => 1,
        'Connections' => 1,
        'Link Previews' => 1,
        'Notifications' => 1,
        'Search' => 1,
        'Workspace/Org Administration' => 1
    };
    return $services;
}

sub request_status_api {
    my ($self, %options) = @_;

    $self->settings();
    my $content = $self->{http}->request(
        full_url => 'https://status.slack.com/api/v2.0.0/current',
        hostname => '',
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status}
    );
    my $decoded;
    eval {
        $decoded = decode_json($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'Cannot decode json response');
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

Slack REST API

=head1 SYNOPSIS

Slack Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Slack API hostname (default: 'slack.com').

=item B<--api-path>

Slack API url path (default: '/api').

=item B<--api-token>

Slack API token of app.

=item B<--port>

Slack API port

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
