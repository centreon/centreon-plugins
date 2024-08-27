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

package hardware::devices::hms::netbiter::argos::restapi::custom::api;

use strict;
use warnings;
use DateTime;
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
            'access-key:s'        => { name => 'access_key' },
            'api-endpoint:s'      => { name => 'api_endpoint' },
            'api-password:s'      => { name => 'api_password' },
            'api-username:s'      => { name => 'api_username' },
            'force-cache-reload'  => { name => 'force_cache_reload' },
            'hostname:s'          => { name => 'hostname' },
            'port:s'              => { name => 'port' },
            'proto:s'             => { name => 'proto' },
            'reload-cache-time:s' => { name => 'reload_cache_time' },
            'timeout:s'           => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
    $self->{cache_auth} = centreon::plugins::statefile->new(%options);
    $self->{cache_sensors} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : 'api.netbiter.net';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_endpoint} = (defined($self->{option_results}->{api_endpoint})) ? $self->{option_results}->{api_endpoint} : '/operation/v1/rest/json';
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{access_key} = (defined($self->{option_results}->{access_key})) ? $self->{option_results}->{access_key} : '';
    $self->{reload_cache_time} = (defined($self->{option_results}->{reload_cache_time})) ? $self->{option_results}->{reload_cache_time} : 3600;
    $self->{force_cache_reload} = (defined($self->{option_results}->{force_cache_reload})) ? $self->{option_results}->{force_cache_reload} : undef;

    if ( !(($self->{api_username} ne '' && $self->{api_password} ne '') || ($self->{access_key} ne '')) ) {
        $self->{output}->add_option_msg(short_msg => 'At least one of --api-username / --api-password (login) ; or --access-key must be set');
        $self->{output}->option_exit();
    }

    $self->{cache_auth}->check_options(option_results => $self->{option_results});
    $self->{cache_sensors}->check_options(option_results => $self->{option_results});

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = '%{http_code} < 200 or %{http_code} > 400';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub convert_iso8601_to_epoch {
    my ($self, %options) = @_;

    if ($options{time_string} =~ /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z/) {
        my $dt = DateTime->new(
            year   => $1,
            month  => $2,
            day    => $3,
            hour   => $4,
            minute => $5,
            second => $6
        );

        my $epoch_time = $dt->epoch();
        return $epoch_time;
    }

    $self->{output}->add_option_msg(short_msg => "Wrong date format: $options{time_string}");
    $self->{output}->option_exit();

}

sub get_access_key {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache_auth}->read(statefile => 'netbiter_argos_api_' . md5_hex($self->{hostname}) . '_' . $self->{cache_key});
    my $expires_on = $self->{cache_auth}->get(name => 'expires_on');
    my $access_key = $self->{cache_auth}->get(name => 'access_key');
    if ( $has_cache_file == 0 || !defined($access_key) || (($expires_on - time()) < 10) ) {
        my $login;
        if ($self->{api_username} ne '') {
          $login = { userName => $self->{api_username}, password => $self->{api_password} };
        }
        my $post_json = JSON::XS->new->utf8->encode($login);

        $self->settings();

        my $content = $self->{http}->request(
            method => 'POST',
            header => ['Content-type: application/json'],
            query_form_post => $post_json,
            url_path => $self->{api_endpoint} . '/user/authenticate'
        );

        if (!defined($content) || $content eq '') {
            $self->{output}->add_option_msg(short_msg => "Authentication endpoint returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $content, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
            $self->{output}->option_exit();
        }
        if (defined($decoded->{error_code})) {
            $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error}, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Authentication endpoint returns error code '" . $decoded->{error_code} . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }

        $access_key = $decoded->{access_key};
        my $expires_on = $self->convert_iso8601_to_epoch(time_string => $decoded->{expires});
        my $datas = { last_timestamp => time(), access_key => $decoded->{accessKey}, expires_on => $expires_on };
        $self->{cache_auth}->write(data => $datas);
    }

    return $access_key;
}

sub request_api {
    my ($self, %options) = @_;

    if (!defined($self->{access_key})) {
        $self->{access_key} = $self->get_access_key(statefile => $self->{cache});
    }

    $self->settings();
    my $url_path = $self->{api_endpoint} . $options{request};
    my $parameters = defined($options{get_params}) ? $options{get_params} : [];
    my $response = $self->{http}->request(
        method    => 'GET',
        get_param => [ 'accesskey=' . $self->{access_key}, @$parameters ],
        url_path  => $url_path
    );
    # check rate limit => to do
    #my $rate_limit = $self->{http}->get_header(name => 'argos-ratelimit-remaining');
    if (!defined($response) || $response eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($response);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }
    return $decoded;
}

sub list_sensors {
    my ($self, %options) = @_;
    # Results are cached to avoid too many API calls
    my $has_cache_file = $self->{cache_sensors}->read(statefile => 'netbiter_cache_sensors_' . md5_hex($options{system_id}));
    my $response = $self->{cache_sensors}->get(name => 'response');
    my $freshness = defined($self->{cache_sensors}->get(name => 'update_time')) ? time() - $self->{cache_sensors}->get(name => 'update_time') : undef;
    $self->{force_cache_reload} = 1 if defined($options{force});

    if ( $has_cache_file == 0 || !defined($response) || (defined($freshness)) && ($freshness > $self->{reload_cache_time}) || defined($self->{force_cache_reload}) ) {
        my $request = '/system/' . $options{system_id} . '/log/config';
        $response = $self->request_api(request => $request);
    }

    $self->{cache_sensors}->write(data => {
        update_time => time(),
        response => $response
    });

    return $response
}

1;

__END__

=head1 NAME

Netbiter Argos RestAPI

=head1 REST API OPTIONS

Netbiter Argos RestAPI

=over 8

=item B<--hostname>

Argos API hostname (default: api.netbiter.net).

=item B<--port>

Port used (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--api-endpoint>

Argos API requests endpoint (default: '/operation/v1/rest/json')

=item B<--access-key>

For Access Key "direct" authentication method.
Example: --access-key='ABCDEFG1234567890'

=item B<--api-username>

For Username/Password authentication method.
Must be used with --api-password option.

=item B<--api-password>

For Username/Password authentication method.
Must be used with --api-username option.

=item B<--timeout>

Set timeout in seconds (default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
