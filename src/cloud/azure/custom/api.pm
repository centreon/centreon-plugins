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
        $options{options}->add_options(arguments => {
            'subscription:s'        => { name => 'subscription' },
            'tenant:s'              => { name => 'tenant' },
            'client-id:s'           => { name => 'client_id' },
            'client-secret:s'       => { name => 'client_secret' },
            'login-endpoint:s'      => { name => 'login_endpoint' },
            'management-endpoint:s' => { name => 'management_endpoint' },
            'timeframe:s'           => { name => 'timeframe' },
            'interval:s'            => { name => 'interval' },
            'aggregation:s@'        => { name => 'aggregation' },
            'zeroed'                => { name => 'zeroed' },
            'timeout:s'             => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode_name} = $options{mode_name};
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

    if (defined($self->{option_results}->{aggregation})) {
        foreach my $aggregation (@{$self->{option_results}->{aggregation}}) {
            if ($aggregation !~ /average|maximum|minimum|total|count/i) {
                $self->{output}->add_option_msg(short_msg => "Aggregation '" . $aggregation . "' is not handled");
                $self->{output}->option_exit();
            }
        }
    }

    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{timeframe} = (defined($self->{option_results}->{timeframe})) ? $self->{option_results}->{timeframe} : undef;
    $self->{step} = (defined($self->{option_results}->{step})) ? $self->{option_results}->{step} : undef;
    $self->{subscription} = (defined($self->{option_results}->{subscription})) ? $self->{option_results}->{subscription} : undef;
    $self->{tenant} = (defined($self->{option_results}->{tenant})) ? $self->{option_results}->{tenant} : undef;
    $self->{client_id} = (defined($self->{option_results}->{client_id})) ? $self->{option_results}->{client_id} : undef;
    $self->{client_secret} = (defined($self->{option_results}->{client_secret})) ? $self->{option_results}->{client_secret} : undef;
    $self->{login_endpoint} = (defined($self->{option_results}->{login_endpoint})) ? $self->{option_results}->{login_endpoint} : 'https://login.microsoftonline.com';
    $self->{management_endpoint} = (defined($self->{option_results}->{management_endpoint})) ? $self->{option_results}->{management_endpoint} : 'https://management.azure.com';
    $self->{api_version} = (defined($self->{option_results}->{api_version})) ? $self->{option_results}->{api_version} : undef;

    if ((!defined($self->{subscription}) || $self->{subscription} eq '') && $self->{mode_name} !~ /discovery-tenant/) {
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
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = '%{http_code} < 200 or %{http_code} >= 500';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    if (defined($self->{access_token})) {
        $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{access_token});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_access_token {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(
        statefile =>
            'azure_api_' .
            md5_hex($self->{tenant}) . '_' .
            md5_hex($self->{client_id}) . '_' .
            md5_hex($self->{management_endpoint})
    );
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $access_token = $options{statefile}->get(name => 'access_token');

    if ($has_cache_file == 0 || !defined($access_token) || (($expires_on - time()) < 10)) {
        $self->settings();

        my $content = $self->{http}->request(
            method => 'POST',
            full_url => $self->{login_endpoint} . '/' . $self->{tenant} . '/oauth2/token',
            hostname => '',
            post_param => [
                'grant_type=client_credentials',
                'client_id=' . $self->{client_id},
                'client_secret=' . $self->{client_secret},
                'resource=' . $self->{management_endpoint}
            ]
        );

        if (!defined($content) || $content eq '' || $self->{http}->get_header(name => 'content-length') == 0) {
            $self->{output}->add_option_msg(short_msg => "Login endpoint API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $@, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
            $self->{output}->option_exit();
        }
        if (defined($decoded->{error})) {
            $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error_description}, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Login endpoint API returns error code '" . $decoded->{error} . "' (add --debug option for detailed message)");
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
    if (!defined($content) || $content eq '' || $self->{http}->get_header(name => 'content-length') == 0) {
        $self->{output}->add_option_msg(short_msg => "Management endpoint API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $@, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }
    if (defined($decoded->{error})) {
        $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error}->{message}, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Management endpoint API returns error code '" . $decoded->{error}->{code} . "' (add --debug option for detailed message)");
        $self->{output}->option_exit();
    }
    if (defined($decoded->{code})) {
        $self->{output}->output_add(long_msg => "Message : " . $decoded->{message}, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Management endpoint API returns code '" . $decoded->{code} . "' (add --debug option for detailed message)");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub convert_duration {
    my ($self, %options) = @_;

    my $duration;

    if ($options{time_string} =~ /^P.*S$/) {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output}, module => 'DateTime::Format::Duration::ISO8601',
            error_msg => "Cannot load module 'DateTime::Format::Duration::ISO8601'."
        );

        my $format = DateTime::Format::Duration::ISO8601->new;
        my $d = $format->parse_duration($options{time_string});
        $duration = $d->minutes * 60 + $d->seconds;
    } elsif ($options{time_string} =~ /^(\d+):(\d+):(\d+)\.\d+$/) {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output}, module => 'DateTime::Duration',
            error_msg => "Cannot load module 'DateTime::Format::Duration'."
        );

        my $d = DateTime::Duration->new(hours => $1, minutes => $2, seconds => $3);
        $duration = $d->minutes * 60 + $d->seconds;
    }

    return $duration;
}

sub convert_iso8601_to_epoch {
    my ($self, %options) = @_;

    if ($options{time_string} =~ /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2}).(\d.*)Z/) {
        my $dt = DateTime->new(
            year       => $1,
            month      => $2,
            day        => $3,
            hour       => $4,
            minute     => $5,
            second     => $6,
            nanosecond => $7
        );

        my $epoch_time = $dt->epoch();
        return $epoch_time;

    }

    $self->{output}->add_option_msg(short_msg => "Wrong date format: $options{time_string}");
    $self->{output}->option_exit();

}

sub json_decode {
    my ($self, %options) = @_;

    $options{content} =~ s/\r//mg;
    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($options{content});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    return $decoded;
}


sub azure_get_subscription_cost_management_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription} . "/providers/Microsoft.CostManagement/query?api-version=" . $self->{api_version};

    return $url;
}

