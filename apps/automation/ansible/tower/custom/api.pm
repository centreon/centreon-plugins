#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::automation::ansible::tower::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;

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
            'username:s'             => { name => 'username' },
            'password:s'             => { name => 'password' },
            'hostname:s'             => { name => 'hostname' },
            'port:s'                 => { name => 'port' },
            'proto:s'                => { name => 'proto' },
            'timeout:s'              => { name => 'timeout' },
            'api-path:s'             => { name => 'api_path' },
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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 80;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'http';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{username} = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : '';
    $self->{password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : '';
    $self->{api_path} = (defined($self->{option_results}->{api_path})) ? $self->{option_results}->{api_path} : '/api/v2';
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

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{credentials} = 1;
    $self->{option_results}->{basic} = 1;
    $self->{option_results}->{username} = $self->{username};
    $self->{option_results}->{password} = $self->{password};
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub request_api {
    my ($self, %options) = @_;

    my $results = [];
    my $page = 1;

    $self->settings();
    while (1) {
        my $path = defined($options{force_endpoint}) ? $self->{api_path} . $options{force_endpoint} : $self->{api_path} . $options{endpoint} . '?page_size=100&page=' . $page;
        my $content = $self->{http}->request(
            method => defined($options{method}) ? $options{method} : 'GET', 
            url_path => $path,
            query_form_post => $options{query_form_post},
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );

        my $code = $self->{http}->get_code();
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

        return $decoded if (defined($options{direct_hash}) && $options{direct_hash} == 1);

        push @$results, @{$decoded->{results}};
        last if (!defined($decoded->{next}));
        last if (defined($options{nonext}) && $options{nonext} == 1);

        $page++;
    }

    return $results;
}

sub tower_list_hosts {
    my ($self, %options) = @_;

    return $self->request_api(endpoint => '/hosts/');
}

sub tower_list_inventories {
    my ($self, %options) = @_;

    return $self->request_api(endpoint => '/inventories/');
}

sub tower_list_projects {
    my ($self, %options) = @_;

    return $self->request_api(endpoint => '/projects/');
}

sub tower_list_job_templates {
    my ($self, %options) = @_;

    return $self->request_api(endpoint => '/job_templates/');
}

sub tower_list_schedules {
    my ($self, %options) = @_;

    my $schedules = $self->request_api(endpoint => '/schedules/');
    if (defined($options{add_job_status})) {
        for (my $i = 0; $i < scalar(@$schedules); $i++) {
            my $job = $self->request_api(
                force_endpoint => '/schedules/' . $schedules->[$i]->{id} . '/jobs/?order_by=-id&page_size=1',
                nonext => 1
            );
            $schedules->[$i]->{last_job} = $job->[0];
        }
    }

    return $schedules;
}

sub tower_list_unified_jobs {
    my ($self, %options) = @_;

    return $self->request_api(endpoint => '/unified_jobs/');
}

sub tower_launch_job_template {
    my ($self, %options) = @_;

    my $json_request = {};
    $json_request->{inventory} = $options{launch_inventory} if (defined($options{launch_inventory}) && $options{launch_inventory} ne '');
    $json_request->{credential} = $options{launch_credential} if (defined($options{launch_credential}));
    $json_request->{job_tags} = $options{launch_tags} if (defined($options{launch_tags}));
    $json_request->{limit} = $options{launch_limit} if (defined($options{launch_limit}));
    $json_request->{extra_vars} = $options{launch_extra_vars} if (defined($options{launch_extra_vars}));

    my $encoded;
    eval {
        $encoded = JSON::XS->new->utf8->encode($json_request);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'Cannot encode request: ' . $@);
        $self->{output}->option_exit();
    }

    my $job = $self->request_api(
        method => 'POST',
        force_endpoint => '/job_templates/' . $options{launch_job_template_id} . '/launch/',
        query_form_post => $encoded,
        direct_hash => 1
    );

    return $job;
}

sub tower_get_job {
    my ($self, %options) = @_;

    return $self->request_api(force_endpoint => '/jobs/' . $options{job_id} . '/', direct_hash => 1);
}

1;

__END__

=head1 NAME

Ansible Tower Rest API

=head1 REST API OPTIONS

Ansible Tower Rest API

=over 8

=item B<--hostname>

Santricity hostname.

=item B<--port>

Port used (Default: 80)

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--username>

API username.

=item B<--password>

API password.

=item B<--api-path>

Specify api path (Default: '/api/v2')

=item B<--timeout>

Set timeout in seconds (Default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
