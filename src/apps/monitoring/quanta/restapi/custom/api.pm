#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::monitoring::quanta::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use DateTime;
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
            'api-token:s'         => { name => 'api_token' },
            'api-path:s'          => { name => 'api_path' },
            'hostname:s'          => { name => 'hostname' },
            'port:s'              => { name => 'port' },
            'proto:s'             => { name => 'proto' },
            'timeout:s'           => { name => 'timeout' },
            'reload-cache-time:s' => { name => 'reload_cache_time' },
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
    $self->{cache_objects} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : 'app.quanta.io';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{api_path} = (defined($self->{option_results}->{api_path})) ? $self->{option_results}->{api_path} : '/api/v1';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_token} = (defined($self->{option_results}->{api_token})) ? $self->{option_results}->{api_token} : '';
    $self->{reload_cache_time} = (defined($self->{option_results}->{reload_cache_time})) ? $self->{option_results}->{reload_cache_time} : 86400;
    $self->{force_cache_reload} = (defined($self->{option_results}->{force_cache_reload})) ? $self->{option_results}->{force_cache_reload} : undef;

    if (!defined($self->{api_token}) || $self->{api_token} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-token option.");
        $self->{output}->option_exit();
    }

    $self->{cache_objects}->check_options(option_results => $self->{option_results});

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{url_path} = $self->{url_path};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = '%{http_code} < 200 or %{http_code} >= 500';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->add_header(key => 'Authorization', value => 'Token ' . $self->{api_token});
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_data_export_api {
    my ($self, %options) = @_;

    $self->settings();

    my ($json, $response, $encoded_form_post);
    eval {
        $encoded_form_post = JSON::XS->new->utf8->encode($options{data});
    };
    my $endpoint = defined($options{is_rum}) ? '/rum_data_export' : '/data_export';
    $response = $self->{http}->request(
        method => 'POST',
        url_path => $self->{api_path} . $endpoint,
        query_form_post => $encoded_form_post
    );

    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->output_add(long_msg => $response);
        $self->{output}->option_exit();
    }    
    eval {
        $json = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode JSON response: $response");
        $self->{output}->option_exit();
    };

    return $json;
}

sub get_configuration_api {
    my ($self, %options) = @_;

    $self->settings();
    my ($json, $response);

    my $get_param = [];
    if (defined($options{get_param})) {
        push @$get_param, $options{get_param};
    }
    
    $response = $self->{http}->request(
        method => 'GET',
        url_path => $self->{api_path} . $options{endpoint},
        get_param => $get_param
    );

    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->output_add(long_msg => $response);
        $self->{output}->option_exit();
    }    
    eval {
        $json = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode JSON response: $response");
        $self->{output}->option_exit();
    };

    return $json;
}

sub list_objects {
    my ($self, %options) = @_;

    my $endpoint = '/sites/' . $options{site_id};
    if ($options{type} =~ 'journey|interaction') {
        $endpoint .= '/user_journeys/';
        if ($options{type} eq 'journey') {
            $endpoint .= $options{journey_id};
        }
        if ($options{type} =~ 'interaction') {
            $endpoint .= $options{journey_id} . '/interactions';
            if ($options{type} eq 'interaction') {
                $endpoint .= '/' . $options{interaction_id};
            }
        }
    }

    # Results are cached to avoid too many API calls
    my $has_cache_file = $self->{cache_objects}->read(statefile => 'quanta_cache_' . md5_hex($options{site_id}) . md5_hex($endpoint));
    my $response = $self->{cache_objects}->get(name => 'response');
    my $freshness = defined($self->{cache_objects}->get(name => 'update_time')) ? time() - $self->{cache_objects}->get(name => 'update_time') : undef;

    if ( $has_cache_file == 0 || !defined($response) || (defined($freshness)) && ($freshness > $self->{reload_cache_time}) ) {
        $response = $self->get_configuration_api(endpoint => $endpoint);
    }

    $self->{cache_objects}->write(data => {
        update_time => time(),
        response => $response
    });

    return $response;
}

1;

__END__

=head1 NAME

Quanta by Centreon Rest API

=head1 SYNOPSIS

Quanta by Centreon Rest API custom mode

=head1 REST API OPTIONS

Quanta by Centreon Rest API

=over 8

=item B<--hostname>

Quanta API hostname (default: 'api.quanta.io')

=item B<--port>

API port (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--api-path>

API URL path (default: '/api/v1')

=item B<--api-token>

API token.

=item B<--timeout>

Set HTTP timeout.

=back

=head1 DESCRIPTION

B<custom>.

=cut
