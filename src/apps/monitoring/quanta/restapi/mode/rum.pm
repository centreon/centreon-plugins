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

package apps::monitoring::quanta::restapi::mode::rum;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'rum', type => 1, message_multiple => 'All RUM counters are OK', cb_prefix_output => 'prefix_output', skipped_code => { -10 => 1 } }
    ];


    $self->{maps_counters}->{rum} = [
        { label => 'sessions', nlabel => 'sessions.count', set => {
                key_values => [ { name => 'sessions' }, { name => 'display' } ],
                output_template => 'sessions: %.d',
                perfdatas => [
                    { value => 'sessions', template => '%.d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'page-views', nlabel => 'pageviews.count', set => {
                key_values => [ { name => 'page_views' }, { name => 'display' } ],
                output_template => 'page views: %.d',
                perfdatas => [
                    { value => 'page_views', template => '%.d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'bounce-rate', nlabel => 'bounce.rate.percentage', set => {
                key_values => [ { name => 'bounces' }, { name => 'display' } ],
                output_template => 'bounce rate: %.d%%',
                perfdatas => [
                    { value => 'bounces', template => '%.d',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'ttfb', nlabel => 'ttfb.milliseconds', set => {
                key_values => [ { name => 'backend_time' }, { name => 'display' } ],
                output_template => 'ttfb: %.3fms',
                perfdatas => [
                    { value => 'backend_time', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'onload', nlabel => 'onload.time.milliseconds', set => {
                key_values => [ { name => 'frontend_time' }, { name => 'display' } ],
                output_template => 'onload time: %.2fms',
                perfdatas => [
                    { value => 'frontend_time', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'interaction-next-paint', nlabel => 'nextpaint.interaction.time.milliseconds', set => {
                key_values => [ { name => 'interaction_to_next_paint' }, { name => 'display' } ],
                output_template => 'interaction to next paint: %.2fms',
                perfdatas => [
                    { value => 'interaction_to_next_paint', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'speed-index', nlabel => 'speedindex.time.milliseconds', set => {
                key_values => [ { name => 'speed_index' }, { name => 'display' } ],
                output_template => 'speed index: %.2fms',
                perfdatas => [
                    { value => 'speed_index', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return $self->{perspective} . ' ' . $options{instance_value}->{display} . ': ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "limit-results:s" => { name => 'limit_results' },
        "perspective:s"   => { name => 'perspective' },
        "site-id:s"       => { name => 'site_id' },
        "timeframe:s"     => { name => 'timeframe' }
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{limit_results} = (defined($self->{option_results}->{limit_results})) ? $self->{option_results}->{limit_results} : '10';
    $self->{perspective} = (defined($self->{option_results}->{perspective})) ? $self->{option_results}->{perspective} : 'all';
    $self->{site_id} = (defined($self->{option_results}->{site_id})) ? $self->{option_results}->{site_id} : '';
    $self->{timeframe} = (defined($self->{option_results}->{timeframe})) ? $self->{option_results}->{timeframe} : '1800';

    if (!defined($self->{site_id}) || $self->{site_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --site-id option.");
        $self->{output}->option_exit();
    }

    if (defined($self->{perspective}) && lc($self->{perspective}) !~ m/all|url|browser|country|city|os/) {
        $self->{output}->add_option_msg(short_msg => 'Unknown perspective set in "--perspective" option.');
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    my $rum_metrics = [
        { name => 'sessions' },
        { name => 'page_views' },
        { name => 'bounces' },
        { name => 'speed_index', is_time => 1 },
        { name => 'frontend_time', is_time => 1 },
        { name => 'backend_time', is_time => 1 },
        { name => 'interaction_to_next_paint', is_time => 1 }
    ];
    my $rum_payload;
    my $rum_aggregations = [ 'mean' ];
    $rum_payload->{namespace} = 'rum';
    $rum_payload->{index} = $self->{perspective};
    # numifying is required with rum API for INT types
    $rum_payload->{tenant_id} = int $self->{site_id};
    $rum_payload->{limit} = int $self->{limit_results};
    $rum_payload->{point_period} = int $self->{timeframe};
    $rum_payload->{range} = int $self->{timeframe};
    foreach my $metric (@$rum_metrics) {
        foreach (@$rum_aggregations) {
            push @{$rum_payload->{metrics_filter}->{$metric->{name}}->{aggregations}}, $_;
        }
    }

    my $results = $options{custom}->get_data_export_api(data => $rum_payload, is_rum => 1);

    foreach my $metric (@$rum_metrics) {
        my $dimension = $self->{perspective};
        foreach my $result (@{$results->{results}}) {
            if (scalar(keys %{$result->{dimensions}}) > 0) {
                foreach (sort keys %{$result->{dimensions}}) {
                    $dimension = $result->{dimensions}->{$_} if $result->{dimensions}->{$_};
                }
            } 
            $self->{rum}->{$dimension}->{display} = $dimension ne 'all' ? $dimension : 'pages';
            if (defined($metric->{is_time})) {
                $self->{rum}->{$dimension}->{$metric->{name}} = $result->{total}->{$metric->{name}}->{mean};
            } else {
                $self->{rum}->{$dimension}->{$metric->{name}} = $result->{total}->{$metric->{name}}->{count} if (defined($result->{total}->{$metric->{name}}->{count}));
            }
        }
    }
}

1;

__END__

=head1 MODE

Check Quanta by Centreon RUM metrics for a given site.

=over 8

=item B<--site-id>

Set ID of the site (mandatory option).

=item B<--timeframe>

Set timeframe in seconds (default: 1800).

=item B<--perspective>

Set the perspective in which the data will be applied.
Can be: 'all', 'url', 'browser', 'country', 'city', 'os' (default: 'all').

=item B<--limit-results>

To be used with --perspective. Limit the number of results to be fetched (number of different URLs, browsers, etc...).
(default: 10).

=item B<--warning-sessions>

Warning threshold for sessions.

=item B<--critical-sessions>

Critical threshold for sessions.

=item B<--warning-page-views>

Warning threshold for page views.

=item B<--critical-page-views>

Critical threshold for page views.

=item B<--warning-bounce-rate>

Warning threshold for bounce rate.

=item B<--critical-bounce-rate>

Critical threshold for bounce rate.

=item B<--warning-ttfb>

Warning threshold for time to first byte (in ms).

=item B<--critical-ttfb>

Critical threshold for time to first byte (in ms).

=item B<--warning-onload>

Warning threshold for C<onload> time (in ms).

=item B<--critical-onload>

Critical threshold for C<onload> time (in ms).

=item B<--warning-interaction-next-paint>

Warning threshold for time to interaction next paint (in ms).

=item B<--critical-interaction-next-paint>

Critical threshold for time to interaction next paint (in ms).

=item B<--warning-speed-index>

Warning threshold for speed index.

=item B<--critical-speed-index>

Critical threshold for speed index.

=back

=cut
