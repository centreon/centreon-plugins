#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package cloud::google::gcp::custom::api;

use strict;
use warnings;
use DateTime;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);
use JSON::WebToken;

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
            'key-file:s'               => { name => 'key_file' },
            'authorization-endpoint:s' => { name => 'authorization_endpoint' },
            'monitoring-endpoint:s'    => { name => 'monitoring_endpoint' },
            'scope-endpoint:s'         => { name => 'scope_endpoint' },
            'zeroed'                   => { name => 'zeroed' },
            'timeout:s'                => { name => 'timeout' }
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

    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{key_file} = (defined($self->{option_results}->{key_file})) ? $self->{option_results}->{key_file} : undef;
    $self->{authorization_endpoint} = (defined($self->{option_results}->{authorization_endpoint})) ?
        $self->{option_results}->{authorization_endpoint} : 'https://www.googleapis.com/oauth2/v4/token';
    $self->{monitoring_endpoint} = (defined($self->{option_results}->{monitoring_endpoint})) ?
        $self->{option_results}->{monitoring_endpoint} : 'https://monitoring.googleapis.com/v3';
    $self->{scope_endpoint} = (defined($self->{option_results}->{scope_endpoint})) ?
        $self->{option_results}->{scope_endpoint} : 'https://www.googleapis.com/auth/cloud-platform';

    if (!defined($self->{key_file}) || $self->{key_file} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --key-file option.");
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = '';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_access_token {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'gcp_api_' . md5_hex($self->{key_file} . ':' . $self->{authorization_endpoint}));
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $access_token = $options{statefile}->get(name => 'access_token');

    if ($has_cache_file == 0 || !defined($access_token) || (($expires_on - time()) < 10)) {
        local $/ = undef;
        if (!open(FILE, "<", $self->{key_file})) {
            $self->{output}->output_add(
                severity => 'UNKNOWN',
                short_msg => sprintf("Cannot read file '%s': %s", $self->{key_file}, $!)
            );
            $self->{output}->display();
            $self->{output}->exit();
        }
        my $key_file = <FILE>;
        close FILE;

        my $iat = time();
        my $exp = $iat + 3600;

        my $decoded_key_file;
        eval {
            $decoded_key_file = JSON::XS->new->utf8->decode($key_file);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode key file");
            $self->{output}->option_exit();
        }

        my $jwt = JSON::WebToken->encode({
            iss => $decoded_key_file->{client_email},
            scope => $self->{scope_endpoint},
            aud => $self->{authorization_endpoint},
            exp => $exp,
            iat => $iat,
        }, $decoded_key_file->{private_key}, 'RS256');

        my $content = $self->{http}->request(
            method => 'POST',
            full_url => $self->{authorization_endpoint},
            hostname => '',
            post_param => [
                'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion=' . $jwt
            ]
        );

        if (!defined($content) || $content eq '') {
            $self->{output}->add_option_msg(
                short_msg => "Authorization endpoint API returns empty content [code: '" . $self->{http}->get_code() .
                    "'] [message: '" . $self->{http}->get_message() . "']"
            );
            $self->{output}->option_exit();
        }

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $content, debug => 1);
            $self->{output}->add_option_msg(
                short_msg => "Cannot decode json response (add --debug option to display returned content)"
            );
            $self->{output}->option_exit();
        }
        if (defined($decoded->{error})) {
            $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error_description}, debug => 1);
            $self->{output}->add_option_msg(
                short_msg => "Authorization endpoint API return error code '" . $decoded->{error} .
                    "' (add --debug option for detailed message)"
            );
            $self->{output}->option_exit();
        }

        $access_token = $decoded->{access_token};
        my $datas = { last_timestamp => time(), access_token => $decoded->{access_token}, expires_on => $exp };
        $options{statefile}->write(data => $datas);
    }

    $self->{access_token} = $access_token;
    $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{access_token});
}

