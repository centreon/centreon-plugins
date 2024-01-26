#
# Copyright 2024 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged instry-strength solution that meets
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

package apps::monitoring::kadiska::mode::watcherstatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_usage_perfdata_ms {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'ms',
        instances => [ $self->{result_values}->{watcher_name}, $self->{result_values}->{site_name}, $self->{result_values}->{gateway_name} ],
        value => sprintf('%.2f', $self->{result_values}->{ $self->{key_values}->[0]->{name} } ),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [ $self->{result_values}->{watcher_name}, $self->{result_values}->{site_name}, $self->{result_values}->{gateway_name} ],
        value => sprintf('%.2f', $self->{result_values}->{ $self->{key_values}->[0]->{name} } ),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub country_prefix_output {
    my ($self, %options) = @_;

    return sprintf("Country '%s' ", $options{instance});
}

sub isp_prefix_output {
    my ($self, %options) = @_;

    return sprintf("ISP '%s' ", $options{instance});
}

sub watcher_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking watcher '%s' [site name: %s] [gateway: %s]:",
        $options{instance_value}->{watcher_name},
        $options{instance_value}->{site_name},
        $options{instance_value}->{gateway_name}
    );
}

sub prefix_watcher_output {
    my ($self, %options) = @_;

    return sprintf(
        "Watcher '%s' [site name: %s] [gateway: %s] : ",
        $options{instance_value}->{watcher_name},
        $options{instance_value}->{site_name},
        $options{instance_value}->{gateway_name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'country', type => 1, cb_prefix_output => 'country_prefix_output', message_multiple => 'All countries are ok' },
        { name => 'isp', type => 1, cb_prefix_output => 'isp_prefix_output', message_multiple => 'All ISP are ok' },
        { name => 'watcher', type => 3, cb_prefix_output => 'prefix_watcher_output', message_multiple => 'All watchers are ok', 
          cb_long_output => 'watcher_long_output', indent_long_output => '    ',
            group => [
                { name => 'dtt_spent', type => 0, skipped_code => { -10 => 1 }},
                { name => 'errors_prct', type => 0, skipped_code => { -10 => 1 }},
                { name => 'full_network_time_spent', type => 0, skipped_code => { -10 => 1 }},
                { name => 'loading_page', type => 0, skipped_code => { -10 => 1 }},
                { name => 'pages', type => 0, skipped_code => { -10 => 1 }},
                { name => 'processing', type => 0, skipped_code => { -10 => 1 }},
                { name => 'redirect_time_avg', type => 0, skipped_code => { -10 => 1 }},
                { name => 'requests', type => 0, skipped_code => { -10 => 1 }},
                { name => 'sessions', type => 0, skipped_code => { -10 => 1 }},
                { name => 'srt_spent', type => 0, skipped_code => { -10 => 1 }},
                { name => 'users', type => 0, skipped_code => { -10 => 1 }},
                { name => 'waiting_time', type => 0, skipped_code => { -10 => 1 }}
            ]
        }
    ];

    $self->{maps_counters}->{isp} = [
        { label => 'isp-dtt-spent', nlabel => 'isp.dtt.spent.time.milliseconds', set => {
                key_values => [ { name => 'dtt_spent' } ],
                output_template => 'DTT spent: %.2f ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'isp-errors-prct', nlabel => 'isp.errors.percentage', set => {
                key_values => [ { name => 'errors_prct' } ],
                output_template => 'Errors: %.2f%%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'isp-full-time-network-spent', nlabel => 'isp.network.spent.time.milliseconds', set => {
                key_values => [ { name => 'full_time_network_spent' } ],
                output_template => 'Full time network spent: %.2f ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'isp-sessions', nlabel => 'isp.sessions.count', set => {
                key_values => [ { name => 'sessions' } ],
                output_template => 'Sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'isp-srt-spent', nlabel => 'isp.srt.spent.time.milliseconds', set => {
                key_values => [ { name => 'srt_spent' } ],
                output_template => 'SRT spent: %.2f ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'isp-requests', nlabel => 'isp.requests.count', set => {
                key_values => [ { name => 'requests' } ],
                output_template => 'Requests: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'isp-redirect-time-avg', nlabel => 'isp.redirect.time.milliseconds', set => {
                key_values => [ { name => 'redirect_time_avg' } ],
                output_template => 'Redirect time avg: %.2f ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'isp-loading-page', nlabel => 'isp.loading.page.duration.milliseconds', set => {
                key_values => [ { name => 'loading_page' } ],
                output_template => 'Loading page duration: %.2f ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },   
        { label => 'isp-pages', nlabel => 'isp.pages.count', set => {
                key_values => [ { name => 'pages' } ],
                output_template => 'Loaded pages: %d',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'isp-processing', nlabel => 'isp.processing.duration.milliseconds', set => {
                key_values => [ { name => 'processing' } ],
                output_template => 'API Processing duration: %.2f ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },  
        { label => 'isp-users', nlabel => 'isp.users.count', set => {
                key_values => [ { name => 'users' } ],
                output_template => 'Connected users: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'isp-waiting-time-avg', nlabel => 'isp.waiting.time.milliseconds', set => {
                key_values => [ { name => 'waiting_time_avg' } ],
                output_template => 'Waiting time avg: %.2f ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        } 
    ];

    $self->{maps_counters}->{country} = [
        { label => 'country-dtt-spent', nlabel => 'watcher.dtt.spent.time.milliseconds', set => {
                key_values => [ { name => 'dtt_spent' } ],
                output_template => 'DTT spent: %.2f ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'country-errors-prct', nlabel => 'watcher.errors.percentage', set => {
                key_values => [ { name => 'errors_prct' } ],
                output_template => 'Errors: %.2f%%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'country-full-time-network-spent', nlabel => 'watcher.network.spent.time.milliseconds', set => {
                key_values => [ { name => 'full_time_network_spent' } ],
                output_template => 'Full time network spent: %.2f ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'country-sessions', nlabel => 'watcher.sessions.count', set => {
                key_values => [ { name => 'sessions' } ],
                output_template => 'Sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'country-srt-spent', nlabel => 'watcher.srt.spent.time.milliseconds', set => {
                key_values => [ { name => 'srt_spent' } ],
                output_template => 'SRT spent: %.2f ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'country-requests', nlabel => 'watcher.requests.count', set => {
                key_values => [ { name => 'requests' } ],
                output_template => 'Requests: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'country-redirect-time-avg', nlabel => 'watcher.redirect.time.milliseconds', set => {
                key_values => [ { name => 'redirect_time_avg' } ],
                output_template => 'Redirect time avg: %.2f ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'country-loading-page', nlabel => 'watchers.loading.page.duration.milliseconds', set => {
                key_values => [ { name => 'loading_page' } ],
                output_template => 'Loading page duration: %.2f ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },   
        { label => 'country-pages', nlabel => 'watchers.pages.count', set => {
                key_values => [ { name => 'pages' } ],
                output_template => 'Loaded pages: %d',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'country-processing', nlabel => 'watchers.processing.duration.milliseconds', set => {
                key_values => [ { name => 'processing' } ],
                output_template => 'API Processing duration: %.2f ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },  
        { label => 'country-users', nlabel => 'watchers.users.count', set => {
                key_values => [ { name => 'users' } ],
                output_template => 'Connected users: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'country-waiting-time-avg', nlabel => 'watchers.waiting.time.milliseconds', set => {
                key_values => [ { name => 'waiting_time_avg' } ],
                output_template => 'Waiting time avg: %.2f ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        } 
    ];

    $self->{maps_counters}->{dtt_spent} = [
        { label => 'watcher-dtt-spent', nlabel => 'watcher.dtt.spent.time.milliseconds', set => {
                key_values => [ { name => 'dtt_spent' }, { name => 'watcher_name' }, { name => 'site_name'}, { name => 'gateway_name'} ],
                output_template => 'DTT spent: %.2f ms',
                closure_custom_perfdata => $self->can('custom_usage_perfdata_ms')
            }
        }
    ];

    $self->{maps_counters}->{errors_prct} = [
        { label => 'watcher-errors-prct', nlabel => 'watcher.errors.percentage', set => {
                key_values => [ { name => 'errors_prct' }, { name => 'watcher_name' }, { name => 'site_name'}, { name => 'gateway_name'} ],
                output_template => 'Errors: %.2f%%',
                closure_custom_perfdata => $self->can('custom_usage_perfdata')
            }
        }
    ];

    $self->{maps_counters}->{full_network_time_spent} = [
        { label => 'watcher-full-network-time-spent',  nlabel => 'watcher.network.spent.time.milliseconds', set => {
                key_values => [ { name => 'full_network_time_spent' }, { name => 'watcher_name' }, { name => 'site_name'}, { name => 'gateway_name'} ],
                output_template => 'Full network time spent: %.2f ms',
                closure_custom_perfdata => $self->can('custom_usage_perfdata_ms')
            }
        }
    ];

    $self->{maps_counters}->{loading_page} = [
        { label => 'watcher-loading-page', nlabel => 'watcher.loading.page.duration.milliseconds', set => {
                key_values => [ { name => 'loading_page' }, { name => 'watcher_name' }, { name => 'site_name'}, { name => 'gateway_name'} ],
                output_template => 'Loading page duration: %.2f ms',
                closure_custom_perfdata => $self->can('custom_usage_perfdata_ms')
            }
        }
    ];

    $self->{maps_counters}->{pages} = [
        { label => 'watcher-pages', nlabel => 'watcher.pages.count', set => {
                key_values => [ { name => 'pages' }, { name => 'watcher_name' }, { name => 'site_name'}, { name => 'gateway_name'} ],
                output_template => 'Loaded pages: %d',
                closure_custom_perfdata => $self->can('custom_usage_perfdata')
            }
        }
    ];

    $self->{maps_counters}->{processing} = [
        { label => 'watcher-processing', nlabel => 'watcher.processing.duration.milliseconds', set => {
                key_values => [ { name => 'processing' }, { name => 'watcher_name' }, { name => 'site_name'}, { name => 'gateway_name'} ],
                output_template => 'API Processing duration: %.2f ms',
                closure_custom_perfdata => $self->can('custom_usage_perfdata_ms')
            }
        }
    ];

    $self->{maps_counters}->{redirect_time_avg} = [
        { label => 'watcher-redirect-time-avg', nlabel => 'watcher.redirect.time.milliseconds', set => {
                key_values => [ { name => 'redirect_time_avg' }, { name => 'watcher_name' }, { name => 'site_name'}, { name => 'gateway_name'} ],
                output_template => 'Redirect time avg: %.2f ms',
                closure_custom_perfdata => $self->can('custom_usage_perfdata_ms')
            }
        }        
    ];

    $self->{maps_counters}->{requests} = [
        { label => 'watcher-requests', nlabel => 'watcher.requests.count', set => {
                key_values => [ { name => 'requests' }, { name => 'watcher_name' }, { name => 'site_name'}, { name => 'gateway_name'} ],
                output_template => 'Requests: %s',
                closure_custom_perfdata => $self->can('custom_usage_perfdata')
            }
        }        
    ];

    $self->{maps_counters}->{sessions} = [
        { label => 'watcher-sessions', nlabel => 'watcher.sessions.count', set => {
                key_values => [ { name => 'sessions' }, { name => 'watcher_name' }, { name => 'site_name' }, { name => 'gateway_name'} ],
                output_template => 'Sessions: %s',
                closure_custom_perfdata => $self->can('custom_usage_perfdata')
            }
        }        
    ];

    $self->{maps_counters}->{srt_spent} = [
        { label => 'watcher-srt-spent', nlabel => 'watcher.srt.spent.time.milliseconds', set => {
                key_values => [ { name => 'srt_spent' }, { name => 'watcher_name' }, { name => 'site_name' }, { name => 'gateway_name'} ],
                output_template => 'SRT spent: %.2f ms',
                closure_custom_perfdata => $self->can('custom_usage_perfdata_ms')
            }
        }        
    ];

    $self->{maps_counters}->{users} = [
        { label => 'watcher-users', nlabel => 'watcher.users.count', set => {
                key_values => [ { name => 'connected_users' }, { name => 'watcher_name' }, { name => 'site_name' }, { name => 'gateway_name'} ],
                output_template => 'Connected users: %s',
                closure_custom_perfdata => $self->can('custom_usage_perfdata')
            }
        }
    ];

    $self->{maps_counters}->{waiting_time} = [
        { label => 'watcher-waiting-time', nlabel => 'watcher.waiting.time.milliseconds', set => {
                key_values => [ { name => 'waiting_time' }, { name => 'watcher_name' }, { name => 'site_name' }, { name => 'gateway_name'} ],
                output_template => 'Waiting time: %.2f ms',
                closure_custom_perfdata => $self->can('custom_usage_perfdata_ms')
            }
        }   
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'country:s'             => { name => 'country' },
        'isp:s'                 => { name => 'isp' },
        'select-watcher-name:s' => { name => 'watcher_name' },
        'select-site-name:s'    => { name => 'site_name' },
        'select-gateway-name:s' => { name => 'gateway_name' },
        'wfa'                   => { name => 'wfa' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $raw_form_post = {
        "select" => [
            {
                "user_id:distinct" => ["countDistinct","user_id"]
            },
            {
                "\%errors:avg|hits" => ["avgFor","hits","error_count"]            
            },
            {
                "redirect_time_spent:avg|requests" => ["avgFor","requests","redirect_time_spent"]
            },
            {
                "waiting_time_spent:avg|requests" => ["avgFor","requests","waiting_time_spent"]
            },
            {
                "full_network_time_spent:avg|requests" => ["avgFor","requests","full_network_time_spent"]
            },
            {
                "srt_spent:avg|requests" => ["avgFor","requests","srt_spent"]
            },
            {
                "dtt_spent:avg|requests" => ["avgFor","requests","dtt_spent"]
            },
            {
                "session:sum|hits" => ["sumFor","hits","session_count"]
            },
            {
                "item:count|requests" => ["countFor","requests"]
            },
            {
                "item:count|pages" => ["countFor","pages"]
            },
            {
                "lcp:p75|pages" => ["p75For","pages","lcp"]
            },
            {
                "processing_whole:avg|requests" => ["avgFor","requests",["+",["+",["+",["+","full_local_time_spent","full_network_time_spent"],"srt_spent"],"dtt_spent"],"dom_waiting_time_spent"]]
            }
        ],
        "from" => "rum",
        "offset" => 0,
        "options" => {"sampling" => \1 }
    }; 

    if (defined($self->{option_results}->{country})){
        unshift @{$raw_form_post->{select}}, { 'country:group' => "country" };
        unshift @{$raw_form_post->{groupby}}, 'country:group';
    } elsif (defined($self->{option_results}->{isp})) {
        unshift @{$raw_form_post->{select}}, { 'isp:group' => "isp" };
        unshift @{$raw_form_post->{groupby}}, 'isp:group';
    } else {
        push @{$raw_form_post->{select}}, { "watcher_id:group" => "watcher_name" }, { "site:group" => "site_name" }, { "gateway:group" => "gateway_name" };
        push @{$raw_form_post->{groupby}}, "watcher_name", "site:group", "gateway:group" ;
    }

    my $select;
    $select = $options{custom}->forge_select(
        site_name => $self->{option_results}->{site_name},
        gateway_name => $self->{option_results}->{gateway_name},
        watcher_name => $self->{option_results}->{watcher_name},
        wfa => defined($self->{option_results}->{wfa}) ? 'yes' : 'no'
    );

    $raw_form_post->{where} = $select if (defined($select));

    my $results = $options{custom}->request_api(
        method => 'POST',
        endpoint => 'query',
        query_form_post => $raw_form_post
    );

    $self->{watcher} = {};
    $self->{country} = {};
    $self->{isp} = {};
    foreach my $watcher (@{$results->{data}}) {
        last if (!defined($watcher->{'watcher_id:group'}));
        my $instance = $watcher->{'watcher_id:group'};
        $instance .= defined($watcher->{'gateway:group'}) ? $watcher->{'gateway:group'} : "wfa";
        $instance .= defined($watcher->{'site:group'}) ? $watcher->{'site:group'} : "no-site";
        
        $self->{watcher}->{$instance} = {
            site_name => defined($watcher->{'site:group'}) ? $watcher->{'site:group'} : "no-site",
            gateway_name => defined($watcher->{'gateway:group'}) ? $watcher->{'gateway:group'} : "wfa",
            watcher_name => $watcher->{'watcher_id:group'}
        };
        
        $self->{watcher}->{$instance}->{waiting_time} = { 
            watcher_name => $watcher->{'watcher_id:group'},
            waiting_time => ( $watcher->{'waiting_time_spent:avg|requests'} / 10**3 ),
            site_name => defined($watcher->{'site:group'}) ? $watcher->{'site:group'} : "no-site",
            gateway_name => defined($watcher->{'gateway:group'}) ? $watcher->{'gateway:group'} : "wfa",
        };

        $self->{watcher}->{$instance}->{users} = { 
            watcher_name => $watcher->{'watcher_id:group'},
            connected_users => $watcher->{'user_id:distinct'},
            site_name => defined($watcher->{'site:group'}) ? $watcher->{'site:group'} : "no-site",
            gateway_name => defined($watcher->{'gateway:group'}) ? $watcher->{'gateway:group'} : "wfa",
        };

        $self->{watcher}->{$instance}->{errors_prct} = { 
            watcher_name => $watcher->{'watcher_id:group'},
            errors_prct => $watcher->{'%errors:avg|hits'},
            site_name => defined($watcher->{'site:group'}) ? $watcher->{'site:group'} : "no-site",
            gateway_name => defined($watcher->{'gateway:group'}) ? $watcher->{'gateway:group'} : "wfa",
        };

        $self->{watcher}->{$instance}->{dtt_spent} = { 
            watcher_name => $watcher->{'watcher_id:group'},
            dtt_spent => ( $watcher->{'dtt_spent:avg|requests'} / 10**3 ) ,
            site_name => defined($watcher->{'site:group'}) ? $watcher->{'site:group'} : "no-site",
            gateway_name => defined($watcher->{'gateway:group'}) ? $watcher->{'gateway:group'} : "wfa",
        };

        $self->{watcher}->{$instance}->{full_network_time_spent} = { 
            watcher_name => $watcher->{'watcher_id:group'},
            full_network_time_spent => ( $watcher->{'full_network_time_spent:avg|requests'} / 10**3 ),
            site_name => defined($watcher->{'site:group'}) ? $watcher->{'site:group'} : "no-site",
            gateway_name => defined($watcher->{'gateway:group'}) ? $watcher->{'gateway:group'} : "wfa",
        };

        $self->{watcher}->{$instance}->{loading_page} = { 
            watcher_name => $watcher->{'watcher_id:group'},
            loading_page => (defined($watcher->{'lcp:p75|pages'}) && $watcher->{'lcp:p75|pages'} != 0 ) ? ($watcher->{'lcp:p75|pages'} / 10**3) : 0,
            site_name => defined($watcher->{'site:group'}) ? $watcher->{'site:group'} : "no-site",
            gateway_name => defined($watcher->{'gateway:group'}) ? $watcher->{'gateway:group'} : "wfa",
        };

        $self->{watcher}->{$instance}->{pages} = { 
            watcher_name => $watcher->{'watcher_id:group'},
            pages => $watcher->{'item:count|pages'},
            site_name => defined($watcher->{'site:group'}) ? $watcher->{'site:group'} : "no-site",
            gateway_name => defined($watcher->{'gateway:group'}) ? $watcher->{'gateway:group'} : "wfa",
        };

        $self->{watcher}->{$instance}->{processing} = { 
            watcher_name => $watcher->{'watcher_id:group'},
            processing => ( $watcher->{'processing_whole:avg|requests'} / 10**3 ),
            site_name => defined($watcher->{'site:group'}) ? $watcher->{'site:group'} : "no-site",
            gateway_name => defined($watcher->{'gateway:group'}) ? $watcher->{'gateway:group'} : "wfa",
        };

        $self->{watcher}->{$instance}->{redirect_time_avg} = { 
            watcher_name => $watcher->{'watcher_id:group'},
            redirect_time_avg => ( $watcher->{'redirect_time_spent:avg|requests'} / 10**3),
            site_name => defined($watcher->{'site:group'}) ? $watcher->{'site:group'} : "no-site",
            gateway_name => defined($watcher->{'gateway:group'}) ? $watcher->{'gateway:group'} : "wfa",
        };

        $self->{watcher}->{$instance}->{requests} = { 
            watcher_name => $watcher->{'watcher_id:group'},
            requests => $watcher->{'item:count|requests'},
            site_name => defined($watcher->{'site:group'}) ? $watcher->{'site:group'} : "no-site",
            gateway_name => defined($watcher->{'gateway:group'}) ? $watcher->{'gateway:group'} : "wfa",
        };

        $self->{watcher}->{$instance}->{sessions} = { 
            watcher_name => $watcher->{'watcher_id:group'},
            sessions => $watcher->{'session:sum|hits'},
            site_name => defined($watcher->{'site:group'}) ? $watcher->{'site:group'} : "",
            gateway_name => defined($watcher->{'gateway:group'}) ? $watcher->{'gateway:group'} : "wfa",
        };
    
        $self->{watcher}->{$instance}->{srt_spent} = { 
            watcher_name => $watcher->{'watcher_id:group'},
            srt_spent => ( $watcher->{'srt_spent:avg|requests'} / 10**3 ),
            site_name => defined($watcher->{'site:group'}) ? $watcher->{'site:group'} : "no-site",
            gateway_name => defined($watcher->{'gateway:group'}) ? $watcher->{'gateway:group'} : "wfa",
        };
    };

    foreach my $country (@{$results->{data}}) {
        last if (!defined($country->{'country:group'}));
        next if (defined($country->{'country:group'}) && $country->{'country:group'} !~ /$self->{option_results}->{country}/i);
        my $instance = $country->{'country:group'};

        $self->{country}->{$instance} = {
            dtt_spent => ( $country->{'dtt_spent:avg|requests'} / 10**3 ),
            errors_prct => $country->{'%errors:avg|hits'},
            full_time_network_spent => ( $country->{'full_network_time_spent:avg|requests'} / 10**3 ),
            loading_page => (defined($country->{'lcp:p75|pages'}) && $country->{'lcp:p75|pages'} != 0 ) ? ($country->{'lcp:p75|pages'} / 10**3) : 0,
            pages => $country->{'item:count|pages'},
            processing => ( $country->{'processing_whole:avg|requests'} / 10**3 ),
            requests => $country->{'item:count|requests'},
            redirect_time_avg => ( $country->{'redirect_time_spent:avg|requests'} / 10**3),
            srt_spent => ( $country->{'srt_spent:avg|requests'} / 10**3 ),
            sessions => $country->{'session:sum|hits'},
            users => $country->{'user_id:distinct'},
            waiting_time_avg => ( $country->{'waiting_time_spent:avg|requests'} / 10**3 ) 
        };
    }

    foreach my $isp (@{$results->{data}}) {
        last if (!defined($isp->{'isp:group'}));
        next if (defined($isp->{'isp:group'}) && $isp->{'isp:group'} !~ /$self->{option_results}->{isp}/i);
        my $instance = $isp->{'isp:group'};

        $self->{isp}->{$instance} = {
            dtt_spent => ( $isp->{'dtt_spent:avg|requests'} / 10**3 ),
            errors_prct => $isp->{'%errors:avg|hits'},
            full_time_network_spent => ( $isp->{'full_network_time_spent:avg|requests'} / 10**3 ),
            loading_page => (defined($isp->{'lcp:p75|pages'}) && $isp->{'lcp:p75|pages'} != 0 ) ? ($isp->{'lcp:p75|pages'} / 10**3) : 0,
            pages => $isp->{'item:count|pages'},
            processing => ( $isp->{'processing_whole:avg|requests'} / 10**3 ),
            requests => $isp->{'item:count|requests'},
            redirect_time_avg => ( $isp->{'redirect_time_spent:avg|requests'} / 10**3),
            srt_spent => ( $isp->{'srt_spent:avg|requests'} / 10**3 ),
            sessions => $isp->{'session:sum|hits'},
            users => $isp->{'user_id:distinct'},
            waiting_time_avg => ( $isp->{'waiting_time_spent:avg|requests'} / 10**3 ) 
        };
    }

    if (scalar(keys %{$self->{watcher}}) <= 0 && scalar(keys %{$self->{country}}) <= 0 && scalar(keys %{$self->{isp}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No instances or results found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Kadiska application watchers statistics during the period specified.

=over 8

=item B<--select-site-name>

Display statistics for watchers on a particular site.

Leave empty to get work-from-home watchers statistics: --select-site-name="" --select-watcher-name="GitHub"

=item B<--select-gateway-name>

Display statistics for watchers attached to a particular gateway.

=item B<--select-watcher-name>

Display statistics for a particular watcher.

=item B<--country>

Display statistics per country. 

Leave empty to get statistics from all countries, or specify particular country.

=item B<--isp>

Display statistics per ISP.

Leave empty to get statistics from all ISP, or specify particular ISP.

=item B<--wfa>

Display statistics for watchers used by work-from-anywhere users.

=item B<--warning-[country|isp|watcher]-*> B<--critical-[country|isp|watcher]-*> 

Thresholds. Can be:
'dtt-spent', 'errors-prct', 'full-network-time-spent',
'sessions', 'srt-spent', 'requests', 'redirect-time-avg',
'loading-page', 'pages', 'processing', 'users', 'waiting-time-avg'.

=back

=cut
