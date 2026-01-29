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

package database::postgres::mode::backends;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

use centreon::plugins::misc qw/is_excluded/;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'warning:s'           => { redirect => 'warning-instance-connected-count' },
        'critical:s'          => { redirect => 'critical-instance-connected-count' },
        'include-database:s'  => { name => 'include_database', default => '' },
        'exclude-database:s'  => { name => 'exclude_database', default => '' },
        'exclude:s'           => { name => 'exclude_database' },
        'check:s'             => { name => 'check', default => 'database' },
        'include-role:s'      => { name => 'include_role', default => '' },
        'exclude-role:s'      => { name => 'exclude_role', default => '' },
        'noidle'              => { name => 'noidle' }
    });

    return $self;
}

sub custom_global_output {
    my ($self, %options) = @_;

    return sprintf(
        'Instance at %.2f%% of client connections limit (%d of max. %d)',
        $self->{result_values}->{prct_used},
        $self->{result_values}->{used},
        $self->{result_values}->{max_connections}
    );
}

sub custom_backend_output {
    my ($self, %options) = @_;

    return sprintf(
        "Database '%s' at %.2f%% of connections limit (%d of max. %d)",
        $self->{result_values}->{database},
        $self->{result_values}->{prct_used},
        $self->{result_values}->{used},
        $self->{result_values}->{max_connections}
    );
}