sub get_project_id {
    my ($self, %options) = @_;

    local $/ = undef;
    if (!open(FILE, "<", $self->{key_file})) {
        $self->{output}->add_option_msg(
            short_msg => sprintf("Cannot read file '%s': %s", $self->{key_file}, $!)
        );
        $self->{output}->option_exit();
    }
    my $key_file = <FILE>;
    close FILE;

    my $decoded_key_file;
    eval {
        $decoded_key_file = JSON::XS->new->utf8->decode($key_file);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode key file");
        $self->{output}->option_exit();
    }

    return $decoded_key_file->{project_id};
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    if (!defined($self->{access_token})) {
        $self->get_access_token(statefile => $self->{cache});
    }

    my $content = $self->{http}->request(%options);

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(
            short_msg => "Monitoring endpoint API returns empty content [code: '" . $self->{http}->get_code() .
                "'] [message: '" . $self->{http}->get_message() . "']"
        );
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $content, debug => 1);
        $self->{output}->add_option_msg(
            short_msg => "Cannot decode response (add --debug option to display returned content)"
        );
        $self->{output}->option_exit();
    }
    if (defined($decoded->{error})) {
        $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error}->{message}, debug => 1);
        $self->{output}->add_option_msg(
            short_msg => "Monitoring endpoint API return error code '" . $decoded->{error}->{code} .
                "' (add --debug option for detailed message)"
        );
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub gcp_get_metrics_set_url {
    my ($self, %options) = @_;

    my $filter_instance = $options{dimension_name};
    if (defined($options{dimension_operator}) && $options{dimension_operator} eq 'starts') {
        $filter_instance .= ' = starts_with("' . $options{dimension_value} . '")';
    } elsif (defined($options{dimension_operator}) && $options{dimension_operator} eq 'regexp') {
        $filter_instance .= ' = monitoring.regex.full_match("' . $options{dimension_value} . '")';
    } else {
        $filter_instance .= ' = "' . $options{dimension_value} . '"';
    }
    my $filter = 'metric.type = "' . $options{api} . '/' . $options{metric} . '" AND ' . $filter_instance;
    $filter .= ' AND ' . join(' AND ', @{$options{extra_filters}}) 
        if (defined($options{extra_filters}) && $options{extra_filters} ne '');
    my $get_param = [
        'filter=' . $filter,
        'interval.startTime=' . $options{start_time},
        'interval.endTime=' . $options{end_time}
    ];
    my $project_id = $self->get_project_id();
    my $url = $self->{monitoring_endpoint} . '/projects/' . $project_id . '/timeSeries/';

    return ($url, $get_param);
}

sub get_instance {
    my ($self, %options) = @_;

    my $timeserie = $options{timeserie};
    foreach (@{$options{instance_key}}) {
        $timeserie = $timeserie->{$_};
    }
    if (ref($timeserie) !~ /ARRAY|HASH/) {
        return $timeserie;
    }

    return undef;
}

sub gcp_get_metrics {
    my ($self, %options) = @_;

    my $start_time = DateTime->now->subtract(seconds => $options{timeframe})->iso8601() . '.000000Z';
    my $end_time = DateTime->now->iso8601() . '.000000Z';

    my ($url, $get_param) = $self->gcp_get_metrics_set_url(%options, start_time => $start_time, end_time => $end_time);
    my $response = $self->request_api(
        method => 'GET',
        full_url => $url,
        hostname => '',
        get_param => $get_param
    );

    my %aggregations = map { $_ => 1 } @{$options{aggregations}};
    my $instance_key = [split /\./, $options{instance_key}];
    my $results = {};
    foreach my $timeserie (@{$response->{timeSeries}}) {
        my $instance = $self->get_instance(
            timeserie => $timeserie,
            instance_key => $instance_key
        );
        next if (!defined($instance));

        my $metric_name = lc($timeserie->{metric}->{type});
        $metric_name =~ s/$options{api}\///;

        if (!defined($results->{$instance})) {
            $results->{$instance} = {};
        }

        my $metric_calc = { points => 0 };
        foreach my $point (@{$timeserie->{points}}) {
            if (defined($point->{value})) {
                my $value = $point->{value}->{ lc($timeserie->{valueType}) . 'Value' };
                if (defined($aggregations{average})) {
                    $metric_calc->{average} = 0 if (!defined($metric_calc->{average}));
                    $metric_calc->{average} += $value;
                    $metric_calc->{points}++;
                }
                if (defined($aggregations{minimum})) {
                    $metric_calc->{minimum} = $value
                        if (!defined($metric_calc->{$metric_name}->{minimum}) || $value < $$metric_calc->{minimum});
                }
                if (defined($aggregations{maximum})) {
                    $metric_calc->{maximum} = $value
                        if (!defined($metric_calc->{maximum}) || $value > $metric_calc->{maximum});
                }
                if (defined($aggregations{total})) {
                    $metric_calc->{total} = 0 if (!defined($metric_calc->{total}));
                    $metric_calc->{total} += $value;
                    $metric_calc->{points}++;
                }
            }
        }

        if (defined($metric_calc->{average})) {
            $metric_calc->{average} /= $metric_calc->{points};
        }
        $results->{$instance}->{$metric_name} = $metric_calc;
        $results->{$instance}->{resource} = $timeserie->{resource};
        $results->{$instance}->{labels} = $timeserie->{metric}->{labels};
    }

    if (defined($self->{option_results}->{zeroed}) && (!defined($options{dimension_operator}) || $options{dimension_operator} eq '' || $options{dimension_operator} eq 'equals')) {
        if ($options{dimension_name} eq $options{dimension_zeroed} && !defined($results->{ $options{dimension_value} })) { 
            $results->{ $options{dimension_value} } = {
                $options{metric} => { average => 0, minimum => 0, maximum => 0, total => 0 }
            };
        }
    }

    return $results;
}

