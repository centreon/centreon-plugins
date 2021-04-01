#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package database::postgres::mode::statistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'database', type => 1, cb_prefix_output => 'prefix_database_output', message_multiple => 'All database statistics are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-commit', nlabel => 'queries.commit.count', set => {
                key_values => [ { name => 'commit', diff => 1 } ],
                output_template => 'Commit : %s',
                perfdatas => [
                    { label => 'commit', value => 'commit', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'total-rollback', nlabel => 'queries.rollback.count', set => {
                key_values => [ { name => 'rollback', diff => 1 } ],
                output_template => 'Rollback : %s',
                perfdatas => [
                    { label => 'rollback', value => 'rollback', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'total-insert', nlabel => 'queries.insert.count', set => {
                key_values => [ { name => 'insert', diff => 1 } ],
                output_template => 'Insert : %s',
                perfdatas => [
                    { label => 'insert', value => 'insert', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'total-update', nlabel => 'queries.update.count', set => {
                key_values => [ { name => 'update', diff => 1 } ],
                output_template => 'Update : %s',
                perfdatas => [
                    { label => 'update', value => 'update', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'total-delete', nlabel => 'queries.delete.count', set => {
                key_values => [ { name => 'delete', diff => 1 } ],
                output_template => 'Delete : %s',
                perfdatas => [
                    { label => 'delete', value => 'delete', template => '%s', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{database} = [
        { label => 'commit', nlabel => 'queries.commit.count', set => {
                key_values => [ { name => 'commit', diff => 1 }, { name => 'name' }, ],
                output_template => 'Commit : %s',
                perfdatas => [
                    { label => 'commit', value => 'commit', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'rollback', nlabel => 'queries.rollback.count', set => {
                key_values => [ { name => 'rollback', diff => 1 }, { name => 'name' }, ],
                output_template => 'Rollback : %s',
                perfdatas => [
                    { label => 'rollback', value => 'rollback', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'insert', nlabel => 'queries.insert.count', set => {
                key_values => [ { name => 'insert', diff => 1 }, { name => 'name' }, ],
                output_template => 'Insert : %s',
                perfdatas => [
                    { label => 'insert', value => 'insert', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'update', nlabel => 'queries.update.count', set => {
                key_values => [ { name => 'update', diff => 1 }, { name => 'name' }, ],
                output_template => 'Update : %s',
                perfdatas => [
                    { label => 'update', value => 'update', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'delete', nlabel => 'queries.delete.count', set => {
                key_values => [ { name => 'delete', diff => 1 }, { name => 'name' }, ],
                output_template => 'Delete : %s',
                perfdatas => [
                    { label => 'delete', value => 'delete', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return 'Total ';
}

sub prefix_database_output {
    my ($self, %options) = @_;
    
    return "Database '" . $options{instance_value}->{name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "filter-database:s"     => { name => 'filter_database' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{database} = {};
    $self->{global} = { commit => 0, rollback => 0, insert => 0, update => 0, delete => 0 };
    my $query = q{
SELECT d.datname as name, pg_stat_get_db_xact_commit(d.oid) as commit, 
                  pg_stat_get_db_xact_rollback(d.oid) as rollback, 
                  pg_stat_get_tuples_inserted(d.oid) as insert, 
                  pg_stat_get_tuples_updated(d.oid) as update, pg_stat_get_tuples_updated(d.oid) as delete 
       FROM pg_database d;
};
    $options{sql}->connect();
    $options{sql}->query(query => $query);
    
    while ((my $row = $options{sql}->fetchrow_hashref())) {
        if (defined($self->{option_results}->{filter_database}) && $self->{option_results}->{filter_database} ne '' &&
            $row->{name} !~ /$self->{option_results}->{filter_database}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $row->{name} . "': no matching filter.");
            next;
        }
        
        $self->{database}->{$row->{name}} = {%$row};
        foreach (keys %{$self->{global}}) {
            $self->{global}->{$_} += $row->{$_};
        }
    }
    
    if (scalar(keys %{$self->{database}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No database found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = "postgres_" . $self->{mode} . '_' . $options{sql}->get_unique_id4save()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_database}) ? md5_hex($self->{option_results}->{filter_database}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check database statistics: commit, rollback, insert, delete, update.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'commit', 'rollback', 'insert', 'delete', 'update',
'total-commit', 'total-rollback', 'total-insert', 'total-delete', 'total-update'.

=item B<--critical-*>

Threshold critical.
Can be: 'commit', 'rollback', 'insert', 'delete', 'update',
'total-commit', 'total-rollback', 'total-insert', 'total-delete', 'total-update'.

=item B<--filter-database>

Filter database (can be a regexp).

=back

=cut
