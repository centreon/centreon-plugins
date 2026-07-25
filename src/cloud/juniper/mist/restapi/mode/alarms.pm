#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package cloud::juniper::mist::restapi::mode::alarms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL },
        { name => 'types', type => COUNTER_TYPE_INSTANCE, prefix_output => "Alarm type '%{type}' ",
          message_multiple => 'All alarm types are OK', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'alarms-critical', nlabel => 'mist.alarms.critical.count',
            set => {
                key_values => [ { name => 'critical' } ],
                output_template => 'critical: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        {
            label => 'alarms-warning', nlabel => 'mist.alarms.warning.count',
            set => {
                key_values => [ { name => 'warning' } ],
                output_template => 'warning: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        {
            label => 'alarms-info', nlabel => 'mist.alarms.info.count', threshold => 0,
            set => {
                key_values => [ { name => 'info' } ],
                output_template => 'info: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{types} = [
        {
            label => 'status',
            type => COUNTER_KIND_TEXT,
            # Evaluated once per alarm type (catalog_status_threshold_ng runs per
            # instance), so a negative-match rule silences only the type it names
            # and never neutralises the alert for the other types:
            #   --critical-status='%{critical} > 0 && %{type} !~ /some_type/'
            # Silenced types stay counted in the perfdata.
            critical_default => '%{critical} > 0',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'critical' }, { name => 'warning' }, { name => 'info' },
                    { name => 'count' }, { name => 'total' }, { name => 'type' }
                ],
                output_template => 'critical: %{critical}, warning: %{warning}, info: %{info}',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'alarm-count', nlabel => 'mist.alarms.count', threshold => 0,
            set => {
                key_values => [ { name => 'count' }, { name => 'type' } ],
                output_template => 'count: %d',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'type' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'site-id:s'            => { name => 'site_id' },
        'timeframe:s'          => { name => 'timeframe', type => 'numeric', default => 3600 },
        'filter-alarm-type:s'  => { name => 'filter_alarm_type' },
        'exclude-alarm-type:s' => { name => 'exclude_alarm_type' }
    });

    return $self;
}

# /alarms/search honours site_id server-side, so the filter is passed straight
# through. It is a search endpoint: results are wrapped in a 'results' key and
# paginated through a 'search_after' cursor (handled by request_api_search).
sub manage_selection {
    my ($self, %options) = @_;

    my $org_id = $options{custom}->get_org_id();
    my $timeframe = $self->{option_results}->{timeframe};

    my @get_param = ('duration=' . $timeframe . 's');
    push @get_param, 'site_id=' . $self->{option_results}->{site_id}
        if (defined($self->{option_results}->{site_id}) && $self->{option_results}->{site_id} ne '');

    my ($alarms, $truncated) = $options{custom}->request_api_search(
        endpoint => "/api/v1/orgs/$org_id/alarms/search",
        get_param => \@get_param
    );

    my ($critical, $warning, $info) = (0, 0, 0);
    my %by_type;

    foreach my $alarm (@$alarms) {
        my $type = $alarm->{type} // 'unknown';

        next if (defined($self->{option_results}->{filter_alarm_type}) && $self->{option_results}->{filter_alarm_type} ne ''
            && $type !~ /$self->{option_results}->{filter_alarm_type}/i);
        next if (defined($self->{option_results}->{exclude_alarm_type}) && $self->{option_results}->{exclude_alarm_type} ne ''
            && $type =~ /$self->{option_results}->{exclude_alarm_type}/i);

        my $severity = lc($alarm->{severity} // 'info');
        $severity = 'info' if ($severity !~ /^(?:critical|warning|info)$/);

        if ($severity eq 'critical') { $critical++; }
        elsif ($severity eq 'warning') { $warning++; }
        else { $info++; }

        $by_type{$type}->{$severity}++;
        $by_type{$type}->{count}++;
    }

    my $total = $critical + $warning + $info;

    $self->{global} = { critical => $critical, warning => $warning, info => $info };

    $self->{types} = {};
    foreach my $type (keys %by_type) {
        $self->{types}->{$type} = {
            type => $type,
            critical => $by_type{$type}->{critical} // 0,
            warning => $by_type{$type}->{warning} // 0,
            info => $by_type{$type}->{info} // 0,
            count => $by_type{$type}->{count},
            total => $total
        };
    }

    # A truncated result means the max-pages safety bound was hit: surface it so
    # the operator knows the counts are a lower bound, not the full window.
    $self->{output}->output_add(long_msg => 'Note: result truncated (--max-pages reached), counts are a lower bound.')
        if ($truncated);
}

1;

__END__

=head1 MODE

Check the Juniper Mist alarms over a time window from the C</alarms/search>
endpoint, broken down by severity and by alarm type.

By default, any critical alarm raises a CRITICAL. A given alarm type can be
silenced with a negative-match C<--critical-status> rule while remaining counted
in the perfdata.

=over 8

=item B<--site-id>

Restrict the check to a single site (honoured server-side by the Mist API).

=item B<--timeframe>

Time window in seconds to look back for alarms (default: 3600).

=item B<--filter-alarm-type>

Only keep alarms whose type matches this regular expression.

=item B<--exclude-alarm-type>

Exclude alarms whose type matches this regular expression.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (per alarm type).
You can use the following variables: %{critical}, %{warning}, %{info},
%{count}, %{total}, %{type}.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (per alarm type)
(default: '%{critical} > 0').

Example - silence a noisy alarm type while still alerting on the rest:
--critical-status='%{critical} > 0 && %{type} !~ /infra_arp_poison/'

=item B<--warning-alarms-critical> B<--critical-alarms-critical>

Threshold on the total number of critical alarms (no default).

=item B<--warning-alarms-warning> B<--critical-alarms-warning>

Threshold on the total number of warning alarms (no default).

=back

=cut
