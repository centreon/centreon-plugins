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

package database::mysql::mode::threadsconnected;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;
    
    return sprintf(
        'Client connected threads total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $self->{result_values}->{total},
        $self->{result_values}->{used},
        $self->{result_values}->{prct_used},
        $self->{result_values}->{free},
        $self->{result_values}->{prct_free}
    );
}

sub prefix_databse_output {
    my ($self, %options) = @_;

    return "Database '" . $options{instance_value}->{name} . "' ";
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } },
        { name => 'databases', type => 1, cb_prefix_output => 'prefix_database_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'usage', nlabel => 'threads.connected.count', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' },
                ]
            }
        },
        { label => 'usage-prct', nlabel => 'threads.connected.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'free' }, { name => 'used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{databases} = [
        { label => 'database-threads-connected', nlabel => 'database.threads.connected.count', display_ok => 0, set => {
                key_values => [ { name => 'threads_connected' } ],
                output_template => 'threads connected: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
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
        'add-databases'  => { name => 'add_databases' }
    });

    return $self;
}


sub add_databases {
    my ($self, %options) = @_;

    $options{sql}->query(query => q{
        SELECT
            schema_name,
            SUM(case when DB is not null then 1 else 0 end) as numbers
        FROM information_schema.schemata LEFT JOIN information_schema.processlist ON schemata.schema_name = DB
        GROUP BY schemata.schema_name
    });

    $self->{databases} = {};
    my $result = $options{sql}->fetchall_arrayref();
    foreach my $row (@$result) {
        $self->{databases}->{ $row->[0] } = {
            name => $row->[0],
            threads_connected => $row->[1]
        };
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    if (!($options{sql}->is_version_minimum(version => '5'))) {
        $self->{output}->add_option_msg(short_msg => "MySQL version '" . $self->{sql}->{version} . "' is not supported (need version >= '5.x').");
        $self->{output}->option_exit();
    }

    my $infos = {};
    if (!$options{sql}->is_mariadb() && $options{sql}->is_version_minimum(version => '5.7.6')) {
         $options{sql}->query(query => q{
            SELECT 'max_connections' as name, @@GLOBAL.max_connections as value
            UNION
            SELECT VARIABLE_NAME as name, VARIABLE_VALUE as value FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Threads_connected'
        });
        while (my ($name, $value) = $options{sql}->fetchrow_array()) {
            $infos->{lc($name)} = $value;
        }
    } elsif ($options{sql}->is_version_minimum(version => '5.1.12')) {
        $options{sql}->query(query => q{
            SELECT 'max_connections' as name, @@GLOBAL.max_connections as value
            UNION
            SELECT VARIABLE_NAME as name, VARIABLE_VALUE as value FROM information_schema.GLOBAL_STATUS WHERE VARIABLE_NAME = 'Threads_connected'
        });
        while (my ($name, $value) = $options{sql}->fetchrow_array()) {
            $infos->{lc($name)} = $value;
        }
    } else {
        $options{sql}->query(query => q{SELECT 'max_connections' as name, @@GLOBAL.max_connections as value});
        if (my ($name, $value) = $options{sql}->fetchrow_array()) {
            $infos->{lc($name)} = $value 
        }
        $options{sql}->query(query => q{SHOW /*!50000 global */ STATUS LIKE 'Threads_connected'});
        if (my ($name, $value) = $options{sql}->fetchrow_array()) {
            $infos->{lc($name)} = $value 
        }
    }

    if (scalar(keys %$infos) == 0) {
        $self->{output}->add_option_msg(short_msg => 'Cannot get number of open connections.');
        $self->{output}->option_exit();
    }

    my $prct_used = $infos->{threads_connected} * 100 / $infos->{max_connections};
    $self->{global} = {
       total => $infos->{max_connections},
       used => $infos->{threads_connected},
       free => $infos->{max_connections} - $infos->{threads_connected},
       prct_used => $prct_used,
       prct_free => 100 - $prct_used
    };

    if (defined($self->{option_results}->{add_databases})) {
        $self->add_databases(sql => $options{sql});
    }
}

1;

__END__

=head1 MODE

Check number of open connections.

=over 8

=item B<--add-databases>

Add threads by databases.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage', 'usage-prct' (%), 'database-threads-connected'.

=back

=cut
