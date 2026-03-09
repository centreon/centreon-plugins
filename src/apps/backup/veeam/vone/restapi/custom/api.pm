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

package apps::backup::veeam::vone::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use centreon::plugins::misc qw/json_decode is_empty/;
use centreon::plugins::constants qw(:messages);
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.")
        unless $options{options};
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'api-username:s'         => { name => 'api_username',   default => '' },
            'api-password:s'         => { name => 'api_password',   default => '' },
            'hostname:s'             => { name => 'hostname',       default => '' },
            'port:s'                 => { name => 'port',           default => 1239 },
            'proto:s'                => { name => 'proto',          default => 'https' },
            'timeout:s'              => { name => 'timeout',        default => 50 },
            'api-path:s'             => { name => 'api_path',       default => '/api/v2.2' },
            'unknown-http-status:s'  => { name => 'unknown_http_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' },
            'cache-use'              => { name => 'cache_use' },
            'cache-lifetime:s'       => { name => 'cache_lifetime', default => 1800 }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
    $self->{cache_connect} = centreon::plugins::statefile->new(%options);
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

    $self->{$_} = $self->{option_results}->{$_} foreach qw/api_path unknown_http_status warning_http_status critical_http_status api_username api_password cache_lifetime/;

    $self->{output}->option_exit(short_msg => "Need to specify --hostname option.")
        if $self->{option_results}->{hostname} eq '';
    $self->{output}->option_exit(short_msg => "Need to specify --api-username option.")
        if $self->{api_username} eq '';
    $self->{output}->option_exit(short_msg => "Need to specify --api-password option.")
        if $self->{api_password} eq '';

    $self->{cache_connect}->check_options(option_results => $self->{option_results});
    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{option_results}->{hostname} . ':' . $self->{option_results}->{port};
}

sub settings {
    my ($self, %options) = @_;

    return if $self->{settings_done};
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub clean_access_token {
    my ($self, %options) = @_;

    my $datas = { updated => time() };
    $self->{cache_connect}->write(data => $datas);
}

sub get_access_token {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache_connect}->read(statefile => 'vone_' . md5_hex($self->get_connection_info() . '_' . $self->{api_username}));
    my $token = $self->{cache_connect}->get(name => 'token');
    my $md5_secret_cache = $self->{cache_connect}->get(name => 'md5_secret');
    my $md5_secret = md5_hex($self->{api_username} . $self->{api_password});

    if ($has_cache_file == 0 ||
        !defined($token) ||
        (defined($md5_secret_cache) && $md5_secret_cache ne $md5_secret)
        ) {
        my $content = $self->{http}->request(
            method => 'POST',
            url_path => '/api/token',
            post_param => ['grant_type=password', 'username=' . $self->{api_username}, 'password=' . $self->{api_password}],
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );

        my $decoded = json_decode($content, output => $self->{output});

        $self->{output}->option_exit(short_msg => "Cannot find access token")
            unless ref $decoded eq 'HASH' && $decoded->{access_token};

        $token = $decoded->{access_token};

        my $datas = {
            updated => time(),
            token => $token,
            md5_secret => $md5_secret
        };

        $self->{cache_connect}->write(data => $datas);
    }

    return $token;
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my $token = $self->get_access_token();
    my ($content) = $self->{http}->request(
        url_path => $self->{api_path} . $options{endpoint},
        get_param => $options{get_param},
        header => [
            'Accept: application/json',
            'Authorization: Bearer ' . $token
        ],
        unknown_status => '',
        warning_status => '',
        critical_status => ''
    );

    # Maybe token is invalid. so we retry
    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_access_token();
        $token = $self->get_access_token();
        $content = $self->{http}->request(
            url_path => $self->{api_path} . $options{endpoint},
            get_param => $options{get_param},
            header => [
                'Accept: application/json',
                'Authorization: Bearer ' . $token
            ],
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );
    }

    $self->{output}->option_exit(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
        if is_empty($content);

    my $decoded = json_decode($content, output => $self->{output}, no_exit => 1);
    $self->{output}->option_exit(short_msg => MSG_JSON_DECODE_ERROR)
        unless $decoded;

    return $decoded;
}

sub write_cache_file {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_vone_' . $options{statefile} . '_' . md5_hex($self->get_connection_info() . '_' . $self->{api_username}));
    $self->{cache}->write(data => {
        update_time => time(),
        response => $options{response}
    });
}