sub azure_get_subscription_cost_management {
    my ($self, %options) = @_;

    my $results = {};
    my $encoded_form_post;

    my $full_url = $self->azure_get_subscription_cost_management_set_url();

    eval {
        $encoded_form_post = JSON::XS->new->utf8->encode($options{body_post});
    };

    my $response = $self->request_api(
        method => 'POST',
        full_url => $full_url,
        query_form_post => $encoded_form_post,
        hostname => '',
        header => ['Content-Type: application/json']
    );

    return $response->{properties}->{rows};
}

sub azure_get_metrics_set_url {
    my ($self, %options) = @_;

    my $uri = URI::Encode->new({encode_reserved => 1});
    my $encoded_metrics = $uri->encode(join(',', @{$options{metrics}}));
    my $encoded_aggregations = $uri->encode(join(',', @{$options{aggregations}}));
    my $encoded_timespan = $uri->encode($options{start_time} . '/' . $options{end_time});

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription} . "/resourceGroups/" .
        $options{resource_group} . "/providers/" . $options{resource_namespace} . "/" . $options{resource_type} .
        "/" . $options{resource} . "/providers/microsoft.insights/metrics?api-version=" . $self->{api_version} .
        "&metricnames=" . $encoded_metrics . "&aggregation=" . $encoded_aggregations .
        "&timespan=" . $encoded_timespan . "&interval=" . $options{interval};
    $url .= "&\$filter=" . $options{dimension} if defined($options{dimension});
    $url .= "&metricnamespace=" . $uri->encode($options{metric_namespace}) if defined($options{metric_namespace});

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

        $results->{$metric_name} = { points => 0, name => $metric->{name}->{localizedValue} };
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
                if (defined($point->{count})) {
                    $results->{$metric_name}->{count} = $point->{count};
                }
            }
        }

        if (defined($results->{$metric_name}->{average})) {
            $results->{$metric_name}->{average} /= $results->{$metric_name}->{points};
        }
    }

    return $results, $response;
}

