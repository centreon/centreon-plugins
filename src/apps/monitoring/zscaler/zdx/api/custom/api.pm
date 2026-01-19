#
# Copyright 2025-Present Centreon (http://www.centreon.com/)
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

package apps::monitoring::zscaler::zdx::api::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use DateTime;
use JSON::XS;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::misc qw(json_decode is_empty value_of is_excluded);

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
            'key-id:s'     => { name => 'key_id', default => '' },
            'key-secret:s' => { name => 'key_secret', default => '' },
            'api-path:s'   => { name => 'api_path', default => '/v1' },
            'hostname:s'   => { name => 'hostname', default => 'api.zdxcloud.net' },
            'port:s'       => { name => 'port', default => 443 },
            'proto:s'      => { name => 'proto', default => 'https' },
            'timeout:s'    => { name => 'timeout', default => 10 }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
    $self->{cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub get_token {
    my ($self, %options) = @_;

    return $self->{token} if defined($self->{token});

    $self->settings();

    my $has_cache_file = $self->{cache}->read(
            statefile => 'zdx_token_' . md5_hex(
                    $self->{hostname}
                    . ':' . $self->{port}
                    . '_' . $self->{key_id})
    );
    # return token stored in cache if exists after checking it is still valid
    if ($has_cache_file) {
        $self->{token}      = $self->{cache}->get(name => 'token');
        $self->{token_type} = $self->{cache}->get(name => 'token_type');
        my $expiration      = $self->{cache}->get(name => 'expiration');

        if (defined($expiration) && $expiration > time() + 60) {
            $self->{http}->add_header(key => 'Authorization', value => $self->{token_type} . ' ' . $self->{token});
            return $self->{token}
        }
    }

    # if we do not have a token or if it has to be renewed
    my $content = $self->{http}->request(
        method          => 'POST',
        url_path        => '/v1/oauth/token',
        query_form_post => '{"key_id": "' . $self->{key_id} . '", "key_secret": "' . $self->{key_secret} . '"}',

    );
    my $decoded_content = json_decode($content, output => $self->{output});

    $self->{output}->option_exit(short_msg => "No token found in '$content'") unless ($decoded_content->{token});
    $self->{token} = $decoded_content->{token};
    $self->{token_type} = $decoded_content->{token_type};
    $self->{http}->add_header(key => 'Authorization', value => $self->{token_type} . ' ' . $self->{token});
    $self->{cache}->write(data => { token => $decoded_content->{token}, token_type => $decoded_content->{token_type}, expiration => ($decoded_content->{expires_in} + time()) });
    return $self->{token};
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub build_location_filters {
    my ($self, %options) = @_;

    # if location id provided the filter is simple
    return { loc => $options{location_id} } if (!is_empty($options{location_id}));

    # if no location filters are given, do not return anything
    return {} if (is_empty($options{include_location_name}) && is_empty($options{exclude_location_name}));
    # if location filters are provided, get the list of location ids
    my $locations = $self->get_locations(%options);
    # $locations points to an array of {id, name}
    return { loc => [map { $_->{id}} @$locations] };
}

sub get_unique_app {
    my ($self, %options) = @_;

    my $content = $self->{http}->request(
        method     => 'GET',
        get_params => $self->{get_params},
        url_path   => $self->{option_results}->{api_path} . '/apps/' . $options{application_id}
    );
    my $app = json_decode($content, output => $self->{output});
    return {
        id          => $app->{id},
        name        => $app->{name},
        score       => $app->{score},
        total_users => $app->{stats}->{active_users}
    }
}

sub get_unique_app_metrics {
    my ($self, %options) = @_;

    my $to = time();
    my $get_params = { map {$_ => $self->{get_params}->{$_}} keys %{$self->{get_params}} };
    $get_params->{from} = $to - 60 * ($options{max_metrics_age} // 20);
    $get_params->{to} = $to;

    my $content = $self->{http}->request(
        method     => 'GET',
        get_params => $get_params,
        url_path   => $self->{option_results}->{api_path} . '/apps/' . $options{application_id} . '/metrics'
    );

    my $metrics = json_decode($content, output => $self->{output});
    # Example:
    # [
    #   {
    #     "metric": "pft",
    #     "unit": "ms",
    #     "datapoints": [
    #       {
    #         "timestamp": 1767964390,
    #         "value": 1410.8
    #       },
    #       ...
    #     ]
    #   }
    # ]

    my $data = {};

    LOOP_METRICS:
    foreach my $met (@$metrics) {
        $data->{$met->{metric}} = -1; # -1 means no value has been recorded
        LOOP_VALUES:
        while ( my $dp = pop(@{$met->{datapoints}}) ) {
            next LOOP_VALUES if $dp->{value} == -1; # skip if no value
            # we store the first non empty value and exit the loop
            $data->{$met->{metric}} = $dp->{value};
            last LOOP_VALUES;
        }
    }

    return $data;
}

sub get_apps {
    my ($self, %options) = @_;

    $self->get_token();

    # build the params to filter on the locations
    $self->{get_params} = $self->build_location_filters(%options);
    my @stats;
    # either we have a single app to get by its id
    if (!is_empty($options{application_id})) {
        push @stats, $self->get_unique_app(application_id => $options{application_id});
        return \@stats;
    }

    # or we have to get all apps and check which ones match the filters
    my $all_apps_json = $self->{http}->request(
        method     => 'GET',
        get_params => $self->{get_params},
        url_path   => $self->{option_results}->{api_path} . '/apps/'
    );
    my $all_apps = json_decode($all_apps_json, output => $self->{output});

    foreach my $app (@$all_apps) {
        next if is_excluded(
            $app->{name},
            $options{include_application_name},
            $options{exclude_application_name});

        push @stats, {
            id          => $app->{id},
            name        => $app->{name},
            score       => $app->{score},
            total_users => $app->{total_users}
        };
    }

    return \@stats;
}

sub get_locations {
    my ($self, %options) = @_;

    $self->get_token();

    # get all locations and check which ones match the filters
    my $locations_json = $self->{http}->request(
        method     => 'GET',
        url_path   => $self->{option_results}->{api_path} . '/administration/locations/'
    );
    my $locations = json_decode($locations_json, output => $self->{output});

    my @result;
    foreach my $loc (@$locations) {
        next if ($options{location_id} && $loc->{id} ne $options{location_id});
        next if is_excluded(
            $loc->{name},
            $options{include_location_name},
            $options{exclude_location_name});

        push @result, {
            id          => $loc->{id},
            name        => $loc->{name},
        };
    }

    return \@result;
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{$_} = $self->{option_results}->{$_} foreach qw(hostname port proto api_path timeout key_id key_secret );

    foreach (qw(key_id key_secret)) {
        $self->{output}->option_exit(short_msg => "Mandatory option '$_' is missing.") if ($self->{$_} eq '');
        $self->{output}->option_exit(short_msg => "Option '$_' contains illegal characters '$1'") if ($self->{$_} =~ /([\b\f\n\r\t\"\\]+)/);
    }

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub settings {
    my ($self, %options) = @_;

    #$self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

1;

__END__

=head1 NAME

Zscaler Digital Experience (ZDX) Rest API

=head1 SYNOPSIS

Custom mode for Zscaler Digital Experience (ZDX) Rest API

=head1 REST API OPTIONS

Zscaler Digital Experience (ZDX) Rest API

=over 8

=item B<--hostname>

ZDX API hostname (default: C<api.zdxcloud.net>)

=item B<--port>

API port (default: 443)

=item B<--proto>

Specify http if needed (default: 'https')

=item B<--api-path>

API URL path (default: '/api')

=item B<--key-id>

Key ID (see L<here|https://help.zscaler.com/zdx/managing-zdx-api-keys> for more details).

=item B<--key-secret>

Key secret (see L<here|https://help.zscaler.com/zdx/managing-zdx-api-keys> for more details).

=item B<--timeout>

Define HTTP timeout.

=back

=head1 DESCRIPTION

B<custom>.

=cut
