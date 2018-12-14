#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package cloud::azure::custom::api;

use strict;
use warnings;
use DateTime;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use URI::Encode;
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
        $options{options}->add_options(arguments => 
                    {
                        "subscription:s"            => { name => 'subscription' },
                        "tenant:s"                  => { name => 'tenant' },
                        "client-id:s"               => { name => 'client_id' },
                        "client-secret:s"           => { name => 'client_secret' },
                        "login-endpoint:s"          => { name => 'login_endpoint' },
                        "management-endpoint:s"     => { name => 'management_endpoint' },
                        "timeframe:s"               => { name => 'timeframe' },
                        "interval:s"                => { name => 'interval' },
                        "aggregation:s@"            => { name => 'aggregation' },
                        "zeroed"                    => { name => 'zeroed' },
                        "timeout:s"                 => { name => 'timeout' },
                        "proxyurl:s"                => { name => 'proxyurl' },
                    });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode} = $options{mode};
    $self->{http} = centreon::plugins::http->new(output => $self->{output});
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
    $self->{proxyurl} = (defined($self->{option_results}->{proxyurl})) ? $self->{option_results}->{proxyurl} : undef;
    $self->{ssl_opt} = (defined($self->{option_results}->{ssl_opt})) ? $self->{option_results}->{ssl_opt} : undef;
    $self->{timeframe} = (defined($self->{option_results}->{timeframe})) ? $self->{option_results}->{timeframe} : undef;
    $self->{step} = (defined($self->{option_results}->{step})) ? $self->{option_results}->{step} : undef;
    $self->{subscription} = (defined($self->{option_results}->{subscription})) ? $self->{option_results}->{subscription} : undef;
    $self->{tenant} = (defined($self->{option_results}->{tenant})) ? $self->{option_results}->{tenant} : undef;
    $self->{client_id} = (defined($self->{option_results}->{client_id})) ? $self->{option_results}->{client_id} : undef;
    $self->{client_secret} = (defined($self->{option_results}->{client_secret})) ? $self->{option_results}->{client_secret} : undef;
    $self->{login_endpoint} = (defined($self->{option_results}->{login_endpoint})) ? $self->{option_results}->{login_endpoint} : 'https://login.microsoftonline.com';
    $self->{management_endpoint} = (defined($self->{option_results}->{management_endpoint})) ? $self->{option_results}->{management_endpoint} : 'https://management.azure.com';
    $self->{api_version} = (defined($self->{option_results}->{api_version})) ? $self->{option_results}->{api_version} : undef;

    if (!defined($self->{subscription}) || $self->{subscription} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --subscription option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{tenant}) || $self->{tenant} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --tenant option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{client_id}) || $self->{client_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --client-id option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{client_secret}) || $self->{client_secret} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --client-secret option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{api_version}) || $self->{api_version} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-version option.");
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{proxyurl} = $self->{proxyurl};
    $self->{option_results}->{ssl_opt} = $self->{ssl_opt};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
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

    my $has_cache_file = $options{statefile}->read(statefile => 'azure_api_' . md5_hex($self->{subscription}) . '_' . md5_hex($self->{tenant}) . '_' . md5_hex($self->{client_id}));
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $access_token = $options{statefile}->get(name => 'access_token');

    if ($has_cache_file == 0 || !defined($access_token) || (($expires_on - time()) < 10)) {
        my $uri = URI::Encode->new({encode_reserved => 1});
        my $encoded_management_endpoint = $uri->encode($self->{management_endpoint});
        my $post_data = 'grant_type=client_credentials' . 
            '&client_id=' . $self->{client_id} .
            '&client_secret=' . $self->{client_secret} .
            '&resource=' . $encoded_management_endpoint;
        
        $self->settings();

        my $content = $self->{http}->request(method => 'POST', query_form_post => $post_data,
                                             full_url => $self->{login_endpoint} . '/' . $self->{tenant} . '/oauth2/token',
                                             hostname => '');

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $content, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
            $self->{output}->option_exit();
        }
        if (defined($decoded->{error})) {
            $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error_description}, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Login endpoint API return error code '" . $decoded->{error} . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }

        $access_token = $decoded->{access_token};
        my $datas = { last_timestamp => time(), access_token => $decoded->{access_token}, expires_on => $decoded->{expires_on} };
        $options{statefile}->write(data => $datas);
    }
    
    return $access_token;
}

sub request_api {
    my ($self, %options) = @_;

    if (!defined($self->{access_token})) {
        $self->{access_token} = $self->get_access_token(statefile => $self->{cache});
    }

    $self->settings();

    my $content = $self->{http}->request(%options);
    
    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $content, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    if (defined($decoded->{error})) {
        $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error}->{message}, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Management endpoint API return error code '" . $decoded->{error}->{code} . "' (add --debug option for detailed message)");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub azure_get_metrics_set_url {
    my ($self, %options) = @_;

    my $uri = URI::Encode->new({encode_reserved => 1});
    my $encoded_metrics = $uri->encode(join(',', @{$options{metrics}}));
    my $encoded_aggregations = $uri->encode(join(',', @{$options{aggregations}}));
    my $encoded_timespan = $uri->encode($options{start_time} . '/' . $options{end_time});

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription} . "/resourceGroups/" . $options{resource_group} .
        "/providers/" . $options{resource_namespace} . "/" . $options{resource_type} . "/" . $options{resource} . '/providers/microsoft.insights/metrics' .
        "?api-version=" . $self->{api_version} . "&metricnames=" . $encoded_metrics . "&aggregation=" . $encoded_aggregations . "&timespan=" . $encoded_timespan;

    return $url; 
}

