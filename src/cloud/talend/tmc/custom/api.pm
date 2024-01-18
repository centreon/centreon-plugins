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

package cloud::talend::tmc::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::misc;

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
        $options{options}->add_options(arguments =>  {
            'region:s'       => { name => 'region' },
            'port:s'         => { name => 'port' },
            'proto:s'        => { name => 'proto' },
            'api-token:s'    => { name => 'api_token' },
            'timeout:s'      => { name => 'timeout' },
            'cache-use'      => { name => 'cache_use' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
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

    $self->{region} = (defined($self->{option_results}->{region})) ? lc($self->{option_results}->{region}) : '';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 50;
    $self->{api_token} = (defined($self->{option_results}->{api_token})) ? $self->{option_results}->{api_token} : '';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if ($self->{region} !~ /^eu|us|us-west|ap|au/) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --region option. Can be: eu, us, us-west, ap, au.");
        $self->{output}->option_exit();
    }
    if ($self->{api_token} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-token option.");
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results}, default_format => 'json');
    return 0;
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = 'api.' . $self->{region} . '.cloud.talend.com';
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();

    my $items = [];
    my $offset = 0;
    while (1) {
        my $body = {};
        my $get_param = [];
        if (defined($options{paging})) {
            $body->{limit} = 100;
            $body->{offset} = $offset;
            $get_param = ['limit=100', 'offset=' . $offset];
        }
        if (defined($options{body})) {
            foreach (keys %{$options{body}}) {
                if (defined($options{body}->{$_})) {
                    $body->{$_} = $options{body}->{$_};
                    push @$get_param, $_ . '=' . $options{body}->{$_};
                }
            }
        }

        if ($options{method} eq 'POST') {
            eval {
                $body = encode_json($body);
            };
            if ($@) {
                $self->{output}->add_option_msg(short_msg => 'cannot encode json request');
                $self->{output}->option_exit();
            }
        }

        my ($content) = $self->{http}->request(
            method => $options{method},
            url_path => $options{endpoint},
            get_param => $options{method} eq 'GET' ? $get_param : undef,
            header => ['Authorization: Bearer ' . $self->{api_token}],
            query_form_post => $options{method} eq 'POST' ? $body : undef,
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
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
            $self->{output}->option_exit();
        }

        if (!defined($options{paging})) {
            push @$items, @$decoded;
            last;
        }

        push @$items, @{$decoded->{items}};
        last if (scalar(@$items) >= $decoded->{total});

        $offset += 100;
    }

    return $items;
}

sub cache_environments {
    my ($self, %options) = @_;

    my $datas = $self->get_environments(disable_cache => 1);
    $self->write_cache_file(
        statefile => 'environments',
        response => $datas
    );

    return $datas;
}

sub cache_plans_execution {
    my ($self, %options) = @_;

    my $datas = $self->get_plans_execution(disable_cache => 1, from => $options{from}, to => $options{to});
    $self->write_cache_file(
        statefile => 'plans_execution',
        response => $datas
    );

    return $datas;
}

sub cache_tasks_execution {
    my ($self, %options) = @_;

    my $datas = $self->get_tasks_execution(disable_cache => 1, from => $options{from}, to => $options{to});
    $self->write_cache_file(
        statefile => 'tasks_execution',
        response => $datas
    );

    return $datas;
}

sub cache_plans_config {
    my ($self, %options) = @_;

    my $datas = $self->get_plans_config(disable_cache => 1);
    $self->write_cache_file(
        statefile => 'plans_config',
        response => $datas
    );

    return $datas;
}

sub cache_tasks_config {
    my ($self, %options) = @_;

    my $datas = $self->get_tasks_config(disable_cache => 1);
    $self->write_cache_file(
        statefile => 'tasks_config',
        response => $datas
    );

    return $datas;
}

sub cache_remote_engines {
    my ($self, %options) = @_;

    my $datas = $self->get_remote_engines(disable_cache => 1);
    $self->write_cache_file(
        statefile => 'remote_engines',
        response => $datas
    );

    return $datas;
}

sub write_cache_file {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_talend_tmc_' . $options{statefile} . '_' . $self->{region} . '_' . md5_hex($self->{api_token}));
    $self->{cache}->write(data => {
        update_time => time(),
        response => $options{response}
    });
}

sub get_cache_file_response {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_talend_tmc_' . $options{statefile} . '_' . $self->{region} . '_' . md5_hex($self->{api_token}));
    my $response = $self->{cache}->get(name => 'response');
    if (!defined($response)) {
        $self->{output}->add_option_msg(short_msg => 'Cache file missing');
        $self->{output}->option_exit();
    }
    return $response;
}

sub get_environments {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'environments')
        if (defined($self->{option_results}->{cache_use}) && !defined($options{disable_cache}));
    return $self->request_api(method => 'GET', endpoint => '/orchestration/environments');
}

sub get_plans_execution {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'plans_execution')
        if (defined($self->{option_results}->{cache_use}) && !defined($options{disable_cache})
            && !(defined($options{planId}) && $options{planId} ne ''));
    return $self->request_api(
        method => 'GET',
        endpoint => (defined($options{planId}) && $options{planId} ne '') ? 
            '/processing/executables/plans/' . $options{planId} . '/executions' : '/processing/executables/plans/executions',
        body => {
            from => $options{from},
            to => $options{to},
            environmentId => $options{environmentId}
        },
        paging => 1
    );
}

sub get_tasks_execution {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'tasks_execution')
        if (defined($self->{option_results}->{cache_use}) && !defined($options{disable_cache})
            && !(defined($options{taskId}) && $options{taskId} ne ''));
    return $self->request_api(
        method => (defined($options{taskId}) && $options{taskId} ne '') ? 'GET' : 'POST',
        endpoint => (defined($options{taskId}) && $options{taskId} ne '') ? 
            '/processing/executables/tasks/' . $options{taskId} . '/executions' : '/processing/executables/tasks/executions',
        body => {
            from => $options{from},
            to => $options{to},
            environmentId => $options{environmentId}
        },
        paging => 1
    );
}

sub get_plans_config {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'plans_config')
        if (defined($self->{option_results}->{cache_use}) && !defined($options{disable_cache}));
    return $self->request_api(
        method => 'GET',
        endpoint => '/orchestration/executables/plans',
        paging => 1
    );
}

sub get_tasks_config {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'tasks_config')
        if (defined($self->{option_results}->{cache_use}) && !defined($options{disable_cache}));
    return $self->request_api(
        method => 'GET',
        endpoint => '/orchestration/executables/tasks',
        paging => 1
    );
}

sub get_remote_engines {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'remote_engines')
        if (defined($self->{option_results}->{cache_use}) && !defined($options{disable_cache}));
    return $self->request_api(
        method => 'GET',
        endpoint => '/processing/runtimes/remote-engines'
    );
}

1;

__END__

=head1 NAME

Cloud Talend REST API

=head1 SYNOPSIS

Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--region>

Region (required). Can be: eu, us, us-west, ap, au.

=item B<--port>

Port used (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--api-token>

API token.

=item B<--timeout>

Set HTTP timeout

=item B<--cache-use>

Use the cache file (created with cache mode). 

=back

=head1 DESCRIPTION

B<custom>.

=cut