sub azure_get_resource_health_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription} . "/resourceGroups/" .
        $options{resource_group} . "/providers/" . $options{resource_namespace} . "/" . $options{resource_type} .
        "/" . $options{resource} . "/providers/Microsoft.ResourceHealth/availabilityStatuses/current?api-version=" . $options{api_version};

    return $url;
}

sub azure_get_resource_health {
    my ($self, %options) = @_;

    my $full_url = $self->azure_get_resource_health_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');

    return $response;
}

sub azure_get_resource_alert_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription} . "/providers/Microsoft.AlertsManagement/alertsSummary" .
        "?api-version=" . $self->{api_version} . "&groupby=" . $options{group_by} . "&targetResourceGroup=" . $options{resource_group} . "&targetResourceName=" . $options{resource}. "&timeRange=" . $options{time_range};

    return $url;
}

sub azure_get_resource_alert {
    my ($self, %options) = @_;

    my $full_url = $self->azure_get_resource_alert_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');

    return $response;
}

sub azure_list_resources_set_url {
    my ($self, %options) = @_;

    my $filter = '';
    my %filter;
    $filter{resource_type} = "resourceType eq '" . $options{namespace} . '/' . $options{resource_type} . "'" if (defined($options{namespace}) && $options{namespace} ne '' && defined($options{resource_type}) && $options{resource_type} ne '');
    $filter{resource_group} = "resourceGroup eq '" . $options{resource_group} . "'" if (defined($options{resource_group}) && $options{resource_group} ne '');
    $filter{location} = "location eq '" . $options{location} . "'" if (defined($options{location}) && $options{location} ne '');

    my $append = '';

    $self->{subscription} = (defined($options{subscription_id}) ? $options{subscription_id} : $self->{subscription});
    $self->{api_version} = (defined($options{api_version}) ? $options{api_version} : $self->{api_version});

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

    my $full_response = [];

    my $full_url = $self->azure_list_resources_set_url(%options);
    while (1) {
        my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
        foreach (@{$response->{value}}) {
            push @$full_response, $_;
        }

        last if (!defined($response->{nextLink}));
        $full_url = $response->{nextLink};
    }

    return $full_response;
}

sub azure_list_replication_protected_items_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription} . "/resourceGroups/" .
        $options{resource_group} . "/providers/Microsoft.RecoveryServices/vaults/" .
        $options{vault_name} . "/replicationProtectedItems?api-version=" . $self->{api_version};

    return $url;
} 

sub azure_list_replication_protected_items {
    my ($self, %options) = @_;

    my $full_url = $self->azure_list_replication_protected_items_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');

    return $response;
} 

sub azure_get_file_share_stats_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription} . "/resourceGroups/" .
        $options{resource_group} . "/providers/Microsoft.Storage/storageAccounts/" . $options{storage_account} . "/fileServices/default/shares/" .
        $options{fileshare} . "?api-version=" . $options{api_version} . "&\$expand=stats";

    return $url;
}

sub azure_get_file_share_stats {
    my ($self, %options) = @_;

    my $full_url = $self->azure_get_file_share_stats_set_url(%options);

    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');

    return $response;

}

sub azure_list_subscriptions_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions" . "?api-version=" . $options{api_version};

    return $url;
}

sub azure_list_subscriptions {
    my ($self, %options) = @_;

    my $full_response = [];
    my $full_url = $self->azure_list_subscriptions_set_url(%options);

    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');

    return $response->{value};

}

sub azure_list_vms_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/resourceGroups/" . $options{resource_group} if (defined($options{resource_group}) && $options{resource_group} ne '');
    $url .= "/providers/Microsoft.Compute/virtualMachines";
    $url .= (defined($options{force_api_version}) && $options{force_api_version} ne '') ? "?api-version=" . $options{force_api_version} : "?api-version=" . $self->{api_version};
    return $url;
}