sub azure_get_metrics {
    my ($self, %options) = @_;
    
    my $results = {};
    my $start_time = DateTime->now->subtract(seconds => $options{timeframe})->iso8601.'Z';
    my $end_time = DateTime->now->iso8601.'Z';

    my $full_url = $self->azure_get_metrics_set_url(%options, start_time => $start_time, end_time => $end_time);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');

    foreach my $metric (@{$response->{value}}) {
        my $metric_name = lc($metric->{name}->{value});
        $metric_name =~ s/ /_/g;

        $results->{$metric_name} = { points => 0 };
        foreach my $timeserie (@{$metric->{timeseries}}) {
            foreach my $point (@{$timeserie->{data}}) {
                if (defined($point->{average})) {
                    $results->{$metric_name}->{average} = 0 if (!defined($results->{$metric_name}->{average}));
                    $results->{$metric_name}->{average} += $point->{average};
                    $results->{$metric_name}->{points}++;
                }
                if (defined($point->{minimum})) {
                    $results->{$metric_name}->{minimum} = $point->{minimum}
                        if (!defined($results->{$metric_name}->{minimum}) || $point->{minimum} < $results->{$metric_name}->{minimum});
                }
                if (defined($point->{maximum})) {
                    $results->{$metric_name}->{maximum} = $point->{maximum}
                        if (!defined($results->{$metric_name}->{maximum}) || $point->{maximum} > $results->{$metric_name}->{maximum});
                }
                if (defined($point->{total})) {
                    $results->{$metric_name}->{total} = 0 if (!defined($results->{$metric_name}->{total}));
                    $results->{$metric_name}->{total} += $point->{total};
                    $results->{$metric_name}->{points}++;
                }
            }
        }
        
        if (defined($results->{$metric_name}->{average})) {
            $results->{$metric_name}->{average} /= $results->{$metric_name}->{points};
        }
    }
    
    return $results, $response;
}

sub azure_list_resources_set_url {
    my ($self, %options) = @_;
    
    my $filter = '';
    my %filter;
    $filter{resource_type} = "resourceType eq '" . $options{namespace} . '/' . $options{resource_type} . "'" if (defined($options{namespace}) && $options{namespace} ne '' && defined($options{resource_type}) && $options{resource_type} ne '');
    $filter{resource_group} = "resourceGroup eq '" . $options{resource_group} . "'" if (defined($options{resource_group}) && $options{resource_group} ne '');
    $filter{location} = "location eq '" . $options{location} . "'" if (defined($options{location}) && $options{location} ne '');

    my $append = '';
    foreach (('resource_type', 'resource_group', 'location')) {
        next if (!defined($filter{$_}));
        $filter .= $append . $filter{$_};
        $append = ' and ';
    }

    my $uri = URI::Encode->new({encode_reserved => 1});
    my $encoded_filter = $uri->encode($filter);
    
    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription} . "/resources?api-version=" . $self->{api_version};
    $url .= "&\$filter=" . $encoded_filter if (defined($encoded_filter) && $encoded_filter ne '');
    
    return $url; 
}

sub azure_list_resources {
    my ($self, %options) = @_;
    
    my $results = {};    
    my $full_url = $self->azure_list_resources_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
    
    return $response->{value};
}

sub azure_list_vms_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/resourceGroups/" . $options{resource_group} if (defined($options{resource_group}) && $options{resource_group} ne '');
    $url .= "/providers/Microsoft.Compute/virtualMachines?api-version=" . $self->{api_version};
        
    return $url; 
}

sub azure_list_vms {
    my ($self, %options) = @_;
    
    my $results = {};
    my $full_url = $self->azure_list_vms_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
    
    return $response->{value};
}

sub azure_list_groups_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription} . "/resourcegroups?api-version=" . $self->{api_version};
            
    return $url; 
}

sub azure_list_groups {
    my ($self, %options) = @_;
    
    my $results = {};
    my $full_url = $self->azure_list_groups_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
    
    return $response->{value};
}

sub azure_list_deployments_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription} . "/resourcegroups/" .
        $options{resource_group} . "/providers/Microsoft.Resources/deployments?api-version=" . $self->{api_version};
    
    return $url; 
}

sub azure_list_deployments {
    my ($self, %options) = @_;
    
    my $results = {};
    my $full_url = $self->azure_list_deployments_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
    
    return $response->{value};
}

1;

__END__

=head1 NAME

Microsoft Azure Rest API

=head1 REST API OPTIONS

Microsoft Azure Rest API

To connect to the Azure Rest API, you must register an application.

Follow the 'How-to guide' in https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal

This custom mode is using the 'OAuth 2.0 Client Credentials Grant Flow'

For futher informations, visit https://docs.microsoft.com/en-us/azure/active-directory/develop/v1-oauth2-client-creds-grant-flow

=over 8

=item B<--subscription>

Set Azure subscription ID.

=item B<--tenant>

Set Azure tenant ID.

=item B<--client-id>

Set Azure client ID.

=item B<--client-secret>

Set Azure client secret.

=item B<--login-endpoint>

Set Azure login endpoint URL (Default: 'https://login.microsoftonline.com')

=item B<--management-endpoint>

Set Azure management endpoint URL (Default: 'https://management.azure.com')

=item B<--timeframe>

Set timeframe in seconds (i.e. 3600 to check last hour).

=item B<--interval>

Set interval of the metric query (Can be : PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H, PT24H).

=item B<--aggregation>

Set monitor aggregation (Can be multiple, Can be: 'minimum', 'maximum', 'average', 'total').

=item B<--zeroed>

Set metrics value to 0 if none. Usefull when Monitor
does not return value when not defined.

=item B<--timeout>

Set timeout in seconds (Default: 10).

=item B<--proxyurl>

Proxy URL if any

=back

=head1 DESCRIPTION

B<custom>.

=cut
