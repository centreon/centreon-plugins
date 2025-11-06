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

package cloud::prometheus::alertmanager::restapi::mode::alerts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc qw(is_excluded);

sub prefix_output_active {
    my ($self, %options) = @_;

    return 'Alerts active ';
}

sub prefix_output_other {
    my ($self, %options) = @_;

    return 'Alerts ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'active', type => 0, cb_prefix_output => 'prefix_output_active' },
        { name => 'other', type => 0, cb_prefix_output => 'prefix_output_other' }
    ];

    $self->{maps_counters}->{active} = [
        { label  => 'active',
          nlabel => 'alerts.active.count',
          set    => {
              key_values      => [ { name => 'active' }, { name => 'total' } ],
              output_template => 'detected: %d',
              perfdatas       => [ {
                  template => '%d',
                  min      => 0,
                  max      => 'total'
              } ]
          }
        },
        { label  => 'active-warning',
          nlabel => 'alerts.active.warning.count',
          set    => {
              key_values      => [ { name => 'warning' }, { name => 'total' } ],
              output_template => 'warning: %d',
              perfdatas       => [ {
                  template => '%d',
                  min      => 0,
                  max      => 'total'
              } ]
          }
        },
        { label  => 'active-critical',
          nlabel => 'alerts.active.critical.count',
          set    => {
              key_values      => [ { name => 'critical' }, { name => 'total' } ],
              output_template => 'critical: %d',
              perfdatas       => [ {
                  emplate => '%d',
                  min     => 0,
                  max     => 'total'
              } ]
          }
        },
        { label  => 'active-info',
          nlabel => 'alerts.active.info.count',
          set    => {
              key_values      => [ { name => 'info' }, { name => 'total' } ],
              output_template => 'info: %d',
              perfdatas       => [ {
                  template => '%d',
                  min      => 0,
                  max      => 'total'
              } ]
          }
        }
    ];

    $self->{maps_counters}->{other} = [
        { label      => 'total',
          nlabel     => 'alerts.total.count',
          display_ok => 0,
          set        => {
              key_values      => [ { name => 'total' } ],
              output_template => 'total: %d',
              perfdatas       => [ {
                  template => '%d',
                  min      => 0
              } ]
          }
        },
        { label      => 'unprocessed',
          nlabel     => 'alerts.unprocessed.count',
          display_ok => 0,
          set        => {
              key_values      => [ { name => 'unprocessed' }, { name => 'total' } ],
              output_template => 'unprocessed: %d',
              perfdatas       => [ {
                  template => '%d',
                  min      => 0,
                  max      => 'total'
              } ]
          }
        },
        { label      => 'suppressed',
          nlabel     => 'alerts.suppressed.count',
          display_ok => 0,
          set        => {
              key_values      => [ { name => 'suppressed' }, { name => 'total' } ],
              output_template => 'suppressed: %d',
              perfdatas       => [ {
                  template => '%d',
                  min      => 0,
                  max      => 'total'
              } ]
          }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'filter-severity:s' => { name => 'filter_severity' },
        'display-alerts:s'  => { name => 'display_alerts' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{display_alerts})) {
        my $mapping = {
            startsAt    => 1,
            endsAt      => 1,
            updatedAt   => 1,
            state       => 1,
            severity    => 1,
            alertname   => 1,
            targetType  => 1,
            host        => 1,
            summary     => 1,
            description => 1
        };
        if ($self->{option_results}->{display_alerts} eq '') {
            $self->{option_results}->{display_alerts} = 'alert [start: %(startsAt)] [state: %(state)] [severity: %(severity)]: %(alertname)';
        }

        while ($self->{option_results}->{display_alerts} =~ /\%\((.*?)\)/g) {
            $self->{output}->option_exit(short_msg => "option --display-alerts unsupported label: %($1)") unless defined($mapping->{$1});
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_endpoint(
        endpoint => '/alerts'
    );
    if (ref($results) eq 'HASH') {
        $results = [ $results ];
    }

    $self->{active} = { total => 0, warning => 0, critical => 0, info => 0 };
    $self->{other} = { total => 0, unprocessed => 0, suppressed => 0 };
    foreach my $alert (@$results) {
        next if is_excluded($alert->{labels}->{alertname}, $self->{option_results}->{filter_name});
        next if is_excluded($alert->{labels}->{severity}, $self->{option_results}->{filter_severity});

        if ($alert->{status}->{state} eq 'active') {
            $self->{active}->{active}++;
            if ($alert->{labels}->{severity} =~ /warning|critical|info/) {
                $self->{active}->{ $alert->{labels}->{severity} }++;
            }
        } elsif ($alert->{status}->{state} =~ /unprocessed|suppressed/) {
            $self->{other}->{other}++;
            $self->{other}->{ $alert->{status}->{state} }++;
        }

        $self->{other}->{total}++;
        $self->{active}->{total}++;
        if (defined($self->{option_results}->{display_alerts})) {
            my $values = {
                startsAt    => $alert->{startsAt},
                endsAt      => defined($alert->{endsAt}) ? $alert->{endsAt} : '',
                updatedAt   => defined($alert->{updatedAt}) ? $alert->{updatedAt} : '',
                state       => $alert->{status}->{state},
                severity    => $alert->{labels}->{severity},
                alertname   => $alert->{labels}->{alertname},
                targetType  => defined($alert->{labels}->{target_type}) ? $alert->{labels}->{target_type} : '',
                host        => defined($alert->{labels}->{host}) ? $alert->{labels}->{host} : '',
                summary     => defined($alert->{annotations}->{summary}) ? $alert->{annotations}->{summary} : '',
                description => defined($alert->{annotations}->{description}) ? $alert->{annotations}->{description} : ''
            };
            my $message = $self->{option_results}->{display_alerts};
            $message =~ s/%\((.*?)\)/$values->{$1}/g;

            $self->{output}->output_add(long_msg => $message);
        }
    }
}

1;

__END__

=head1 MODE

Check alerts.

=over 8

=item B<--filter-name>

Filter alerts by name (can use regexp).

=item B<--filter-severity>

Filter alerts by severity (can use regexp).

=item B<--display-alerts>

Display alerts in verbose output (default: C<'alert [start: %(startsAt)] [state: %(state)] [severity: %(severity)]: %(alertname)'>).

=item B<--warning-active>

Warning threshold for active alerts count.

=item B<--critical-active>

Critical threshold for active alerts count.

=item B<--warning-active-warning>

Warning threshold for active alerts with warning severity count.

=item B<--critical-active-warning>

Critical threshold for active alerts with warning severity count.

=item B<--warning-active-critical>

Warning threshold for active alerts with critical severity count.

=item B<--critical-active-critical>

Critical threshold for active alerts with critical severity count.

=item B<--warning-active-info>

Warning threshold for active alerts with info severity count.

=item B<--critical-active-info>

Critical threshold for active alerts with info severity count.

=item B<--warning-total>

Warning threshold for total alerts count.

=item B<--critical-total>

Critical threshold for total alerts count.

=item B<--warning-unprocessed>

Warning threshold for unprocessed alerts count.

=item B<--critical-unprocessed>

Critical threshold for unprocessed alerts count.

=item B<--warning-suppressed>

Warning threshold for suppressed alerts count.

=item B<--critical-suppressed>

Critical threshold for suppressed alerts count.

=back

=cut