sub custom_role_output {
    my ($self, %options) = @_;

    return sprintf(
        "Role '%s' at %.2f%% of connections limit (%d of max. %d)",
        $self->{result_values}->{role},
        $self->{result_values}->{prct_used},
        $self->{result_values}->{used},
        $self->{result_values}->{max_connections}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'backends', type => 1 },
        { name => 'roles', type => 1 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'instance', nlabel => 'instance.connected.count', set => {
                key_values => [ { name => 'used' }, { name => 'prct_used' }, { name => 'max_connections' } ],
                closure_custom_output => $self->can('custom_global_output'),
                perfdatas => [
                    { template => '%s', min => 0, unit => '' },
                ],
            }
        },
        { label => 'instance-prct', nlabel => 'instance.connected.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'max_connections' } ],
                closure_custom_output => $self->can('custom_global_output'),
                perfdatas => [
                    { template => '%s', min => 0, unit => '%' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{backends} = [
        { label => 'database', nlabel => 'database.connected.count', set => {
                key_values => [ { name => 'used' }, { name => 'prct_used' }, { name => 'max_connections' }, { name => 'database' } ],
                closure_custom_output => $self->can('custom_backend_output'),
                perfdatas => [
                    { template => '%s', min => 0, unit => '', label_extra_instance => 1  },
                ],
            }
        },
        { label => 'database-pct', nlabel => 'database.connected.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'max_connections' }, { name => 'database' } ],
                closure_custom_output => $self->can('custom_backend_output'),
                perfdatas => [
                    { template => '%s', min => 0, unit => '%', label_extra_instance => 1  },
                ],
            }
        }
    ];

    $self->{maps_counters}->{roles} = [
        { label => 'role', nlabel => 'role.connected.count', set => {
                key_values => [ { name => 'used' }, { name => 'prct_used' }, { name => 'max_connections' }, { name => 'role' } ],
                closure_custom_output => $self->can('custom_role_output'),
                perfdatas => [
                    { template => '%s', min => 0, unit => '', label_extra_instance => 1  },
                ],
            }
        },
        { label => 'role-prct', nlabel => 'role.connected.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'max_connections' }, { name => 'role' } ],
                closure_custom_output => $self->can('custom_role_output'),
                perfdatas => [
                    { template => '%s', min => 0, unit => '%', label_extra_instance => 1  },
                ],
            }
        }

    ];
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    $self->{option_results}->{check} = lc $self->{option_results}->{check};
    $self->{output}->option_exit( short_msg => 'Check option must be database, role or all')
        unless $self->{option_results}->{check} =~ /^(?:all|database|role)$/;

    $self->{check_database} = $self->{option_results}->{check} =~ /^(?:all|database)$/;
    $self->{check_role} = $self->{option_results}->{check} =~ /^(?:all|role)$/;

    1;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    
    my $noidle = '';
    if ($self->{option_results}->{noidle}) {
        if ($options{sql}->is_version_minimum(version => '9.2')) {
            $noidle = " AND state <> 'idle'";
        } else {
            $noidle = " AND current_query <> '<IDLE>'";
        }
    }

    my $query = "";

    if ($self->{check_database}) {
        $query= qq~SELECT
            'database' AS object_type,
            COUNT(datid) AS current,
            (SELECT setting AS mc FROM pg_settings WHERE name = 'max_connections') AS mc,
            d.datname as object_name,
            d.datconnlimit as object_limit
        FROM pg_database d
        LEFT JOIN pg_stat_activity s ON (s.datid = d.oid$noidle)
        GROUP BY d.datname, d.datconnlimit~;
    }

    if ($self->{check_role}) {
        $query.= " UNION ALL " if $query ne '';

        $query.= qq~SELECT
            'role' AS object_type,
            COUNT(datid) AS current,
            (SELECT setting AS mc FROM pg_settings WHERE name = 'max_connections') AS mc,
            r.rolname as object_name,
            r.rolconnlimit as object_limit
        FROM pg_roles r
        LEFT JOIN pg_stat_activity s ON (s.usename = r.rolname$noidle)
        GROUP BY r.rolname, r.rolconnlimit~;
    }

    $query.= "\nORDER BY object_type, object_name";

    $options{sql}->query(query => $query);

    $self->{backends} = {};
    $self->{roles} = {};

    my $result = $options{sql}->fetchall_arrayref();

    my $check_done = 0;

    my $global_total_connections = 0;
    my $global_max_connections = 0;

    foreach my $row (@{$result}) {
        my ($type, $used, $tmp_max_connections, $name, $max_connections) = @$row;

        if ($self->{check_database} && $type eq 'database') {
            $global_total_connections += $used;
        } elsif (! $self->{check_database} && $type eq 'role') {
            $global_total_connections += $used;
        }
        $global_max_connections = $tmp_max_connections;

        if ($type eq 'database' && is_excluded($name, $self->{option_results}->{include_database}, $self->{option_results}->{exclude_database})) {
            $self->{output}->output_add(long_msg => "Skipping database '$name'");
            next
        }
        if ($type eq 'role' && is_excluded($name, $self->{option_results}->{include_role}, $self->{option_results}->{exclude_role})) {
            $self->{output}->output_add(long_msg => "Skipping role '$name'");
            next
        }

        $max_connections = $global_max_connections if $max_connections == -1 || $max_connections > $global_max_connections;
        
        my $prct_used = ($used * 100) / $max_connections;

        if ($type eq 'database') {
            $self->{backends}->{$name} = { used => $used,
                                           prct_used=> $prct_used,
                                           max_connections => $max_connections,
                                           database => $name };
        } else {
            $self->{roles}->{$name} = { used => $used,
                                        prct_used=> $prct_used,
                                        max_connections => $max_connections,
                                        role => $name };
        }
        
        $check_done = 1;
    }

    $self->{global} = { used => $global_total_connections,
                        prct_used => $global_max_connections ?
                                        ($global_total_connections * 100) / $global_max_connections :
                                        0,
                        max_connections => $global_max_connections
                       };

    $self->{output}->option_exit( short_msg => 'No '.( $self->{check_database} ? 'database' : 'role' ).' checked (permission or a wrong filter)')
        unless $check_done;
}

1;

__END__

=head1 MODE

Check the current number of connections for one or more databases

=over 8

=item B<--check>

What to check (default: 'database')
Can be: 'database', 'role', 'all'.

=item B<--include-database>

Filter databases using a regular expression.

=item B<--exclude-database>

Exclude databases using a regular expression.

=item B<--include-user>

Filter users using a regular expression.

=item B<--exclude-user>

Exclude users using a regular expression.

=item B<--noidle>

Idle connections are not counted.

=item B<--warning-database>

Threshold.

=item B<--critical-database>

Threshold.

=item B<--warning-database-pct>

Threshold in percentage.

=item B<--critical-database-pct>

Threshold in percentage.

=item B<--warning-instance>

Threshold.

=item B<--critical-instance>

Threshold.

=item B<--warning-instance-prct>

Threshold.

=item B<--critical-instance-prct>

Threshold.

=item B<--warning-role>

Threshold.

=item B<--critical-role>

Threshold.

=item B<--warning-role-prct>

Threshold in percentage.

=item B<--critical-role-prct>

Threshold in percentage.

=back

=cut
