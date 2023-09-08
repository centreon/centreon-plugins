#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package apps::monitoring::kadiska::mode::alerts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_global_output {
    my ($self, %options) = @_;
    return 'Rules: ';
}

sub prefix_rules_output {
    my ($self, %options) = @_;
    return sprintf('Rule id: "%s", Rule name: "%s" ',
        $options{instance_value}->{id},
        $options{instance_value}->{name});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output'},
        { name => 'rules', type => 1, cb_prefix_output => 'prefix_rules_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'rules-total-count', nlabel => 'rules.total.count', set => {
                key_values => [ { name => 'total' }  ],
                output_template => 'total rules: %s',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        },
        { label => 'rules-criticals-total-count', nlabel => 'rules.criticals.count', set => {
                key_values => [ { name => 'total_critical' }  ],
                output_template => 'total criticals: %s',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        },
        { label => 'rules-warnings-total-count', nlabel => 'rules.warnings.count', set => {
                key_values => [ { name => 'total_warning' }  ],
                output_template => 'total warnings: %s',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        },
        { label => 'rules-nodata-total-count', nlabel => 'rules.nodata.count', set => {
                key_values => [ { name => 'total_nodata' }  ],
                output_template => 'total no data: %s',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{rules} = [
        { label => 'rule-ok-count', nlabel => 'rule.ok.count', set => {
                key_values => [ { name => 'ok_count' } ],
                output_template => 'ok count: %s',
                display_ok => 0,
                perfdatas => [ {template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' } ]
            }
        },
        { label => 'rule-warning-count', nlabel => 'rule.warning.count', set => {
                key_values => [ { name => 'warning_count' } ],
                output_template => 'warning count: %s',
                display_ok => 0,
                perfdatas => [ {template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' } ]
            }
        },
        { label => 'rule-critical-count', nlabel => 'rule.critical.count', set => {
                key_values => [ { name => 'critical_count' } ],
                output_template => 'critical count: %s',
                display_ok => 0,
                perfdatas => [ {template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' } ]
            }
        },
        { label => 'rule-nodata-count', nlabel => 'rule.nodata.count', set => {
                key_values => [ { name => 'nodata_count' } ],
                output_template => 'no data count: %s',
                display_ok => 0,
                perfdatas => [ {template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' } ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $raw_form_post = {
        "select" => [
            {
                "rule_id:group" => "rule_id"
            },
            {
                "rule_name:any" => ["any","rule_name"]
            },
            {
                ["any","rule_name"] => ["any","rule_id"]
            },
            {
                "critical:count" => ["sum","critical_count"]
            },
            {
                "warning:count" => ["sum","warning_count"]
            },
            {
                "ok:count" => ["sum","ok_count"]
            },
            {
                "nodata:count" => ["sum","nodata_count"]
            }
        ],
        "from" => "alert",
        "groupby" => [
            "rule_id:group"
        ],
        "orderby" => [
            ["rule_name:any","desc"]
        ],
        "offset" => 0,
        "limit" => 61
    };

    my $results = $options{custom}->request_api(
        method => 'POST',
        endpoint => 'query',
        query_form_post => $raw_form_post
    );

    #Check if bad API request is submit
    if (!exists $results->{data}) {
        $self->{output}->add_option_msg(short_msg => 'No data result in API request.');
        $self->{output}->option_exit();
    }

    $self->{global} = { total_critical => 0, total_warning => 0, total_nodata => 0 };

    foreach (@{$results->{data}}) {
        my $rule = $_;

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
             $rule->{'rule_name:any'} !~ /$self->{option_results}->{filter_name}/);

        $self->{rules}->{$rule->{'rule_id:group'}} = {
            id             => $rule->{'rule_id:group'},
            name           => $rule->{'rule_name:any'},
            ok_count       => $rule->{'ok:count'},
            warning_count  => $rule->{'warning:count'},
            critical_count => $rule->{'critical:count'},
            nodata_count   => $rule->{'nodata:count'}
        };
        $self->{global}->{total_critical}+=$rule->{'critical:count'};
        $self->{global}->{total_warning}+=$rule->{'warning:count'};
        $self->{global}->{total_nodata}+=$rule->{'nodata:count'};
    }
    $self->{global}->{total} = scalar (keys %{$self->{rules}});

    if (scalar(keys %{$self->{rules}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No rule found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Kadiska rules alerts status.

=over 8

=item B<--filter-name>

Only get rules by name (can be a regexp).

=back

=cut