sub azure_list_vms {
    my ($self, %options) = @_;
    
    my $full_response = [];
    my $full_url = $self->azure_list_vms_set_url(%options);
    while (1) {
        my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
        foreach (@{$response->{value}}) {
            push @$full_response, $_;
        }

        last if (!defined($response->{nextLink}));
        $full_url = $response->{nextLink};
    }

    return $full_response;
}

sub azure_list_file_shares_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription} . "/resourceGroups/" . $options{resource_group} . "/providers/Microsoft.Storage/storageAccounts/" .
        $options{storage_account} . "/fileServices/default/shares?api-version=" . $options{api_version};
    return $url;
}

sub azure_list_file_shares {
    my ($self, %options) = @_;

    my $full_url = $self->azure_list_file_shares_set_url(%options);
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

    my $full_url = $self->azure_list_deployments_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
    return $response->{value};
}

sub azure_list_vaults_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/resourceGroups/" . $options{resource_group} if (defined($options{resource_group}) && $options{resource_group} ne '');
    $url .= "/providers/Microsoft.RecoveryServices/vaults?api-version=" . $self->{api_version};
    return $url;
}

sub azure_list_vaults {
    my ($self, %options) = @_;

    my $full_url = $self->azure_list_vaults_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
    return $response->{value};
}

sub azure_list_backup_jobs_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription} . "/resourcegroups/" .
        $options{resource_group} . "/providers/Microsoft.RecoveryServices/vaults/" .
        $options{vault_name} . "/backupJobs?api-version=" . $self->{api_version};

    return $url;
}

sub azure_list_backup_jobs {
    my ($self, %options) = @_;

    my $full_url = $self->azure_list_backup_jobs_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
    return $response->{value};
}

sub azure_list_backup_items_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription} . "/resourcegroups/" .
        $options{resource_group} . "/providers/Microsoft.RecoveryServices/vaults/" .
        $options{vault_name} . "/backupProtectedItems?api-version=" . $self->{api_version};

    return $url;
}

sub azure_list_backup_items {
    my ($self, %options) = @_;

    my $full_url = $self->azure_list_backup_items_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');

    return $response->{value};
}

sub azure_list_expressroute_circuits_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/resourceGroups/" . $options{resource_group} if (defined($options{resource_group}) && $options{resource_group} ne '');
    $url .= "/providers/Microsoft.Network/expressRouteCircuits?api-version=" . $self->{api_version};

    return $url;
}

sub azure_list_expressroute_circuits {
    my ($self, %options) = @_;

    my $full_url = $self->azure_list_expressroute_circuits_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');

    return $response->{value};
}

sub azure_list_vpn_gateways_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription} . "/resourcegroups/" .
        $options{resource_group} . "/providers/Microsoft.Network/virtualNetworkGateways?api-version=" . $self->{api_version};

    return $url;
}

sub azure_list_vpn_gateways {
    my ($self, %options) = @_;

    my $full_url = $self->azure_list_vpn_gateways_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');

    return $response->{value};
}

sub azure_list_virtualnetworks_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription} . "/resourcegroups/" .
        $options{resource_group} . "/providers/Microsoft.Network/virtualNetworks?api-version=" . $self->{api_version};

    return $url;
}

sub azure_list_virtualnetworks {
    my ($self, %options) = @_;

    my $full_url = $self->azure_list_virtualnetworks_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');

    return $response->{value};
}

sub azure_list_vnet_peerings_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription} . "/resourcegroups/" .
        $options{resource_group} . "/providers/Microsoft.Network/virtualNetworks/" .
        $options{resource} . "/virtualNetworkPeerings?api-version=" . $self->{api_version};

    return $url;
}

sub azure_list_vnet_peerings {
    my ($self, %options) = @_;

    my $full_url = $self->azure_list_vnet_peerings_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');

    return $response->{value};
}

