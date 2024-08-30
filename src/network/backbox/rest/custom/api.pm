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

package network::backbox::rest::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self              = {};
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
            'url-path:s'  => { name => 'url_path' },
            'api-token:s' => { name => 'api_token' },
            'timeout:s'   => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http}   = centreon::plugins::http->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname}  = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{proto}     = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{port}      = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{url_path}  = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/rest/data/token/api/';
    $self->{api_token} = (defined($self->{option_results}->{api_token})) ? $self->{option_results}->{api_token} : '';
    $self->{timeout}   = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_token} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-token option.");
        $self->{output}->option_exit();
    }

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
    $self->{option_results}->{port}     = $self->{port};
    $self->{option_results}->{proto}    = $self->{proto};
    $self->{option_results}->{timeout}  = $self->{timeout};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request {
    my ($self, %options) = @_;

    my $endpoint = $options{full_endpoint};
    if (!defined($endpoint)) {
        $endpoint = $self->{url_path} . $options{endpoint};
    }

    $self->settings();

    my $content = $self->{http}->request(
        method          => 'GET',
        url_path        => $endpoint,
        get_param       => $options{get_param},
        header          => [
            'AUTH: ' . $self->{api_token}
        ],
        warning_status  => '',
        unknown_status  => '',
        critical_status => ''
    );

    # Maybe there is an issue with the token. So we retry.
    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $content = $self->{http}->request(
            url_path        => $endpoint,
            get_param       => $options{get_param},
            header          => [
                'AUTH: ' . $self->{api_token}
            ],
            unknown_status  => $self->{unknown_http_status},
            warning_status  => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );
    }

    my $decoded = $self->json_decode(content => $content);
    if (!defined($decoded)) {
        $self->{output}->add_option_msg(short_msg => 'Error while retrieving data (add --debug option for detailed message)');
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub get_backup_jobs_status {
    my ($self, %options) = @_;

    my $endpoint = 'dashboard/backupStatus';
    if (defined($options{filter_type}) && $options{filter_type} ne '') {
        $endpoint .= '/' . $options{filter_type};
    }
    return $self->request(endpoint => $endpoint);
}

sub get_config_status {
    my ($self, %options) = @_;

    my $endpoint = 'dashboard/configStatus';
    if (defined($options{filter_type}) && $options{filter_type} ne '') {
        $endpoint .= '/' . $options{filter_type};
    }
    return $self->request(endpoint => $endpoint);
}

sub get_intelli_check_status {
    my ($self, %options) = @_;

    my $endpoint = 'dashboard/intelliCheckStatus';
    if (defined($options{filter_type}) && $options{filter_type} ne '') {
        $endpoint .= '/' . $options{filter_type};
    }
    if (defined($options{report_id}) && $options{report_id} ne '') {
        $endpoint .= '/' . $options{report_id};
    }
    return $self->request(endpoint => $endpoint);
}

1;

__END__

=head1 NAME

Backbox API

=head1 SYNOPSIS

Backbox api

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

API hostname.

=item B<--url-path>

API url path (default: '/rest/token/api')

=item B<--port>

API port (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--api-token>

Set API token

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