sub request_api_paginate {
    my ($self, %options) = @_;

    my $items = [];
    my $get_param = [];
    $get_param = $options{get_param} if (defined($options{get_param}));
    while (1) {
        my $response = $self->request_api(
            method => 'GET',
            full_url => $options{url},
            hostname => '',
            get_param => $get_param
        );
        last if (!defined($response->{items}));
        push @$items, @{$response->{items}};

        last if (!defined($response->{nextPageToken}));
        $get_param = [@{$options{get_param}}, 'pageToken=' . $response->{nextPageToken}];
    }

    return $items;
}

sub gcp_compute_engine_set_base_url {
    my ($self, %options) = @_;

    my $project_id = $self->get_project_id();
    my $url = 'https://compute.googleapis.com/compute/v1/projects/' . $project_id;
    return $url;
}

sub gcp_list_compute_engine_zones {
    my ($self, %options) = @_;

    my $url = $self->gcp_compute_engine_set_base_url();
    my $zones = $self->request_api_paginate(
        url => $url . '/zones'
    );
    return $zones;
}

sub gcp_list_compute_engine_instances {
    my ($self, %options) = @_;

    my $results = [];
    my $url = $self->gcp_compute_engine_set_base_url();
    my $zones = $self->gcp_list_compute_engine_zones();
    foreach (@$zones) {
        my $instances = $self->request_api_paginate(
            url => $url . '/zones/' . $_->{name} . '/instances'
        );
        push @$results, @$instances;
    }
    return $results;
}

sub gcp_cloudsql_set_base_url {
    my ($self, %options) = @_;

    my $project_id = $self->get_project_id();
    my $url = 'https://sqladmin.googleapis.com/sql/v1beta4/projects/' . $project_id;
    return $url;
}

sub gcp_list_cloudsql_instances {
    my ($self, %options) = @_;

    my $url = $self->gcp_cloudsql_set_base_url();
    my $instances = $self->request_api_paginate(
        url => $url . '/instances'
    );
    return $instances;
}

sub gcp_list_storage_buckets {
    my ($self, %options) = @_;

    my $buckets = $self->request_api_paginate(
        url => 'https://storage.googleapis.com/storage/v1/b',
        get_param => ['project=' . $self->get_project_id()]
    );
    return $buckets;
}

1;

__END__

=head1 NAME

Google Cloud Platform Rest API

=head1 REST API OPTIONS

Google Cloud Platform Rest API

To connect to the GCP Rest API, you need to create an API key.

Follow the 'How-to guide' in https://cloud.google.com/video-intelligence/docs/common/auth

=over 8

=item B<--key-file>

Set GCP key file path.

=item B<--authorization-endpoint>

Set GCP authorization endpoint URL (Default: 'https://www.googleapis.com/oauth2/v4/token')

=item B<--monitoring-endpoint>

Set GCP monitoring endpoint URL (Default: 'https://monitoring.googleapis.com/v3')

=item B<--scope-endpoint>

Set GCP scope endpoint URL (Default: 'https://www.googleapis.com/auth/cloud-platform')

=item B<--zeroed>

Set metrics value to 0 if none. Usefull when Stackdriver
does not return value when not defined.

=item B<--timeout>

Set timeout in seconds (Default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
