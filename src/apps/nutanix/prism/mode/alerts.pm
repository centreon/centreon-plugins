#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package apps::nutanix::prism::mode::alerts;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use POSIX qw(floor);

# Nutanix Prism v2.0 API severity values and their Centreon equivalents
my %SEVERITY_MAP = (
    kCritical => 'critical',
    kWarning  => 'warning',
    kInfo     => 'info',
);

sub custom_alert_output {
    my ($self, %options) = @_;

    my $age_s    = $self->{result_values}->{age_seconds};
    my $days     = floor($age_s / 86400);
    my $hours    = floor(($age_s % 86400) / 3600);
    my $mins     = floor(($age_s % 3600) / 60);
    my $age_str  = '';
    $age_str    .= "${days}d " if $days > 0;
    $age_str    .= "${hours}h " if $hours > 0;
    $age_str    .= "${mins}m"   if $mins  > 0 || ($days == 0 && $hours == 0);
    $age_str     = '< 1m' if $age_str eq '';

    return sprintf(
        "alert [severity: %s] [title: %s] [entity: %s] raised %s ago",
        $self->{result_values}->{severity},
        $self->{result_values}->{title},
        $self->{result_values}->{entity},
        $age_str,
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        # Global counters: alert count per severity
        { name => 'global', type => 0 },
        # Per-alert counters: individual status for long output
        {
            name             => 'alerts',
            type             => 1,
            cb_prefix_output => 'prefix_alert_output',
            message_multiple => 'No active alerts',
            skipped_code     => { -10 => 1 },
        },
    ];

    $self->{maps_counters}->{global} = [
        {
            label  => 'alerts-critical',
            nlabel => 'alerts.severity.critical.count',
            set    => {
                key_values      => [ { name => 'critical' } ],
                output_template => 'critical alerts: %d',
                perfdatas       => [ { template => '%d', min => 0 } ],
            }
        },
        {
            label  => 'alerts-warning',
            nlabel => 'alerts.severity.warning.count',
            set    => {
                key_values      => [ { name => 'warning' } ],
                output_template => 'warning alerts: %d',
                perfdatas       => [ { template => '%d', min => 0 } ],
            }
        },
        {
            label  => 'alerts-info',
            nlabel => 'alerts.severity.info.count',
            set    => {
                key_values      => [ { name => 'info' } ],
                output_template => 'info alerts: %d',
                perfdatas       => [ { template => '%d', min => 0 } ],
            }
        },
        {
            label  => 'alerts-total',
            nlabel => 'alerts.total.count',
            set    => {
                key_values      => [ { name => 'total' } ],
                output_template => 'total alerts: %d',
                perfdatas       => [ { template => '%d', min => 0 } ],
            }
        },
    ];

    $self->{maps_counters}->{alerts} = [
        {
            label  => 'alert-status',
            type   => 2,
            # Default: each critical alert triggers CRITICAL, warning triggers WARNING
            warning_default  => '%{severity} eq "warning"',
            critical_default => '%{severity} eq "critical"',
            set    => {
                key_values => [
                    { name => 'id'          },
                    { name => 'severity'    },
                    { name => 'title'       },
                    { name => 'entity'      },
                    { name => 'age_seconds' },
                ],
                closure_custom_output          => $self->can('custom_alert_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },
    ];
}

sub prefix_alert_output {
    my ($self, %options) = @_;
    return "Alert '" . $options{instance_value}->{id} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'filter-severity:s' => { name => 'filter_severity' },
            'filter-title:s'    => { name => 'filter_title' },
            'filter-entity:s'   => { name => 'filter_entity' },
            # Minimum alert age in seconds; younger alerts are ignored
            'min-age:s'         => { name => 'min_age', default => 0 },
        }
    );

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result   = $options{custom}->get_alerts();
    my $entities = $result->{entities} // [];

    $self->{global} = { critical => 0, warning => 0, info => 0, total => 0 };
    $self->{alerts} = {};

    my $now = time();

    for my $alert (@{$entities}) {
        # Normalize severity: kCritical → critical
        my $raw_sev  = $alert->{severity} // 'kInfo';
        my $severity = $SEVERITY_MAP{$raw_sev} // 'info';

        # Title: reconstructed from alert_title, message, or check_id
        my $title    = $alert->{alert_title}  // $alert->{message} // $alert->{check_id} // 'N/A';

        # Affected entity: scan context_types for a recognizable entity name key
        my $entity = 'cluster';
        my $types  = $alert->{context_types}  // [];
        my $values = $alert->{context_values} // [];
        for my $i (0 .. $#{$types}) {
            if ($types->[$i] =~ /^(vm_name|host_name|storage_pool_name|disk_id)$/i) {
                $entity = $values->[$i] // $entity;
                last;
            }
        }

        # Age in seconds (created_time_stamp_in_usecs is in microseconds)
        my $created_usec = $alert->{created_time_stamp_in_usecs} // 0;
        my $age_s        = ($created_usec > 0) ? ($now - int($created_usec / 1_000_000)) : 0;
        $age_s           = 0 if $age_s < 0;

        my $id = $alert->{id} // $alert->{alert_type_uuid} // "$severity-$title";

        next if defined($self->{option_results}->{filter_severity})
             && $self->{option_results}->{filter_severity} ne ''
             && $severity !~ /$self->{option_results}->{filter_severity}/i;
        next if defined($self->{option_results}->{filter_title})
             && $self->{option_results}->{filter_title} ne ''
             && $title !~ /$self->{option_results}->{filter_title}/i;
        next if defined($self->{option_results}->{filter_entity})
             && $self->{option_results}->{filter_entity} ne ''
             && $entity !~ /$self->{option_results}->{filter_entity}/i;
        next if $age_s < $self->{option_results}->{min_age};

        $self->{global}->{$severity}++;
        $self->{global}->{total}++;

        $self->{alerts}->{$id} = {
            id          => $id,
            severity    => $severity,
            title       => $title,
            entity      => $entity,
            age_seconds => $age_s,
        };
    }
}

1;

__END__

=head1 MODE

Monitor active Nutanix alerts through Prism REST API.

Only unresolved alerts are fetched (C<resolved=false>).

=over 8

=item B<--filter-severity>

Filter alerts by severity (regexp, case-insensitive).
Values: C<critical>, C<warning>, C<info>.
Example: C<--filter-severity='critical|warning'>

=item B<--filter-title>

Filter alerts by title (regexp, case-insensitive).

=item B<--filter-entity>

Filter alerts by affected entity name (regexp).

=item B<--min-age>

Ignore alerts younger than this value in seconds (default: 0).
Example: C<--min-age=300> to skip alerts raised less than 5 minutes ago.

=item B<--warning-alerts-critical>

Warning threshold for count of critical-severity alerts.

=item B<--critical-alerts-critical>

Critical threshold. Example: C<--critical-alerts-critical=1>

=item B<--warning-alerts-warning>

Warning threshold for count of warning-severity alerts.

=item B<--critical-alerts-warning>

Critical threshold for warning-severity alert count.

=item B<--warning-alerts-total>

Warning threshold for total active alert count.

=item B<--critical-alerts-total>

Critical threshold for total active alert count.

=item B<--warning-alert-status>

Warning condition per alert (Perl expression).
Default: C<%{severity} eq "warning">
Variables: C<%{id}>, C<%{severity}>, C<%{title}>, C<%{entity}>, C<%{age_seconds}>

=item B<--critical-alert-status>

Critical condition per alert.
Default: C<%{severity} eq "critical">

=back

=cut
