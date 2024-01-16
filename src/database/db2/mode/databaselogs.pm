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

package database::db2::mode::databaselogs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'B',
        instances => [$self->{result_values}->{dbname}, $self->{result_values}->{partition}],
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => $self->{result_values}->{total}
    );
}

sub custom_usage_free_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'B',
        instances => [$self->{result_values}->{dbname}, $self->{result_values}->{partition}],
        value => $self->{result_values}->{free},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => $self->{result_values}->{total}
    );
}

sub custom_usage_prct_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => '%',
        instances => [$self->{result_values}->{dbname}, $self->{result_values}->{partition}],
        value => sprintf('%.2f', $self->{result_values}->{prct_used}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => 100
    );
}

sub prefix_log_output {
    my ($self, %options) = @_;

    return sprintf(
        "database '%s' log '%s' ",
        $options{instance_value}->{dbname},
        $options{instance_value}->{partition}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'logs', type => 1, cb_prefix_output => 'prefix_log_output', message_multiple => 'All database logs are ok' }
    ];

    $self->{maps_counters}->{logs} = [
        { label => 'log-usage', nlabel => 'database.log.usage.bytes', set => {
                key_values => [ 
                    { name => 'used' }, { name => 'free' },
                    { name => 'prct_used' }, { name => 'prct_free' },
                    { name => 'total' }, { name => 'dbname' }, { name => 'partition' }
                ],
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata')
            }
        },
        { label => 'log-usage-free', nlabel => 'database.log.free.bytes', display_ok => 0, set => {
                key_values => [
                    { name => 'free' }, { name => 'used' },
                    { name => 'prct_used' }, { name => 'prct_free' },
                    { name => 'total' }, { name => 'dbname' }, { name => 'partition' }
                ],
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_free_perfdata')
            }
        },
        { label => 'log-usage-prct', nlabel => 'database.log.usage.percentage', display_ok => 0, set => {
                key_values => [
                    { name => 'prct_used' }, { name => 'used' },
                    { name => 'free' }, { name => 'prct_free' },
                    { name => 'total' }, { name => 'dbname' }, { name => 'partition' }
                ],
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_prct_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => q{
        SELECT 
            dbpartitionnum, total_log_used_kb, total_log_available_kb
        FROM
            sysibmadm.log_utilization
    });

    my $dbname = $options{sql}->get_database_name();
    $self->{logs} = {};
    while (my $row = $options{sql}->fetchrow_arrayref()) {
        my $used = $row->[1] * 1024;
        my $total = $used + ($row->[2] * 1024);
        $self->{logs}->{ $row->[0] } = {
            dbname => $dbname,
            partition => $row->[0],
            total => $total,
            used => $used,
            free => $total - $used,
            prct_used => $used * 100 / $total,
            prct_free => 100 - ($used * 100 / $total)
        };
    }
}

1;

__END__

=head1 MODE

Check database logs utilization.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage', 'usage-free', 'usage-prct'.

=back

=cut
