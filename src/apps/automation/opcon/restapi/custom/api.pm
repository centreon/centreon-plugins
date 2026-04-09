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

package apps::automation::opcon::restapi::custom::api;

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
            'api-token:s'            => { name => 'api_token',      default => '' },
            'hostname:s'             => { name => 'hostname',       default => '' },
            'port:s'                 => { name => 'port',           default => 443 },
            'proto:s'                => { name => 'proto',          default => 'https' },
            'timeout:s'              => { name => 'timeout',        default => 50 },
            'api-path:s'             => { name => 'api_path',       default => '/api' },
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
    $self->{output}->option_exit(short_msg => "Need to specify --api-token option.")
        if $self->{option_results}->{api_token} eq '';

    $self->{cache}->check_options(option_results => $self->{option_results}, default_format => 'json');

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

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my $items = [];
    my ($limit, $offset) = (10000, 0);
    while (1) {
        my $get_param = $options{get_param};
        push @$get_param, 'limit=' . $limit, 'offset=' . $offset;
        my ($content) = $self->{http}->request(
            url_path => $self->{api_path} . $options{endpoint},
            get_param => $get_param,
            header => [
                'Accept: application/json',
                'Authorization: Token ' . $self->{option_results}->{api_token}
            ],
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );

        $self->{output}->option_exit(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
            if is_empty($content);

        my $decoded = json_decode($content, output => $self->{output}, no_exit => 1);
        $self->{output}->option_exit(short_msg => MSG_JSON_DECODE_ERROR)
            unless $decoded;

        foreach my $item (@$decoded) {
            push @$items, $options{add_item_closure}->(item => $item);
        }
        last if (scalar(@$decoded) < $limit);

        $offset += $limit;
    }

    return $items;
}

sub write_cache_file {
    my ($self, %options) = @_;

    my $ctime = time();
    $self->{cache}->read(statefile => 'cache_opcon_' . $options{statefile} . '_' . md5_hex($self->get_connection_info() . '_' . $self->{option_results}->{api_token}));
    $self->{cache}->write(data => {
        update_time => $ctime,
        response => $options{response}
    });

    return $ctime;
}

sub get_cache_file_response {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_opcon_' . $options{statefile} . '_' . md5_hex($self->get_connection_info() . '_' . $self->{option_results}->{api_token}));
    my $response = $self->{cache}->get(name => 'response');
    $self->{output}->option_exit(short_msg => 'Cache file missing')
        unless $response;

    my $update_time = $self->{cache}->get(name => 'update_time');
    $self->{output}->option_exit(short_msg => 'Cache file expired')
        if (time() - $self->{cache_lifetime}) > $update_time;

    return ($response, $update_time);
}

sub cache_machines {
    my ($self, %options) = @_;

    my $datas = $self->get_machines(disable_cache => 1);
    my $update_time = $self->write_cache_file(
        statefile => 'machines',
        response => $datas
    );

    return ($datas, $update_time);
}

sub cache_masterJobs {
    my ($self, %options) = @_;

    my $datas = $self->get_masterJobs(disable_cache => 1);
    my $update_time = $self->write_cache_file(
        statefile => 'masterJobs',
        response => $datas
    );

    return ($datas, $update_time);
}

sub cache_jobHistories {
    my ($self, %options) = @_;

    my $datas = $self->get_jobHistories(disable_cache => 1, get_param => $options{get_param});
    my $update_time = $self->write_cache_file(
        statefile => 'jobHistories',
        response => $datas
    );

    return ($datas, $update_time);
}

sub add_machine {
    my (%options) = @_;

    return {
        id => $options{item}->{id},
        name => $options{item}->{name},
        state => $options{item}->{status}->{state},
        networkStatus => $options{item}->{status}->{networkStatus},
        operationStatus => $options{item}->{status}->{operationStatus},
        type => $options{item}->{type}->{description},
        osType => $options{item}->{osType}
    };
}

sub add_masterJobs {
    my (%options) = @_;

    return {
        id => $options{item}->{id},
        name => $options{item}->{name},
        departmentId => $options{item}->{department}->{id}
    };
}

sub add_jobHistories {
    my (%options) = @_;

    return {
        id => $options{item}->{id},
        name => $options{item}->{jobName},
        startTime => $options{item}->{jobStartTime},
        statusNum => $options{item}->{jobStatus}->{id},
        statusDesc => $options{item}->{jobStatus}->{description},
        terminationTime => $options{item}->{jobTermination},
        duration => $options{item}->{duration},
        type => $options{item}->{jobType}->{description}
    };
}

sub get_machines {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'machines')
        if $self->{option_results}->{cache_use} && !$options{disable_cache};

    return $self->request_api(
        endpoint => '/machines',
        add_item_closure => $self->can('add_machine') 
    );
}

sub get_masterJobs {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'masterJobs')
        if $self->{option_results}->{cache_use} && !$options{disable_cache};

    return $self->request_api(
        endpoint => '/masterJobs/v2',
        add_item_closure => $self->can('add_masterJobs') 
    );
}

sub get_jobHistories {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'jobHistories')
        if $self->{option_results}->{cache_use} && !$options{disable_cache};

    return $self->request_api(
        endpoint => '/jobHistories',
        get_param => $options{get_param},
        add_item_closure => $self->can('add_jobHistories') 
    );
}

1;

__END__

=head1 NAME

OpCon Rest API

=head1 REST API OPTIONS

OpCon Rest API

=over 8

=item B<--hostname>

Set hostname.

=item B<--port>

Port used (default: 443)

=item B<--proto>

Define https if needed (default: 'https')

=item B<--api-token>

Define application API token.

=item B<--api-path>

Define API path (default: '/api')

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
