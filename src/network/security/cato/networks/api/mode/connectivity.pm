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

package network::security::cato::networks::api::mode::connectivity;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

use centreon::plugins::misc qw(change_seconds);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use DateTime::Format::Strptime;
use POSIX qw(strftime);
use network::security::cato::networks::api::misc qw/mk_timeframe/;

# All available performance metrics
# Full list: https://api.catonetworks.com/documentation/#definition-TimeseriesKey
my @performance_metrics = ( { metric => 'bytesUpstreamMax',
                              label => 'upstream-max',
                              nlabel => 'connectivity.upstream.max.bytes',
                              unit => 'B'
                            },
                            { metric => 'bytesDownstreamMax',
                              label => 'downstream-max',
                              nlabel => 'connectivity.upstream.max.bytes',
                              unit => 'B'
                            },
                            { metric => 'lostUpstreamPcnt',
                              label => 'lost-upstream',
                              nlabel => 'connectivity.upstream.lost.percentage',
                              unit => '%'
                            },
                            { metric => 'lostDownstreamPcnt',
                              label => 'lost-downstream',
                              nlabel => 'connectivity.downstream.lost.percentage',
                              unit => '%'
                            },
                            { metric => 'packetsDiscardedDownstream',
                              label => 'discarded-downstream',
                              nlabel => 'connectivity.downstream.discarded.count',
                              unit => ''
                            },
                            { metric => 'packetsDiscardedUpstream',
                              label => 'discarded-upstream',
                              nlabel => 'connectivity.upstream.discarded.count',
                              unit => ''
                            },
                            { metric => 'jitterUpstream',
                              label => 'jitter-upstream',
                              nlabel => 'connectivity.upstream.jitter.ms',
                              unit => 'ms'
                            },
                            { metric => 'jitterDownstream',
                              label => 'jitter-downstream',
                              nlabel => 'connectivity.downstream.jitter.ms',
                              unit => 'ms'
                            },
                            { metric => 'lastMilePacketLoss',
                              label => 'lastmile-packetloss',
                              nlabel => 'connectivity.lastmile.packetloss.count',
                              unit => ''
                            },
                            { metric => 'lastMileLatency',
                              label => 'lastmile-latency',
                              nlabel => 'connectivity.lastmile.latency.ms',
                              unit => 'ms'
                            }
                        );

sub custom_performance_output {
    my ($self, %options) = @_;

    return "Bucket '".$options{instance_value}->{bucket}."' ";
}

sub custom_connected_since_output {
    my ($self, %options) = @_;

    $self->{output}->add_option_msg(long_msg =>  "Connected since: ".change_seconds(value => $self->{result_values}->{connected_since})." (".$self->{result_values}->{connected_since_date}.")");

    return "connected since: $self->{'result_values'}->{connected_since}s";
}

sub custom_last_connected_output {
    my ($self, %options) = @_;

    $self->{output}->add_option_msg(long_msg =>  "Last connected: ".change_seconds(value => $self->{result_values}->{last_connected})." ago (".$self->{result_values}->{last_connected_date}.")");

    return "last connected: $self->{'result_values'}->{last_connected}s ago";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
            { name => 'global', type => 0, skipped_code => { -10 => 1 } },
            { name=> 'performance', type => 1, cb_prefix_output => 'custom_performance_output', message_multiple => 'All performances checks are ok', skipped_code => { -10 => 1 } }
    ];

    my $values = [ { name => 'connectivity' }, { name => 'operational' }, { name => 'last_connected' }, { name => 'connected_since' }, { name => 'pop_name' } ];

    # "global" counter is related to connectivity status
    $self->{maps_counters}->{global} = [
        { label => 'connectivity-status', type => 2, critical_default => '%{connectivity} !~ /Connected/', set => {
                key_values => $values, output_use => 'connectivity',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            },
        },
        { label => 'operational-status', type => 2, critical_default => '%{operational} !~ /active|new/', set => {
                key_values => $values, output_use => 'operational',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            },
        },
        { label => 'pop-name', type => 2, set => {
                key_values => $values, output_use => 'pop_name',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            },
        },
        { label => 'connected-since', nlabel => 'connected.since.seconds', display_ok => $self->{output}->is_verbose(),
            set => {
                closure_custom_output => $self->can('custom_connected_since_output'),
                key_values => [ { name => 'connected_since' }, { name => 'connected_since_date' } ],
                threshold_use => 'connected_since',
                perfdatas => [ { template => '%d', min => 0, unit => 's' } ]
            },
        },
        { label => 'last-connected', nlabel => 'connected.last.seconds', display_ok => $self->{output}->is_verbose(),
            set => {
                closure_custom_output => $self->can('custom_last_connected_output'),
                key_values => [ { name => 'last_connected' }, { name => 'last_connected_date' } ],
                threshold_use => 'last_connected',
                perfdatas => [ { template => '%d', min => 0, unit => 's' } ]
            },
        },
    ];

    # "performance" counter is related to performance metrics
    $self->{maps_counters}->{performance} = [
        map {
            {   label => $_->{label},
                nlabel => $_->{nlabel},
                set => {
                    key_values => [ { name => $_->{metric} }, { name => 'bucket' } ],
                    perfdatas => [ { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'bucket', unit => $_->{unit} } ]
                }
            }
        } @performance_metrics ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
            "site-id:s"              => { name => 'site_id' },
            "performance-metrics:s@" => { name => 'performance_metrics' },
            "buckets:s"              => { name => 'buckets', default => '5' },
            "timeframe:s"            => { name => 'timeframe', default => '5' },
            "timeframe-unit:s"       => { name => 'timeframe_unit', default => 'm' },
            "timeframe-query:s"      => { name => 'timeframe_query', default => '' },
    });

    return $self;
}


sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    foreach my $opt (qw/site_id buckets/) {
        $self->{$opt} = $self->{option_results}->{$opt} // '';
        next if $self->{$opt} =~ /^\d+$/;

        $self->{output}->option_exit(short_msg => "Need to specify a numeric --".($opt=~s/_/-/gr)." option.");
    }

    # Define timeframe to query performance metrics
    $self->{timeframe} = $self->{option_results}->{timeframe_query};
    if ($self->{timeframe} eq '') {
        $self->{timeframe} = $self->{option_results}->{timeframe};
        $self->{output}->option_exit(short_msg => "Need to specify a numeric --timeframe option.")
            unless $self->{timeframe} =~ /^\d+$/;
        $self->{timeframe_unit} = $self->{option_results}->{timeframe_unit};
        $self->{output}->option_exit(short_msg => "Invalid timeframe-unit unit value (m, h, D, M, Y).")
            unless $self->{timeframe_unit} =~ /^[mhDMY]$/;

        $self->{timeframe} = mk_timeframe($self->{timeframe}, $self->{timeframe_unit});
    }

    # Select the desired performance metrics with --performance-metrics option and define them in performance_metrics_enabled hash
    # This option can be used multiple times and can contain comma separated lists
    # Allowed special values: all, none
    # Other allowed values care SiteMetrics from cato API, or plugins labels and nlabels
    # 'all' is the default value, meaning all metrics are collected
    # 'none' means that no AccountMetrics calls are made and therefore no performances metrics are collected
    $self->{performance_metrics_enabled} = {};

    $self->{option_results}->{performance_metrics} = [ 'all' ] unless ref $self->{option_results}->{performance_metrics} eq 'ARRAY';

    foreach my $metric (map { split ',', lc } @{$self->{option_results}->{performance_metrics}}) {
        $metric = lc $metric;
        if ($metric eq 'all') {
            $self->{performance_metrics_enabled}->{$_->{metric}} = 1 foreach @performance_metrics;
        } elsif ($metric eq 'none' || $metric eq '') {
            $self->{performance_metrics_enabled} = {};
        } else {
            my ($found) = grep { $metric eq lc $_->{metric} ||
                                 $metric eq lc $_->{label} ||
                                 $metric eq lc $_->{nlabel} ?
                                    $_->{metric} :
                                    ''
                               } @performance_metrics;

            $self->{output}->option_exit(short_msg => "Wrong performance metric '" . $metric . "'.")
                unless $found;
            $self->{performance_metrics_enabled}->{$metric} = 1;
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->check_connectivity(site_id => $self->{site_id},
                                                       buckets => $self->{buckets},
                                                       timeframe => $self->{timeframe},
                                                       performance_metrics => $self->{performance_metrics_enabled});
    $self->{output}->option_exit(short_msg => "Cannot retrieve connectivity status for site '" . $self->{site_id} . "'.")
        unless exists $results->{name};

    my ($last_connected_seconds, $connected_since_seconds) = (0,0);
    my $strp = DateTime::Format::Strptime->new( pattern => "%Y-%m-%dT%H:%M:%SZ" );

    # Convert date fields to timestamp to manage them as thresholds
    $last_connected_seconds = $strp->parse_datetime($results->{last_connected}) // 0;
    $last_connected_seconds = time - $last_connected_seconds->epoch if $last_connected_seconds;
    $last_connected_seconds = 0 if $last_connected_seconds < 0;

    $connected_since_seconds = $strp->parse_datetime($results->{connected_since}) // 0;
    $connected_since_seconds = time - $connected_since_seconds->epoch if $connected_since_seconds;
    $connected_since_seconds = 0 if $connected_since_seconds < 0;

    $self->{global} = { display => $results->{name},
                        connectivity => $results->{connectivity_status},
                        operational => $results->{operational_status},
                        last_connected_date => $results->{last_connected},
                        connected_since_date => $results->{connected_since},
                        last_connected => $last_connected_seconds,
                        connected_since => $connected_since_seconds,
                        pop_name => $results->{pop_name}
                      };

    $self->{performance} = {};
    if ($results->{performance}) {
        while (my ($metric, $values) = each %{$results->{performance}}) {
            foreach my $entry (@{$values}) {
                $self->{performance}->{$entry->{timestamp}}->{$metric} = $entry->{value};
            }
        }
        while (my ($timestamp, $values) = each %{$self->{performance}}) {
            # format bucket timestamp to human readable format
            $values->{bucket} = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime($timestamp/1000));
        }
    }
}

