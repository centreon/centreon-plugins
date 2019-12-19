#
# Copyright 2019 Centreon (http://www.centreon.com/)
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
use URI::Encode;
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
            'key-file:s'                => { name => 'key_file' },
            'authorization-endpoint:s'  => { name => 'authorization_endpoint' },
            'monitoring-endpoint:s'     => { name => 'monitoring_endpoint' },
            'scope-endpoint:s'          => { name => 'scope_endpoint' },
            'timeframe:s'               => { name => 'timeframe' },
            'interval:s'                => { name => 'interval' },
            'aggregation:s@'            => { name => 'aggregation' },
            'zeroed'                    => { name => 'zeroed' },
            'timeout:s'                 => { name => 'timeout' },
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode} = $options{mode};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);
    
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {
    my ($self, %options) = @_;

    foreach (keys %{$options{default}}) {
        if ($_ eq $self->{mode}) {
            for (my $i = 0; $i < scalar(@{$options{default}->{$_}}); $i++) {
                foreach my $opt (keys %{$options{default}->{$_}[$i]}) {
                    if (!defined($self->{option_results}->{$opt}[$i])) {
                        $self->{option_results}->{$opt}[$i] = $options{default}->{$_}[$i]->{$opt};
                    }
                }
            }
        }
    }
}

sub check_options {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{aggregation})) {
        foreach my $aggregation (@{$self->{option_results}->{aggregation}}) {
            if ($aggregation !~ /average|maximum|minimum|total/i) {
                $self->{output}->add_option_msg(short_msg => "Aggregation '" . $aggregation . "' is not handled");
                $self->{output}->option_exit();
            }
        }
    }

    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{timeframe} = (defined($self->{option_results}->{timeframe})) ? $self->{option_results}->{timeframe} : undef;
    $self->{step} = (defined($self->{option_results}->{step})) ? $self->{option_results}->{step} : undef;
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
    $self->{http}->add_header(key => 'Content-Type', value => 'application/x-www-form-urlencoded');
    if (defined($self->{access_token})) {
        $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{access_token});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_access_token {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'gcp_api_' . md5_hex($self->{key_file}));
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
        
        my $post_data = 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' . $jwt;
        
        $self->settings();

        my $content = $self->{http}->request(method => 'POST', query_form_post => $post_data,
                                             full_url => $self->{authorization_endpoint},
                                             hostname => '');

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
    
    return $access_token;
}

sub get_project_id {
    my ($self, %options) = @_;

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

    if (!defined($self->{access_token})) {
        $self->{access_token} = $self->get_access_token(statefile => $self->{cache});
    }

    $self->settings();

    $self->{output}->output_add(long_msg => "URL: '" . $options{full_url} . "'", debug => 1);

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

    my $uri = URI::Encode->new({encode_reserved => 1});
    my $encoded_filter = $uri->encode('metric.type = "' . $options{api} . '/' . $options{metric} . '"');
    $encoded_filter .= $uri->encode(' AND ' . $options{dimension} . ' = starts_with(' . $options{instance} . ')');
    $encoded_filter .= ' AND ' . $uri->encode(join(' AND ', @{$options{extra_filters}}))
        if (defined($options{extra_filters}) && $options{extra_filters} ne '');
    my $encoded_start_time = $uri->encode($options{start_time});
    my $encoded_end_time = $uri->encode($options{end_time});
    my $project_id = $self->get_project_id();

    my $url = $self->{monitoring_endpoint} . "/projects/" . $project_id . "/timeSeries/?filter=" . $encoded_filter .
        "&interval.startTime=" . $encoded_start_time . "&interval.endTime=" . $encoded_end_time;

    return $url;
}

sub gcp_get_metrics {
    my ($self, %options) = @_;

    my $results = {};
    my $start_time = DateTime->now->subtract(seconds => $options{timeframe})->iso8601.'.000000Z';
    my $end_time = DateTime->now->iso8601.'.000000Z';

    my $full_url = $self->gcp_get_metrics_set_url(%options, start_time => $start_time, end_time => $end_time);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');

    my %aggregations = map {$_ => 1} @{$options{aggregations}};

    foreach my $timeserie (@{$response->{timeSeries}}) {
        my $metric_name = lc($timeserie->{metric}->{type});
        $metric_name =~ s/$options{api}\///;
        
        $results->{$metric_name} = { points => 0 };
        foreach my $point (@{$timeserie->{points}}) {
            if (defined($point->{value})) {
                my $value = $point->{value}->{lc($timeserie->{valueType}) . 'Value'};
                if (defined($aggregations{average})) {
                    $results->{$metric_name}->{average} = 0 if (!defined($results->{$metric_name}->{average}));
                    $results->{$metric_name}->{average} += $value;
                    $results->{$metric_name}->{points}++;
                }
                if (defined($aggregations{minimum})) {
                    $results->{$metric_name}->{minimum} = $value
                        if (!defined($results->{$metric_name}->{minimum}) || $value < $results->{$metric_name}->{minimum});
                }
                if (defined($aggregations{maximum})) {
                    $results->{$metric_name}->{maximum} = $value
                        if (!defined($results->{$metric_name}->{maximum}) || $value > $results->{$metric_name}->{maximum});
                }
                if (defined($aggregations{total})) {
                    $results->{$metric_name}->{total} = 0 if (!defined($results->{$metric_name}->{total}));
                    $results->{$metric_name}->{total} += $value;
                    $results->{$metric_name}->{points}++;
                }
            }
        }
        if (defined($results->{$metric_name}->{average})) {
            $results->{$metric_name}->{average} /= $results->{$metric_name}->{points};
        }
        $results->{resource} = $timeserie->{resource};
        $results->{labels} = $timeserie->{metric}->{labels};
    }
    
    return $results, $response;
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

Set GCP scope endpoint URL (Default: 'https://www.googleapis.com/auth/monitoring.read')

=item B<--timeframe>

Set timeframe in seconds (i.e. 3600 to check last hour).

=item B<--aggregation>

Set monitor aggregation (Can be multiple, Can be: 'minimum', 'maximum', 'average', 'total').

=item B<--zeroed>

Set metrics value to 0 if none. Usefull when Stackdriver
does not return value when not defined.

=item B<--timeout>

Set timeout in seconds (Default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