sub azure_list_sqlservers_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/resourceGroups/" . $options{resource_group} if (defined($options{resource_group}) && $options{resource_group} ne '');
    $url .= "/providers/Microsoft.Sql/servers";
    $url .= (defined($options{force_api_version}) && $options{force_api_version} ne '') ? "?api-version=" . $options{force_api_version} : "?api-version=" . $self->{api_version};
    return $url;
}

sub azure_list_sqlservers {
    my ($self, %options) = @_;

    my $full_response = [];
    my $full_url = $self->azure_list_sqlservers_set_url(%options);
    while (1) {
        my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
        foreach (@{$response->{value}}) {
            push @$full_response, $_;
        }

        last if (!defined($response->{nextLink}));
        $full_url = $response->{nextLink};
    }

    return $full_response;
}

sub azure_list_sqldatabases_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/resourceGroups/" . $options{resource_group} if (defined($options{resource_group}) && $options{resource_group} ne '');
    $url .= "/providers/Microsoft.Sql/servers/" . $options{server} if (defined($options{server}) && $options{server} ne '');
    $url .= (defined($options{force_api_version}) && $options{force_api_version} ne '') ? "?api-version=" . $options{force_api_version} : "?api-version=" . $self->{api_version};
    return $url;
}

sub azure_list_sqldatabases {
    my ($self, %options) = @_;

    my $full_response = [];
    my $full_url = $self->azure_list_sqldatabases_set_url(%options);
    while (1) {
	my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
	foreach (@{$response->{value}}) {
	    push @$full_response, $_;
	}

	last if (!defined($response->{nextLink}));
	$full_url = $response->{nextLink};
    }

    return $full_response;
}

sub azure_get_log_analytics_set_url {
    my ($self, %options) = @_;

    my $uri = URI::Encode->new({encode_reserved => 1});
    my $encoded_query = $uri->encode($options{query});
    my $encoded_timespan = $uri->encode($options{timespan});
    my $url = $self->{management_endpoint} . '/v1/workspaces/' . $options{workspace_id} . '/query?query=' . $encoded_query;
    $url .= '&timespan=' . $encoded_timespan if (defined($encoded_timespan));
    $url .= '&api-version=' . $self->{api_version};

    return $url;
}

sub azure_get_log_analytics {
    my ($self, %options) = @_;

    my $full_url = $self->azure_get_log_analytics_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');

    return $response;
}

sub azure_get_insights_analytics {
    my ($self, %options) = @_;

    my $raw_results = {};
    my $analytics_results = $self->azure_get_log_analytics(
        workspace_id => $options{workspace_id},
        query => $options{query},
        timespan => $options{timespan}
    );

    foreach (@{$analytics_results->{tables}}) {
        my ($i, $j) = (0, 0);
        foreach my $entry (@{$_->{columns}}) {
            $raw_results->{index}->{$entry->{name}} = $i;
            $i++;
        }

        foreach (@{$_->{rows}}) {
            $raw_results->{data}->{$j}->{tags} = @$_[$raw_results->{index}->{Tags}];
            $raw_results->{data}->{$j}->{computer} = @$_[$raw_results->{index}->{Computer}];
            $raw_results->{data}->{$j}->{resourceid} = @$_[$raw_results->{index}->{_ResourceId}];
            if (!defined($options{disco})) {
                $raw_results->{data}->{$j}->{timegenerated} = @$_[$raw_results->{index}->{TimeGenerated}];
                $raw_results->{data}->{$j}->{name} = @$_[$raw_results->{index}->{Name}];
                $raw_results->{data}->{$j}->{value} = @$_[$raw_results->{index}->{Val}];
            }
            $j++;
        }
    }
    return $raw_results;
}

sub azure_get_publicip_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/resourceGroups/" . $options{resource_group} if (defined($options{resource_group}) && $options{resource_group} ne '');
    $url .= "/providers/Microsoft.Network/publicIPAddresses/" . $options{resource} if (defined($options{resource}) && $options{resource} ne '');
    $url .= "?api-version=" . $self->{api_version};

    return $url;
}