sub get_cache_file_response {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_vone_' . $options{statefile} . '_' . md5_hex($self->get_connection_info() . '_' . $self->{api_username}));
    my $response = $self->{cache}->get(name => 'response');
    $self->{output}->option_exit(short_msg => 'Cache file missing')
        unless $response;

    my $update_time = $self->{cache}->get(name => 'update_time');
    $self->{output}->option_exit(short_msg => 'Cache file expired')
        if (time() - $self->{cache_lifetime}) > $update_time;

    return $response;
}

sub cache_vm_replication_jobs {
    my ($self, %options) = @_;

    my $datas = $self->get_vm_replication_jobs(disable_cache => 1, timeframe => $options{timeframe});
    $self->write_cache_file(
        statefile => 'vm_replication_jobs',
        response => $datas
    );

    return $datas;
}

sub cache_vm_backup_jobs {
    my ($self, %options) = @_;

    my $datas = $self->get_vm_backup_jobs(disable_cache => 1, timeframe => $options{timeframe});
    $self->write_cache_file(
        statefile => 'vm_backup_jobs',
        response => $datas
    );

    return $datas;
}

sub cache_backup_copy_jobs {
    my ($self, %options) = @_;

    my $datas = $self->get_backup_copy_jobs(disable_cache => 1, timeframe => $options{timeframe});
    $self->write_cache_file(
        statefile => 'backup_copy_jobs',
        response => $datas
    );

    return $datas;
}

sub cache_repositories {
    my ($self, %options) = @_;

    my $datas = $self->get_repositories(disable_cache => 1);
    $self->write_cache_file(
        statefile => 'repositories',
        response => $datas
    );

    return $datas;
}

sub cache_proxies {
    my ($self, %options) = @_;

    my $datas = $self->get_proxies(disable_cache => 1);
    $self->write_cache_file(
        statefile => 'proxies',
        response => $datas
    );

    return $datas;
}

sub cache_license {
    my ($self, %options) = @_;

    my $datas = $self->get_license(disable_cache => 1);
    $self->write_cache_file(
        statefile => 'license',
        response => $datas
    );

    return $datas;
}

sub get_backup_job_session {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'backup_job_session')
        if $self->{option_results}->{cache_use} && !$options{disable_cache};

    return $self->request_api(
        endpoint => '/api/query',
        get_param => [
            'type=BackupJobSession',
            'format=Entities',
            'filter=CreationTime>='
        ]
    );
}

sub get_repositories {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'repositories')
        if $self->{option_results}->{cache_use} && !$options{disable_cache};

    return $self->request_api(
        endpoint => '/vbr/repositories',
        get_param => ['limit=0']
    );
}

sub get_proxies {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'proxies')
        if $self->{option_results}->{cache_use} && !$options{disable_cache};

    return $self->request_api(
        endpoint => '/vbr/backupProxies',
        get_param => ['limit=0']
    );
}

sub get_license {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'license')
        if $self->{option_results}->{cache_use} && !$options{disable_cache};

    return $self->request_api(
        endpoint => '/license/currentUsage',
        get_param => ['limit=0']
    );
}

sub get_vm_replication_jobs {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'vm_replication_jobs')
        if $self->{option_results}->{cache_use} && !$options{disable_cache};

    return $self->request_api(
        endpoint => '/vbrJobs/vmReplicationJobs',
        get_param => ['limit=0']
    );
}

sub get_vm_backup_jobs {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'vm_backup_jobs')
        if $self->{option_results}->{cache_use} && !$options{disable_cache};

    return $self->request_api(
        endpoint => '/vbrJobs/vmBackupJobs',
        get_param => ['limit=0']
    );
}

sub get_backup_copy_jobs {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'backup_copy_jobs')
        if $self->{option_results}->{cache_use} && !$options{disable_cache};

    return $self->request_api(
        endpoint => '/vbrJobs/backupCopyJobs',
        get_param => ['limit=0']
    );
}

1;

__END__

=head1 NAME

Veeam One Rest API

=head1 REST API OPTIONS

Veeam One Rest API

=over 8

=item B<--hostname>

Set hostname.

=item B<--port>

Port used (default: 1239)

=item B<--proto>

Define https if needed (default: 'https')

=item B<--api-username>

Set username.

=item B<--api-password>

Set password.

=item B<--api-path>

Define API path (default: '/api/v2.2')

=item B<--timeout>

Set timeout in seconds (default: 50).

=item B<--cache-use>

Use the cache file (created with cache mode). 

=item B<--cache-lifetime>

Define the cache lifetime before raising an error (default: 1800 seconds).

=back

=head1 DESCRIPTION

B<custom>.

=cut
