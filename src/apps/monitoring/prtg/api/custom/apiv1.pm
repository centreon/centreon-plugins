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

package apps::monitoring::prtg::api::custom::apiv1;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use centreon::plugins::misc qw/json_decode is_empty/;
use centreon::plugins::constants qw(:messages);
use Digest::SHA qw(sha256_hex);

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
            'hostname:s'             => { name => 'hostname',     default => '' },
            'api-token:s'            => { name => 'api_token',     default => '' },
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
    $options{options}->add_help(package => __PACKAGE__, sections => 'API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
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

    $self->{$_} = $self->{option_results}->{$_} foreach qw/hostname api_token api_path port proto unknown_http_status warning_http_status critical_http_status cache_lifetime/;

    $self->{output}->option_exit(short_msg => "Need to specify --hostname option.")
        if ($self->{hostname} eq '');

    $self->{output}->option_exit(short_msg => "Need to specify --api-token option.")
        if ($self->{api_token} eq '');

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{hostname} . $self->{port};
}

sub settings {
    my ($self, %options) = @_;

    return if $self->{settings_done};
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub request_api {
    my ($self, %options) = @_;

    my $get_param = [@{$options{get_param}}];
    push @$get_param, 'apitoken=' . $self->{api_token};

    $self->settings();
    my ($content) = $self->{http}->request(
        hostname => $self->{hostname},
        url_path => $self->{api_path} . $options{endpoint},
        get_param => $options{get_param},
        header => ['Accept: application/json'],
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status}
    );

    $self->{output}->option_exit(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
        if is_empty($content);

    my $decoded = json_decode($content, output => $self->{output}, no_exit => 1);
    $self->{output}->option_exit(short_msg => MSG_JSON_DECODE_ERROR)
        unless $decoded;

    return $decoded;
}

sub write_cache_file {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_prtg_' . $options{statefile} . '_' . sha256_hex($self->get_connection_info()));
    $self->{cache}->write(data => {
        update_time => time(),
        response => $options{response}
    });
}

sub get_cache_file_response {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_prtg_' . $options{statefile} . '_' . sha256_hex($self->get_connection_info()));
    my $response = $self->{cache}->get(name => 'response');
    $self->{output}->option_exit(short_msg => 'Cache file missing')
        unless $response;

    my $update_time = $self->{cache}->get(name => 'update_time');
    $self->{output}->option_exit(short_msg => 'Cache file expired')
        if (time() - $self->{cache_lifetime}) > $update_time;

    return $response;
}

sub cache_devices {
    my ($self, %options) = @_;

    my $response = $self->get_devices(disable_cache => 1);
    $self->write_cache_file(
        statefile => 'devices',
        response => $response
    );

    return $response;
}

sub cache_sensors {
    my ($self, %options) = @_;

    my $response = $self->get_sensors(disable_cache => 1);
    $self->write_cache_file(
        statefile => 'sensors',
        response => $response
    );

    return $response;
}

my %map_prtg_status = (
    1 => 'unknown',
    2 => 'collecting',
    3 => 'ok',
    4 => 'warning',
    5 => 'critical',
    6 => 'noProbe',
    7 => 'pausedbyUser',
    8 => 'PausedbyDependency',
    9 => 'PausedbySchedule',
    10 => 'unusual',
    11 => 'pausedbyLicense',
    12 => 'pausedUntil',
    13 => 'downAcknowledged',
    14 => 'downPartial'
);

sub get_devices {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'devices')
        if $self->{option_results}->{cache_use} && !$options{disable_cache};

    my $data = $self->request_api(
        endpoint => '/table.json',
        get_param => [
            'content=devices',
            'columns=objid,device,host,probe,status,message,lastvalue,tags,group,active',
            'count=1000000'
        ]
    );

    # PRTG device can have the same name: need to add the group
    my $response = {};
    my $names = {};
    foreach (@{$data->{devices}}) {
        my $name = $_->{device};
        if (defined($names->{ $_->{device} })) {
            $response->{ $names->{ $_->{device} } }->{name} = $_->{device} . '-' . $response->{ $names->{ $_->{device} } }->{group};
            $name .= '-' . $_->{group};
        }

        $names->{$name} = $_->{objid};
        $response->{ $_->{objid} } = {
            id      => $_->{objid},
            name    => $name,
            address => $_->{host},
            status  => $map_prtg_status{ $_->{status_raw} },
            tags    => $_->{tags},
            group   => $_->{group},
            active  => ($_->{active} =~ /true|1/i ? 1 : 0)
        };
    }

    return $response;
}

sub get_sensors {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'sensors')
        if $self->{option_results}->{cache_use} && !$options{disable_cache};

    my $data = $self->request_api(
        endpoint => '/table.json',
        get_param => [
            'content=sensors',
            'columns=objid,parentid,group,tags,device,sensor,status,lastvalue,priority,active',
            'count=1000000'
        ]
    );

    my $response = {};
    foreach (@{$data->{sensors}}) {
        $response->{ $_->{objid} } = {
            id           => $_->{objid},
            parentId     => $_->{parentid}, 
            name         => $_->{sensor},
            status       => $map_prtg_status{ $_->{status_raw} },
            tags         => $_->{tags},
            group        => $_->{group},
            active       => ($_->{active} =~ /true|1/i ? 1 : 0),
            lastvalue    => $_->{lastvalue},
            lastvalueRaw => $_->{lastvalue_raw}
        };
    }

    return $response;
}

1;

__END__

=head1 NAME

PRTG API v1

=head1 API OPTIONS

PRTG API

=over 8

=item B<--hostname>

Define PRTG API hostname

=item B<--api-token>

Define API token.

=item B<--port>

Port used (default: 443)

=item B<--proto>

Define https if needed (default: 'https')

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
