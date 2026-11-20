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

package apps::nutanix::prism::mode::healthchecks;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

# Nutanix NCC health checks expose per-node results in execution_results[].
# The overall state is read from health_check_series[].state (last entry) or state:
#   PASS, FAIL, WARNING, INFO, ERROR, SCHEDULED, RUNNING, ABORTED

my %STATE_SEVERITY = (
    FAIL    => 'critical',
    ERROR   => 'critical',
    WARNING => 'warning',
    PASS    => 'ok',
    INFO    => 'info',
);

sub custom_check_output {
    my ($self, %options) = @_;
    return sprintf(
        "health check '%s' [category: %s] state is '%s' — %s",
        $self->{result_values}->{name},
        $self->{result_values}->{category},
        $self->{result_values}->{state},
        $self->{result_values}->{message},
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        # Global summary: check counts by result state
        { name => 'global', type => 0 },
        # Individual result per health check
        {
            name             => 'checks',
            type             => 1,
            cb_prefix_output => 'prefix_check_output',
            message_multiple => 'All health checks passed',
            skipped_code     => { -10 => 1 },
        },
    ];

    $self->{maps_counters}->{global} = [
        {
            label  => 'checks-pass',
            nlabel => 'healthchecks.pass.count',
            set    => {
                key_values      => [ { name => 'pass' } ],
                output_template => 'pass: %d',
                perfdatas       => [ { template => '%d', min => 0 } ],
            }
        },
        {
            label  => 'checks-fail',
            nlabel => 'healthchecks.fail.count',
            set    => {
                key_values      => [ { name => 'fail' } ],
                output_template => 'fail: %d',
                perfdatas       => [ { template => '%d', min => 0 } ],
            }
        },
        {
            label  => 'checks-warning',
            nlabel => 'healthchecks.warning.count',
            set    => {
                key_values      => [ { name => 'warning' } ],
                output_template => 'warning: %d',
                perfdatas       => [ { template => '%d', min => 0 } ],
            }
        },
        {
            label  => 'checks-error',
            nlabel => 'healthchecks.error.count',
            set    => {
                key_values      => [ { name => 'error' } ],
                output_template => 'error: %d',
                perfdatas       => [ { template => '%d', min => 0 } ],
            }
        },
    ];

    $self->{maps_counters}->{checks} = [
        {
            label            => 'check-status',
            type             => 2,
            warning_default  => '%{state} eq "WARNING"',
            critical_default => '%{state} =~ /^(FAIL|ERROR)$/',
            set              => {
                key_values => [
                    { name => 'name'     },
                    { name => 'category' },
                    { name => 'state'    },
                    { name => 'message'  },
                ],
                closure_custom_output          => $self->can('custom_check_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },
    ];
}

sub prefix_check_output {
    my ($self, %options) = @_;
    return "Check '" . $options{instance_value}->{name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'filter-name:s'     => { name => 'filter_name' },
            'filter-category:s' => { name => 'filter_category' },
            # Only report non-PASS checks to reduce noise on large clusters
            'only-failing'      => { name => 'only_failing' },
        }
    );

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result   = $options{custom}->get_health_checks();
    my $entities = $result->{entities} // [];

    $self->{global} = { pass => 0, fail => 0, warning => 0, error => 0 };
    $self->{checks} = {};

    for my $check (@{$entities}) {
        my $name     = $check->{name}     // $check->{check_id} // 'unknown';
        my $category = $check->{category} // 'N/A';

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '') {
            next if $name !~ /$self->{option_results}->{filter_name}/i;
        }
        if (defined($self->{option_results}->{filter_category}) && $self->{option_results}->{filter_category} ne '') {
            next if $category !~ /$self->{option_results}->{filter_category}/i;
        }

        # Overall state from health_check_series[].state (last entry) or state field
        my $state = 'UNKNOWN';
        if (defined($check->{health_check_series}) && ref($check->{health_check_series}) eq 'ARRAY'
                && @{$check->{health_check_series}}) {
            $state = uc($check->{health_check_series}->[-1]->{state} // 'UNKNOWN');
        } elsif (defined($check->{state})) {
            $state = uc($check->{state});
        }

        next if defined($self->{option_results}->{only_failing}) && $state eq 'PASS';

        # Detail message: concatenate execution result messages when available
        my $message = $check->{message} // '';
        if (!$message && defined($check->{health_check_series}) && @{$check->{health_check_series}}) {
            my $last = $check->{health_check_series}->[-1];
            my $causes = join('; ', map { $_->{message} // '' } @{ $last->{execution_results} // [] });
            $message = $causes if $causes ne '';
        }
        $message = 'no detail' if $message eq '';

        # Increment the matching global bucket (error stays in its own bucket,
        # not merged into fail — otherwise healthchecks.error.count would always be 0).
        my $bucket = lc($state);
        $self->{global}->{$bucket}++ if exists $self->{global}->{$bucket};

        $self->{checks}->{$name} = {
            name     => $name,
            category => $category,
            state    => $state,
            message  => $message,
        };
    }
}

1;

__END__

=head1 MODE

Monitor Nutanix NCC (Nutanix Cluster Check) health check results through Prism REST API.

Each health check reports a state: C<PASS>, C<FAIL>, C<WARNING>, C<ERROR>,
C<INFO>, C<RUNNING>, C<SCHEDULED> or C<ABORTED>.

=over 8

=item B<--filter-name>

Filter health checks by name (regexp, case-insensitive).
Example: C<--filter-name='disk|cvm'>

=item B<--filter-category>

Filter health checks by category (regexp, case-insensitive).
Example: C<--filter-category='Hardware'>

=item B<--only-failing>

Only report health checks that are not in PASS state.
Useful to reduce noise on large clusters.

=item B<--warning-check-status>

Warning condition per check (Perl expression).
Default: C<%{state} eq "WARNING">

Variables: C<%{name}>, C<%{category}>, C<%{state}>, C<%{message}>

=item B<--critical-check-status>

Critical condition per check.
Default: C<%{state} =~ /^(FAIL|ERROR)$/>

=item B<--warning-checks-fail>

Warning threshold for count of FAIL checks.

=item B<--critical-checks-fail>

Critical threshold for count of FAIL checks. Example: C<--critical-checks-fail=1>

=item B<--warning-checks-warning>

Warning threshold for count of WARNING checks.

=item B<--critical-checks-warning>

Critical threshold for count of WARNING checks.

=item B<--warning-checks-error>

Warning threshold for count of ERROR checks.

=item B<--critical-checks-error>

Critical threshold for count of ERROR checks.

=back

=cut