sub azure_get_publicip {
    my ($self, %options) = @_;

    my $full_url = $self->azure_get_publicip_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');

    return $response;
}

sub azure_get_budget_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/resourceGroups/" . $options{resource_group} if (defined($options{resource_group}) && $options{resource_group} ne '');
    $url .= "/providers/Microsoft.Consumption/budgets/" . $options{budget_name};
    $url .= "?api-version=" . $self->{api_version};

    return $url;
}

sub azure_get_budget {
    my ($self, %options) = @_;

    my $full_url = $self->azure_get_budget_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');

    return $response;
}

sub azure_list_budget_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/providers/Microsoft.Consumption/budgets";
    $url .= "?api-version=" . $self->{api_version};

    return $url;
}

sub azure_list_budget {
    my ($self, %options) = @_;

    my $full_url = $self->azure_list_budget_set_url(%options);
    my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');

    return $response;
}

sub azure_get_usagedetails_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/resourceGroups/" . $options{resource_group} if (defined($options{resource_group}) && $options{resource_group} ne '');
    $url .= "/providers/Microsoft.Consumption/usageDetails?\$filter=properties%2FusageStart ge %27" . $options{usage_start} . "%27 and properties%2FusageEnd le %27" . $options{usage_end} . "%27";
    $url .= "&metric=". ($options{cost_metric} || 'actualcost');
    $url .= "&api-version=" . $self->{api_version};
    return $url;
}

sub azure_get_usagedetails {
    my ($self, %options) = @_;

    my $full_response = [];
    my $full_url = $self->azure_get_usagedetails_set_url(%options);
    while (1) {
        my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
        foreach (@{$response->{value}}) {
            push @$full_response, $_;
        }

        last if (!defined($response->{nextLink}));
        $full_url = $response->{nextLink};
    }

    return $full_response;
}

sub azure_list_compute_disks_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/resourceGroups/" . $options{resource_group} if (defined($options{resource_group}) && $options{resource_group} ne '');
    $url .= "/providers/Microsoft.Compute/disks";
    $url .= (defined($options{force_api_version}) && $options{force_api_version} ne '') ? "?api-version=" . $options{force_api_version} : "?api-version=" . $self->{api_version};
    return $url;
}

sub azure_list_compute_disks {
    my ($self, %options) = @_;

    my $full_response = [];
    my $full_url = $self->azure_list_compute_disks_set_url(%options);
    while (1) {
	my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
	foreach (@{$response->{value}}) {
	    push @$full_response, $_;
	}

	last if (!defined($response->{nextLink}));
	$full_url = $response->{nextLink};
    }

    return $full_response;
}

sub azure_list_nics_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/resourceGroups/" . $options{resource_group} if (defined($options{resource_group}) && $options{resource_group} ne '');
    $url .= "/providers/Microsoft.Network/networkInterfaces";
    $url .= (defined($options{force_api_version}) && $options{force_api_version} ne '') ? "?api-version=" . $options{force_api_version} : "?api-version=" . $self->{api_version};
    return $url;
}

sub azure_list_nics {
    my ($self, %options) = @_;

    my $full_response = [];
    my $full_url = $self->azure_list_nics_set_url(%options);
    while (1) {
        my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
        foreach (@{$response->{value}}) {
            push @$full_response, $_;
        }

        last if (!defined($response->{nextLink}));
        $full_url = $response->{nextLink};
    }

    return $full_response;
}

sub azure_list_nsgs_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/resourceGroups/" . $options{resource_group} if (defined($options{resource_group}) && $options{resource_group} ne '');
    $url .= "/providers/Microsoft.Network/networkSecurityGroups";
    $url .= (defined($options{force_api_version}) && $options{force_api_version} ne '') ? "?api-version=" . $options{force_api_version} : "?api-version=" . $self->{api_version};
    return $url;
}

