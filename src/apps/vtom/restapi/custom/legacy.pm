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

package apps::vtom::restapi::custom::legacy;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
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
            'api-username:s'    => { name => 'api_username' },
            'api-password:s'    => { name => 'api_password' },
            'hostname:s'        => { name => 'hostname' },
            'port:s'            => { name => 'port' },
            'proto:s'           => { name => 'proto' },
            'timeout:s'         => { name => 'timeout' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' },
            'token:s'                => { name => 'token' },
            'cache-use'              => { name => 'cache_use' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'LEGACY API OPTIONS', once => 1);

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

    $self->{option_results}->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 30080;
    $self->{option_results}->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'http';
    $self->{option_results}->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if (!defined($self->{option_results}->{hostname}) || $self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});

    if ($self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-username option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-password option.');
        $self->{output}->option_exit();
    }

    return 0;
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));

    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{settings_done} = 1;
    $self->{option_results}->{credentials} = 1;
    $self->{option_results}->{basic} = 1;
    $self->{option_results}->{username} = $self->{api_username};
    $self->{option_results}->{password} = $self->{api_password};
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{option_results}->{hostname} . ':' . $self->{option_results}->{port};
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my ($content) = $self->{http}->request(
        url_path => $options{endpoint},
        get_param => $options{get_param},
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status}
    );

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->allow_nonref(1)->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub write_cache_file {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_vtom_' . md5_hex($self->get_connection_info()) . '_' . $options{statefile});
    $self->{cache}->write(data => {
        update_time => time(),
        response => $options{response}
    });
}

sub get_cache_file_response {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_vtom_' . md5_hex($self->get_connection_info()) . '_' . $options{statefile});
    my $response = $self->{cache}->get(name => 'response');
    if (!defined($response)) {
        $self->{output}->add_option_msg(short_msg => 'Cache file missing');
        $self->{output}->option_exit();
    }
    return $response;
}

my $mapping_job_status = {
    R => 'running',
    U => 'notscheduled',
    F => 'finished',
    W => 'waiting',
    E => 'error'
};

sub call_jobs {
    my ($self, %options) = @_;

    my $env = {};
    my $results = $self->request_api(
        endpoint => '/api/environment/list'
    );
    if (defined($results->{result}->{rows})) {
        foreach (@{$results->{result}->{rows}}) {
            $env->{ $_->{id} } = $_->{name};
        }
    }

    my $app = {};
    $results = $self->request_api(
        endpoint => '/api/application/list'
    );
    if (defined($results->{result}->{rows})) {
        foreach (@{$results->{result}->{rows}}) {
            $app->{ $_->{id} } = { application => $_->{name}, environment => $env->{ $_->{envSId} } };
        }
    }

    my $jobs = [];
    $results = $self->request_api(
        endpoint => '/api/job/list'
    );
    $results = defined($results->{result}) && ref($results->{result}) eq 'ARRAY' ? $results->{result} :
            (defined($results->{result}->{rows}) ? $results->{result}->{rows} : []);

    my $current_time = time();
    foreach (@$results) {
        my $applicationId = defined($_->{applicationSId}) ? $_->{applicationSId} : 
            (defined($_->{appSId}) ? $_->{appSId} : undef);
        my $application = defined($applicationId) && defined($app->{$applicationId}) ?
            $app->{$applicationId}->{application} : 'unknown';
        my $environment = defined($applicationId) && defined($app->{$applicationId}) ?
            $app->{$applicationId}->{environment} : 'unknown';
        push @$jobs, {
            application => $application,
            environment => $environment,
            name => $_->{name},
            returnCode => $_->{retcode},
            status => $mapping_job_status->{ $_->{status} },
            message => $_->{information},
            duration => defined($_->{timeBegin}) ? ( $current_time - $_->{timeBegin}) : undef
        };
    }

    return $jobs;
}

sub cache_jobs {
    my ($self, %options) = @_;

    my $datas = $self->call_jobs();
    $self->write_cache_file(
        statefile => 'jobsStatus',
        response => $datas
    );

    return $datas;
}

sub get_jobs {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'jobsStatus')
        if (defined($self->{option_results}->{cache_use}));
    return $self->call_jobs();
}

1;

__END__

=head1 NAME

VTOM Legacy API

=head1 LEGACY API OPTIONS

VTOM Rest API

=over 8

=item B<--hostname>

Set the hostname.

=item B<--port>

Set the port used (default: 30002).

=item B<--proto>

Specify the protocol (default: 'http').

=item B<--api-username>

Set the API username.

=item B<--api-password>

Set the API password.

=item B<--timeout>

Set the timeout in seconds (default: 30).

=back

=head1 DESCRIPTION

B<custom>.

=cut
