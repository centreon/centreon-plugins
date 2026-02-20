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

package apps::backup::veeam::vbem::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use DateTime;
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
            'api-username:s'         => { name => 'api_username' },
            'api-password:s'         => { name => 'api_password' },
            'hostname:s'             => { name => 'hostname' },
            'port:s'                 => { name => 'port' },
            'proto:s'                => { name => 'proto' },
            'timeout:s'              => { name => 'timeout' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' },
            'cache-use'              => { name => 'cache_use' }
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

    $self->{option_results}->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{option_results}->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 9398;
    $self->{option_results}->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{option_results}->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 50;
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';

    if ($self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
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

    return if (defined($self->{settings_done}));
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{settings_done} = 1;
}

sub clean_session_id {
    my ($self, %options) = @_;

    my $datas = { updated => time() };
    $self->{cache_connect}->write(data => $datas);
}

sub get_session_id {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache_connect}->read(statefile => 'vbem_' . md5_hex($self->get_connection_info() . '_' . $self->{api_username}));
    my $session_id = $self->{cache_connect}->get(name => 'session_id');
    my $md5_secret_cache = $self->{cache_connect}->get(name => 'md5_secret');
    my $md5_secret = md5_hex($self->{api_username} . $self->{api_password});

    if ($has_cache_file == 0 ||
        !defined($session_id) ||
        (defined($md5_secret_cache) && $md5_secret_cache ne $md5_secret)
        ) {
        my $content = $self->{http}->request(
            method => 'POST',
            url_path => '/api/sessionMngr/',
            query_form_post => '',
            credentials => 1,
            basic => 1,
            username => $self->{api_username},
            password => $self->{api_password},
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );

        $session_id = $self->{http}->get_header(name => 'x-restsvcsessionid');

        if (!defined($session_id)) {
            $self->{output}->add_option_msg(short_msg => "Cannot find session id");
            $self->{output}->option_exit();
        }

        my $datas = {
            updated => time(),
            session_id => $session_id,
            md5_secret => $md5_secret
        };
        $self->{cache_connect}->write(data => $datas);
    }

    return $session_id;
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my $session_id = $self->get_session_id();
    my ($content) = $self->{http}->request(
        url_path => $options{endpoint},
        get_param => $options{get_param},
        header => ['x-restsvcsessionid: ' . $session_id],
        unknown_status => '',
        warning_status => '',
        critical_status => ''
    );

    # Maybe token is invalid. so we retry
    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_session_id();
        $session_id = $self->get_session_id();
        $content = $self->{http}->request(
            url_path => $options{endpoint},
            get_param => $options{get_param},
            header => ['x-restsvcsessionid: ' . $session_id],
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );
    }

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($content);
        $decoded = $self->lowercase_keys(content => $decoded);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub lowercase_keys {
    my ($self, %options) = @_;
    my $ref = $options{content};

    if (ref $ref eq 'HASH') {
        my %new;
        for my $key (keys %$ref) {
            $new{ lc $key } = $self->lowercase_keys(content => $ref->{$key});
        }
        return \%new;
    }
    elsif (ref $ref eq 'ARRAY') {
        return [ map { $self->lowercase_keys(content => $_) } @$ref ];
    }
    else {
        return $ref;
    }
}

sub write_cache_file {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_vbem_' . $options{statefile} . '_' . md5_hex($self->get_connection_info() . '_' . $self->{api_username}));
    $self->{cache}->write(data => {
        update_time => time(),
        response => $options{response}
    });
}

sub get_cache_file_response {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_vbem_' . $options{statefile} . '_' . md5_hex($self->get_connection_info() . '_' . $self->{api_username}));
    my $response = $self->{cache}->get(name => 'response');
    if (!defined($response)) {
        $self->{output}->add_option_msg(short_msg => 'Cache file missing');
        $self->{output}->option_exit();
    }
    return $response;
}

sub cache_backup_job_session {
    my ($self, %options) = @_;

    my $datas = $self->get_backup_job_session(disable_cache => 1, timeframe => $options{timeframe});
    $self->write_cache_file(
        statefile => 'backup_job_session',
        response => $datas
    );

    return $datas;
}


sub cache_repository {
    my ($self, %options) = @_;

    my $datas = $self->get_repository(disable_cache => 1);
    $self->write_cache_file(
        statefile => 'repository',
        response => $datas
    );

    return $datas;
}

sub get_backup_job_session {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'backup_job_session')
        if (defined($self->{option_results}->{cache_use}) && !defined($options{disable_cache}));

    my $creation_time = DateTime->now->subtract(seconds => $options{timeframe})->iso8601();

    return $self->request_api(
        endpoint => '/api/query',
        get_param => [
            'type=BackupJobSession',
            'format=Entities',
            'filter=CreationTime>=' . $creation_time
        ]
    );
}

sub get_replica_job_session {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'replica_job_session')
        if (defined($self->{option_results}->{cache_use}) && !defined($options{disable_cache}));

    my $creation_time = DateTime->now->subtract(seconds => $options{timeframe})->iso8601();

    return $self->request_api(
        endpoint => '/api/query',
        get_param => [
            'type=ReplicaJobSession',
            'format=Entities',
            'filter=CreationTime>=' . $creation_time
        ]
    );
}

sub get_repository {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'repository')
        if (defined($self->{option_results}->{cache_use}) && !defined($options{disable_cache}));

    return $self->request_api(
        endpoint => '/api/query',
        get_param => [
            'type=Repository',
            'format=Entities'
        ]
    );
}

1;

__END__

=head1 NAME

Veeam Backup Enterprise Manager Rest API

=head1 REST API OPTIONS

Veeam Backup Enterprise Manager Rest API

=over 8

=item B<--hostname>

Set hostname.

=item B<--port>

Port used (default: 9398)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--api-username>

Set username.

=item B<--api-password>

Set password.

=item B<--timeout>

Set timeout in seconds (default: 50).

=item B<--cache-use>

Use the cache file (created with cache mode). 

=back

=head1 DESCRIPTION

B<custom>.

=cut
