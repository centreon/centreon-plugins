#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::backup::veeam::vbr::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use centreon::plugins::misc qw/json_decode is_empty/;
use centreon::plugins::constants qw(:messages);
use Digest::SHA qw(sha256_hex);

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'api-username:s'         => { name => 'api_username', default => '' },
            'api-password:s'         => { name => 'api_password', default => '' },
            'api-version:s'          => { name => 'api_version', default => '1.3-rev1' },
            'hostname:s'             => { name => 'hostname', default => '' },
            'port:s'                 => { name => 'port', default => 9419 },
            'proto:s'                => { name => 'proto', default => 'https' },
            'timeout:s'              => { name => 'timeout', default => 30 },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
    $self->{cache_connect} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->{output}->option_exit(short_msg => 'Need to specify --hostname option.')
        if $self->{option_results}->{hostname} eq '';
    $self->{output}->option_exit(short_msg => 'Need to specify --api-username option.')
        if $self->{option_results}->{api_username} eq '';
    $self->{output}->option_exit(short_msg => 'Need to specify --api-password option.')
        if $self->{option_results}->{api_password} eq '';
    $self->{output}->option_exit(short_msg => 'Need to specify --api-version option.')
        if $self->{option_results}->{api_version} eq '';

    $self->{cache_connect}->check_options(option_results => $self->{option_results});

    return 0;
}

sub settings {
    my ($self, %options) = @_;

    return if $self->{settings_done};
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'x-api-version', value => $self->{option_results}->{api_version});
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub clean_access_token {
    my ($self, %options) = @_;

    $self->{cache_connect}->write(data => { updated => time() });
}

sub get_access_token {
    my ($self, %options) = @_;

    my $opts = $self->{option_results};
    $self->{cache_connect}->read(statefile => 'veeam_vbr_' . sha256_hex($opts->{hostname} . ':' . $opts->{port} . '_' . $opts->{api_username}));
    my $token = $self->{cache_connect}->get(name => 'access_token');
    my $sha_secret = sha256_hex($opts->{api_username} . $opts->{api_password});

    return $token
        if $token
        && $self->{cache_connect}->get(name => 'expires_at', default => 0) > time() + 30
        && $self->{cache_connect}->get(name => 'sha_secret', default => '') eq $sha_secret;

    my $content = $self->{http}->request(
        method => 'POST',
        url_path => '/api/oauth2/token',
        post_param => [ 'grant_type=password', 'username=' . $opts->{api_username}, 'password=' . $opts->{api_password} ],
        unknown_status => $opts->{unknown_http_status},
        warning_status => $opts->{warning_http_status},
        critical_status => $opts->{critical_http_status}
    );

    my $decoded = json_decode($content, output => $self->{output}, errstr => MSG_JSON_DECODE_ERROR);
    $self->{output}->option_exit(short_msg => 'Cannot find access token')
        unless ref $decoded eq 'HASH' && $decoded->{access_token};

    $self->{cache_connect}->write(data => {
        updated => time(),
        access_token => $decoded->{access_token},
        # Veeam access tokens are valid for 15 minutes by default
        expires_at => time() + ($decoded->{expires_in} // 900),
        sha_secret => $sha_secret
    });

    return $decoded->{access_token};
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my %request = (
        url_path => '/api/v1' . $options{endpoint},
        get_param => $options{get_param}
    );

    my $content = $self->{http}->request(
        %request,
        header => [ 'Authorization: Bearer ' . $self->get_access_token() ],
        unknown_status => '',
        warning_status => '',
        critical_status => ''
    );

    # The cached token may have been revoked or expired early on server side,
    # retry once with a new token before applying the HTTP status thresholds
    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_access_token();
        $content = $self->{http}->request(
            %request,
            header => [ 'Authorization: Bearer ' . $self->get_access_token() ],
            unknown_status => $self->{option_results}->{unknown_http_status},
            warning_status => $self->{option_results}->{warning_http_status},
            critical_status => $self->{option_results}->{critical_http_status}
        );
    }

    $self->{output}->option_exit(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
        if is_empty($content);

    return json_decode($content, output => $self->{output}, errstr => MSG_JSON_DECODE_ERROR);
}

sub request_api_paginate {
    my ($self, %options) = @_;

    my ($skip, $limit, $items) = (0, 200, []);
    while (1) {
        my $result = $self->request_api(
            endpoint => $options{endpoint},
            get_param => [ @{$options{get_param} // []}, 'skip=' . $skip, 'limit=' . $limit ]
        );
        $self->{output}->option_exit(short_msg => "Cannot find data in API response")
            unless ref $result eq 'HASH' && ref $result->{data} eq 'ARRAY';

        push @$items, @{$result->{data}};
        $skip += scalar(@{$result->{data}});
        last if scalar(@{$result->{data}}) == 0
            || !defined($result->{pagination}->{total})
            || $skip >= $result->{pagination}->{total};
    }

    return $items;
}

sub get_license {
    my ($self, %options) = @_;

    return $self->request_api(endpoint => '/license');
}

sub get_job_states {
    my ($self, %options) = @_;

    return $self->request_api_paginate(endpoint => '/jobs/states');
}

sub get_managed_servers {
    my ($self, %options) = @_;

    return $self->request_api_paginate(endpoint => '/backupInfrastructure/managedServers');
}

sub get_repository_states {
    my ($self, %options) = @_;

    return $self->request_api_paginate(
        endpoint => '/backupInfrastructure/repositories/states',
        get_param => $options{exclude_extents} ? [ 'excludeExtents=true' ] : []
    );
}

1;

__END__

=head1 NAME

Veeam Backup & Replication Rest API

=head1 REST API OPTIONS

Veeam Backup & Replication Rest API

=over 8

=item B<--hostname>

Set hostname.

=item B<--port>

Port used (default: 9419)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--api-username>

API username.

=item B<--api-password>

API password.

=item B<--api-version>

Define the REST API version and revision sent in the C<x-api-version> header (default: C<1.3-rev1>).
Use an older revision such as C<1.2-rev1> to monitor a Veeam Backup & Replication 12 server.

=item B<--timeout>

Set timeout in seconds (default: 30).

=item B<--unknown-http-status>

Threshold for unknown HTTP status (default: '%{http_code} < 200 or %{http_code} >= 300').

=item B<--warning-http-status>

Threshold for warning HTTP status.

=item B<--critical-http-status>

Threshold for critical HTTP status.

=back

=head1 DESCRIPTION

B<custom>.

=cut
