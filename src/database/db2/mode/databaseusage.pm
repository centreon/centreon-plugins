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

package database::db2::mode::databaseusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DBD::DB2::Constants;

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
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
        instances => $self->{result_values}->{dbname},
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
        instances => $self->{result_values}->{dbname},
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
        instances => $self->{result_values}->{dbname},
        value => sprintf('%.2f', $self->{result_values}->{prct_used}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => 100
    );
}

sub prefix_output {
    my ($self, %options) = @_;

    return sprintf(
        "database '%s' ",
        $options{instance_value}->{dbname}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'space-usage', nlabel => 'database.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'dbname' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata')
            }
        },
        { label => 'space-usage-free', nlabel => 'database.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'dbname' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_free_perfdata')
            }
        },
        { label => 'space-usage-prct', nlabel => 'database.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' }, { name => 'dbname' } ],
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
    my $dbh = $options{sql}->get_dbh();

    my ($snapshot_timestamp, $db_size, $db_capacity) = ('', 0, 0);
    my $sth = $dbh->prepare(q{
        CALL SYSPROC.GET_DBSIZE_INFO(?, ?, ?, 0)
    });
    $sth->bind_param_inout(1, \$snapshot_timestamp, 30, { db2_param_type=>SQL_PARAM_OUTPUT() });
    $sth->bind_param_inout(2, \$db_size, 30, { db2_param_type=>SQL_PARAM_OUTPUT() });
    $sth->bind_param_inout(3, \$db_capacity, 30, { db2_param_type=>SQL_PARAM_OUTPUT() });
    $sth->execute();
    if (!defined($snapshot_timestamp) || $snapshot_timestamp eq '') {
        $self->{output}->add_option_msg(short_msg => 'Cannot execute query: ' . $dbh->errstr());
        $self->{output}->option_exit();
    }

    $self->{global} = {
        dbname => $options{sql}->get_database_name(),
        total => $db_capacity,
        used => $db_size,
        free => $db_capacity - $db_size,
        prct_used => $db_size * 100 / $db_capacity,
        prct_free => 100 - ($db_size * 100 / $db_capacity)
    };
}

1;

__END__

=head1 MODE

Check database space usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage', 'space-usage-free', 'space-usage-prct'.

=back

=cut