sub azure_list_nsgs {
    my ($self, %options) = @_;

    my $full_response = [];
    my $full_url = $self->azure_list_nsgs_set_url(%options);
    while (1) {
        my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
        foreach (@{$response->{value}}) {
            push @$full_response, $_;
        }

        last if (!defined($response->{nextLink}));
        $full_url = $response->{nextLink};
    }

    return $full_response;
}

sub azure_list_publicips_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/resourceGroups/" . $options{resource_group} if (defined($options{resource_group}) && $options{resource_group} ne '');
    $url .= "/providers/Microsoft.Network/publicIPAddresses";
    $url .= (defined($options{force_api_version}) && $options{force_api_version} ne '') ? "?api-version=" . $options{force_api_version} : "?api-version=" . $self->{api_version};
    return $url;
}

sub azure_list_publicips {
    my ($self, %options) = @_;

    my $full_response = [];
    my $full_url = $self->azure_list_publicips_set_url(%options);
    while (1) {
        my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
        foreach (@{$response->{value}}) {
            push @$full_response, $_;
        }

        last if (!defined($response->{nextLink}));
        $full_url = $response->{nextLink};
    }

    return $full_response;
}

sub azure_list_route_tables_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/resourceGroups/" . $options{resource_group} if (defined($options{resource_group}) && $options{resource_group} ne '');
    $url .= "/providers/Microsoft.Network/routeTables";
    $url .= (defined($options{force_api_version}) && $options{force_api_version} ne '') ? "?api-version=" . $options{force_api_version} : "?api-version=" . $self->{api_version};
    return $url;
}

sub azure_list_route_tables {
    my ($self, %options) = @_;

    my $full_response = [];
    my $full_url = $self->azure_list_route_tables_set_url(%options);
    while (1) {
        my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
        foreach (@{$response->{value}}) {
            push @$full_response, $_;
        }

        last if (!defined($response->{nextLink}));
        $full_url = $response->{nextLink};
    }

    return $full_response;
}

sub azure_list_snapshots_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/resourceGroups/" . $options{resource_group} if (defined($options{resource_group}) && $options{resource_group} ne '');
    $url .= "/providers/Microsoft.Compute/snapshots";
    $url .= (defined($options{force_api_version}) && $options{force_api_version} ne '') ? "?api-version=" . $options{force_api_version} : "?api-version=" . $self->{api_version};
    return $url;
}

sub azure_list_snapshots {
    my ($self, %options) = @_;

    my $full_response = [];
    my $full_url = $self->azure_list_snapshots_set_url(%options);
    while (1) {
        my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
        foreach (@{$response->{value}}) {
            push @$full_response, $_;
        }

        last if (!defined($response->{nextLink}));
        $full_url = $response->{nextLink};
    }

    return $full_response;
}

sub azure_list_sqlvms_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/resourceGroups/" . $options{resource_group} if (defined($options{resource_group}) && $options{resource_group} ne '');
    $url .= "/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines";
    $url .= (defined($options{force_api_version}) && $options{force_api_version} ne '') ? "?api-version=" . $options{force_api_version} : "?api-version=" . $self->{api_version}; 
    return $url;
}

sub azure_list_sqlvms {
    my ($self, %options) = @_;

    my $full_response = [];
    my $full_url = $self->azure_list_sqlvms_set_url(%options);
    while (1) {
        my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
        foreach (@{$response->{value}}) {
            push @$full_response, $_;
        }

        last if (!defined($response->{nextLink}));
        $full_url = $response->{nextLink};
    }

    return $full_response;
}

sub azure_list_sqlelasticpools_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/resourceGroups/" . $options{resource_group} if (defined($options{resource_group}) && $options{resource_group} ne '');
    $url .= "/providers/Microsoft.Sql/servers/" . $options{server} if (defined($options{server}) && $options{server} ne '');
    $url .= (defined($options{force_api_version}) && $options{force_api_version} ne '') ? "/elasticPools?api-version=" . $options{force_api_version} : "/elasticPools?api-version=" . $self->{api_version};
    return $url;
}