1;

__END__

=head1 MODE

Check sites connectivity and performance.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='connected'

=item B<--site-id>

Site ID to run query on (required).

=back

=head2 Buckets and timeframe handling for performance metrics

The timeframe defines the period over which the performance metrics are aggregated.
The parameters B<timeframe> and B<timeframe-unit> allow retrieving data from a specific
interval while B<timeframe-query> allows to defining a more complex time interval.
B<timeframe> is ignored if timeframe-query is set.

=over 8

=item B<--timeframe>

Numeric timeframe to use (default: 5).
Meaning that data from the last 5 minutes will be retrieved.

=item B<--timeframe-unit>

Unit to use with B<timeframe> option (m: minutes, h: hours, D: days, M: months, Y: years) (default: m).

=item B<--timeframe-query>

Timeframe query to use (example: C<utc.2025-09-11/{14:00:00--14:30:00}>).
Refer to Cato API documentation for more information about supported formats.

=item B<--buckets>

Defines the number of buckets for the query's time interval.
For example: a 10 minutes interval with 5 buckets results in 2 minute per bucket (default: 5).

=back

=head2 Performance metrics

=over 8

=item B<--performance-metrics>

Specify the performance metrics to query (comma separated list) (default: 'all').
You can use this option multiple times.
Supported values are: C<all>, C<none>, C<bytesUpstreamMax>, C<bytesDownstreamMax>,
C<lostUpstreamPcnt>, C<lostDownstreamPcnt>, C<packetsDiscardedDownstream>,
C<packetsDiscardedUpstream>, C<jitterUpstream>, C<jitterDownstream>, C<lastMilePacketLoss>,
C<lastMileLatency>.
C<all> means that all metrics are collected whereas C<none> means none are collected.
Refer to Cato API documentation https://api.catonetworks.com/documentation/#definition-TimeseriesKey
for more information about supported metrics.

=item B<--warning-discarded-downstream>

Threshold.

=item B<--critical-discarded-downstream>

Threshold.

=item B<--warning-discarded-upstream>

Threshold.

=item B<--critical-discarded-upstream>

Threshold.

=item B<--warning-downstream-max>

Threshold in bytes.

=item B<--critical-downstream-max>

Threshold in bytes.

=item B<--warning-jitter-downstream>

Threshold in milliseconds.

=item B<--critical-jitter-downstream>

Threshold in milliseconds.

=item B<--warning-jitter-upstream>

Threshold in milliseconds.

=item B<--critical-jitter-upstream>

Threshold in milliseconds.

=item B<--warning-lastmile-latency>

Threshold in milliseconds.

=item B<--critical-lastmile-latency>

Threshold in milliseconds.

=item B<--warning-lastmile-packetloss>

Threshold.

=item B<--critical-lastmile-packetloss>

Threshold.

=item B<--warning-lost-downstream>

Threshold in percentage.

=item B<--critical-lost-downstream>

Threshold in percentage.

=item B<--warning-lost-upstream>

Threshold in percentage.

=item B<--critical-lost-upstream>

Threshold in percentage.

=item B<--warning-upstream-max>

Threshold in bytes.

=item B<--critical-upstream-max>

Threshold in bytes.

=back

=head2 Connectivity status

=over 8

=item B<--warning-connectivity-status>

Define the connectivity status conditions to match for the status to be WARNING.
Example: --warning-connectivity-status='%{connectivity} =~ /Degraded/'

=item B<--critical-connectivity-status>

Define the connectivity status conditions to match for the status to be CRITICAL.
Default: --critical-connectivity-status='%{connectivity} !~ /Connected/'

=item B<--warning-operational-status>

Define the operational status conditions to match for the status to be WARNING.
Example: --warning-operational-status='%{operational} !~ /active/'

=item B<--critical-operational-status>

Define the operational status conditions to match for the status to be CRITICAL.
Default: --critical-operational-status='%{operational} !~ /active|new/'

=item B<--warning-pop-name>

Define the pop name conditions to match for the status to be WARNING.
Example: --warning-pop-name='%{pop_name} !~ /Toulouse/'

=item B<--critical-pop-name>

Define the pop name conditions to match for the status to be CRITICAL.
Example: --critical-pop-name='%{pop_name} !~ /Toulouse/'

=item B<--warning-last-connected>

Threshold in seconds.

=item B<--critical-last-connected>

Threshold in seconds.

=item B<--warning-connected-since>

Threshold in seconds.

=item B<--critical-connected-since>

Threshold in seconds.

=back

=cut