sub azure_list_sqlelasticpools {
    my ($self, %options) = @_;

    my $full_response = [];
    my $full_url = $self->azure_list_sqlelasticpools_set_url(%options);
    while (1) {
        my $response = $self->request_api(method => 'GET', full_url => $full_url, hostname => '');
        foreach (@{$response->{value}}) {
            push @$full_response, $_;
        }

        last if (!defined($response->{nextLink}));
        $full_url = $response->{nextLink};
    }

    return $full_response;
}

sub azure_set_url {
    my ($self, %options) = @_;

    my $url = $self->{management_endpoint} . "/subscriptions/" . $self->{subscription};
    $url .= "/resourceGroups/" . $options{resource_group} if length $options{resource_group};
    $url .= "/providers/" . $options{providers} if length $options{providers};
    $url .= "/" . $options{resource} if length $options{resource};
    $url .= "/" . $options{query_name};
}

sub azure_list_policystates {
    my ($self, %options) = @_;

    my $get_params = [
        'api-version', $self->{api_version},
        '$select', 'ResourceId, ResourceType, ResourceLocation, ResourceGroup, PolicyDefinitionName, IsCompliant, ComplianceState'
    ];
    my @filters = ();
    if (length $options{resource_location}) {
        push(@filters, ("ResourceLocation eq '" . $options{resource_location} . "'"));
        delete $options{resource_location};
    }
    if (length $options{resource_type}) {
        push(@filters, ("ResourceType eq '" . $options{resource_type} . "'"));
        delete $options{resource_type};
    }
    if (length $options{policy_name}) {
        push(@filters, ("PolicyDefinitionName eq '" . $options{policy_name} . "'"));
        delete $options{policy_name};
    }
    my $filterRequest;
    foreach my $filter (@filters) {
        if (!defined($filterRequest)) {
            $filterRequest = $filter;
        } else {
            $filterRequest .= " and " . $filter;
        }
    }
    if (length$filterRequest) {
        push(@$get_params, '$filter', $filterRequest);
    }

    my ($url) = $self->azure_set_url(%options);
    my $full_response = [];
    while (1) {
        my $response = $self->request_api(
            method => 'POST',
            full_url => $url,
            hostname => '',
            get_params => $get_params,
            query_form_post => '',
            header => ['Content-Type: application/json']
        );
        foreach (@{$response->{value}}) {
            push @$full_response, $_;
        }

        last if (!defined($response->{'@odata.nextLink'}));
        $url = $response->{'@odata.nextLink'};
    }

    return $full_response;
}

1;

__END__

=head1 NAME

Microsoft Azure Rest API

=head1 REST API OPTIONS

Microsoft Azure Rest API

To connect to the Azure Rest API, you must register an application.

Follow the 'How-to guide' at https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal

The application needs the 'Monitoring Reader' role (see https://docs.microsoft.com/en-us/azure/azure-monitor/platform/roles-permissions-security#monitoring-reader).

This custom mode is using the 'OAuth 2.0 Client Credentials Grant Flow'

For further information, visit https://docs.microsoft.com/en-us/azure/active-directory/develop/v1-oauth2-client-creds-grant-flow

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

Set Azure login endpoint URL (default: 'https://login.microsoftonline.com')

=item B<--management-endpoint>

Set Azure management endpoint URL (default: 'https://management.azure.com')

=item B<--timeframe>

Set timeframe in seconds (i.e. 3600 to check last hour).

=item B<--interval>

Set interval of the metric query (can be : C<PT1M>, C<PT5M>, C<PT15M>, C<PT30M>, C<PT1H>, C<PT6H>, C<PT12H>, C<PT24H>).

=item B<--aggregation>

Define how the data must be aggregated. Available aggregations: 'minimum', 'maximum', 'average', 'total'
and 'count'.
Can be called multiple times.

=item B<--zeroed>

Set metrics value to 0 if they are missing. Useful when some metrics are
undefined.

=item B<--timeout>

Set timeout in seconds (default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
