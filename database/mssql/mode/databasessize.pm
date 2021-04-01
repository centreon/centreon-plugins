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

package database::mssql::mode::databasessize;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_space_usage_perfdata {
    my ($self, %options) = @_;

    my ($warning, $critical);
    if (!(defined($self->{instance_mode}->{option_results}->{ignore_unlimited}) && $self->{result_values}->{limit} eq 'unlimited')) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
        $critical =  $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    }
    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'B',
        instances => $self->{result_values}->{name}, 
        value => $self->{result_values}->{used_space},
        warning => $warning,
        critical => $critical,
        min => 0,
        max => $self->{result_values}->{total_space}
    );
}

sub custom_space_free_perfdata {
    my ($self, %options) = @_;

    my ($warning, $critical);
    if (!(defined($self->{instance_mode}->{option_results}->{ignore_unlimited}) && $self->{result_values}->{limit} eq 'unlimited')) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
        $critical =  $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    }
    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'B',
        instances => $self->{result_values}->{name}, 
        value => $self->{result_values}->{free_space},
        warning => $warning,
        critical => $critical,
        min => 0,
        max => $self->{result_values}->{total_space}
    );
}

sub custom_space_usage_prct_perfdata {
    my ($self, %options) = @_;

    my ($warning, $critical);
    if (!(defined($self->{instance_mode}->{option_results}->{ignore_unlimited}) && $self->{result_values}->{limit} eq 'unlimited')) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
        $critical =  $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    }
    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => '%',
        instances => $self->{result_values}->{name}, 
        value => sprintf('%.2f', $self->{result_values}->{prct_used_space}),
        warning => $warning,
        critical => $critical,
        min => 0,
        max => 100
    );
}

sub custom_space_threshold {
    my ($self, %options) = @_;

    return 'ok' if (
        defined($self->{instance_mode}->{option_results}->{ignore_unlimited}) &&
        $self->{result_values}->{limit} eq 'unlimited'
    );

    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{ $self->{key_values}->[0]->{name} },
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_space_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    return sprintf(
        'space total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
}

sub database_long_output {
    my ($self, %options) = @_;

    return "checking database '" . $options{instance_value}->{name} . "'";
}

sub prefix_database_output {
    my ($self, %options) = @_;

    return "database '" . $options{instance_value}->{name} . "' ";
}

sub prefix_logfiles_output {
    my ($self, %options) = @_;

    return 'log files ';
}

sub prefix_datafiles_output {
    my ($self, %options) = @_;

    return 'data files ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'databases', type => 3, cb_prefix_output => 'prefix_database_output', cb_long_output => 'database_long_output', indent_long_output => '    ', message_multiple => 'All databases are ok',
            group => [
                { name => 'datafiles', type => 0, cb_prefix_output => 'prefix_datafiles_output', skipped_code => { -10 => 1 } },
                { name => 'logfiles', type => 0, cb_prefix_output => 'prefix_logfiles_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{datafiles} = [
        { label => 'datafiles-space-usage', nlabel => 'datafiles.space.usage.bytes', set => {
                key_values => [
                    { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' },
                    { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'name' },
                    { name => 'limit' }
                ],
                closure_custom_output => $self->can('custom_space_output'),
                closure_custom_threshold_check => $self->can('custom_space_threshold'),
                closure_custom_perfdata => $self->can('custom_space_usage_perfdata')
            }
        },
        { label => 'datafiles-space-usage-free', nlabel => 'datafiles.space.free.bytes', display_ok => 0, set => {
                key_values => [
                    { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' },
                    { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'name' },
                    { name => 'limit' }
                ],
                closure_custom_output => $self->can('custom_space_output'),
                closure_custom_threshold_check => $self->can('custom_space_threshold'),
                closure_custom_perfdata => $self->can('custom_space_free_perfdata')
            }
        },
        { label => 'datafiles-space-usage-prct', nlabel => 'datafiles.space.usage.percentage', display_ok => 0, set => {
                key_values => [
                    { name => 'prct_used_space' }, { name => 'used_space' }, { name => 'free_space' },
                    { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'name' },
                    { name => 'limit' }
                ],
                closure_custom_output => $self->can('custom_space_output'),
                closure_custom_threshold_check => $self->can('custom_space_threshold'),
                closure_custom_perfdata => $self->can('custom_space_usage_prct_perfdata')
            }
        }
    ];

    $self->{maps_counters}->{logfiles} = [
        { label => 'logfiles-space-usage', nlabel => 'logfiles.space.usage.bytes', set => {
                key_values => [
                    { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' },
                    { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'name' },
                    { name => 'limit' }
                ],
                closure_custom_output => $self->can('custom_space_output'),
                closure_custom_threshold_check => $self->can('custom_space_threshold'),
                closure_custom_perfdata => $self->can('custom_space_usage_perfdata')
            }
        },
        { label => 'logfiles-space-usage-free', nlabel => 'logfiles.space.free.bytes', display_ok => 0, set => {
                key_values => [
                    { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' },
                    { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'name' },
                    { name => 'limit' }
                ],
                closure_custom_output => $self->can('custom_space_output'),
                closure_custom_threshold_check => $self->can('custom_space_threshold'),
                closure_custom_perfdata => $self->can('custom_space_free_perfdata')
            }
        },
        { label => 'logfiles-space-usage-prct', nlabel => 'logfiles.space.usage.percentage', display_ok => 0, set => {
                key_values => [
                    { name => 'prct_used_space' }, { name => 'used_space' }, { name => 'free_space' },
                    { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'name' },
                    { name => 'limit' }
                ],
                closure_custom_output => $self->can('custom_space_output'),
                closure_custom_threshold_check => $self->can('custom_space_threshold'),
                closure_custom_perfdata => $self->can('custom_space_usage_prct_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-database:s'             => { name => 'filter_database' },
        'datafiles-maxsize:s'           => { name => 'datafiles_maxsize' },
        'logfiles-maxsize:s'            => { name => 'logfiles_maxsize' },
        'datafiles-maxsize-unlimited:s' => { name => 'datafiles_maxsize_unlimited' },
        'logfiles-maxsize-unlimited:s'  => { name => 'logfiles_maxsize_unlimited' },
        'check-underlying-disk'         => { name => 'check_underlying_disk' },   
        'ignore-unlimited'              => { name => 'ignore_unlimited' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my ($unlimited_disk, $drives, $result) = ({}, {});

    $options{sql}->connect();

    if (defined($self->{option_results}->{check_underlying_disk})) {
        $options{sql}->query(query => qq{exec master.dbo.xp_fixeddrives});
        $result = $options{sql}->fetchall_arrayref();
        foreach my $row (@$result) {
            $drives->{ $row->[0] } = $row->[1] * 1024 * 1024;
        }
    }

    $options{sql}->query(query => qq{
        EXEC sp_MSforeachdb 'USE ?
        SELECT
            DB_NAME(),
            [name],    
            physical_name,
            [File_Type] = CASE type   
                WHEN 0 THEN ''data''
                WHEN 1 THEN ''log''
            END,
            [Total_Size] = [size],
            [Used_Space] = (CAST(FILEPROPERTY([name], ''SpaceUsed'') as int)),
            [Growth_Units] = CASE [is_percent_growth]    
                WHEN 1 THEN CAST(growth AS varchar(20)) + ''%''
                ELSE CAST(growth*8/1024 AS varchar(20)) + ''Mb''
            END,
            [max_size]
        FROM sys.database_files'
    });

    # limit can be: 'unlimited', 'overload', 'other'.
    $self->{databases} = {};
    while ($result = $options{sql}->fetchall_arrayref()) {
        last if (scalar(@$result) <= 0);

        foreach my $row (@$result) {
            next if (!defined($row->[7]));    
    
            if (defined($self->{option_results}->{filter_database}) && $self->{option_results}->{filter_database} ne '' &&
                $row->[0] !~ /$self->{option_results}->{filter_database}/i) {
                $self->{output}->output_add(debug => 1, long_msg => "skipping database " . $row->[0] . ": no matching filter.");
                next;
            }

            if (!defined($self->{databases}->{ $row->[0] })) {
                $self->{databases}->{ $row->[0] } = {
                    name => $row->[0],
                    datafiles => {
                        name => $row->[0],
                        used_space => 0,
                        total_space => 0,
                        limit => 'other'
                    },
                    logfiles => {
                        name => $row->[0],
                        used_space => 0,
                        total_space => 0,
                        limit => 'other'
                    }
                };
            }

            $self->{databases}->{ $row->[0] }->{$row->[3] . 'files'}->{used_space} += ($row->[5] * 8 * 1024);

            my $size = $row->[4] * 8 * 1024;
            #max_size = -1 (=unlimited)
            if ($row->[7] == -1) {
                $self->{databases}->{ $row->[0] }->{$row->[3] . 'files'}->{limit} = 'unlimited';
            }
            if (defined($self->{option_results}->{check_underlying_disk})) {
                # look for the drives
                foreach my $drive_name (keys %$drives) {
                    if ($row->[2] =~ /^$drive_name/) {
                        if (($row->[7] > 0) && (($row->[7] * 8 * 1024) <= ($size + $drives->{$drive_name}))) {
                            $size = $row->[7] * 8 * 1024;
                        } elsif (!defined($unlimited_disk->{ $row->[0] . '_' . $row->[3] . 'files_' . $drive_name })) {
                            $size += $drives->{$drive_name};
                            $unlimited_disk->{ $row->[0] . '_' . $row->[3] . 'files_' . $drive_name } = 1;
                        }
                        last;
                    }
                }
            } elsif ($row->[7] > 0) {
                $size = $row->[7] * 8 * 1024;
            }
            $self->{databases}->{ $row->[0] }->{$row->[3] . 'files'}->{total_space} += $size;
        }
    }

    foreach my $dbname (keys %{$self->{databases}}) {
        foreach my $type (('data', 'log')) {
            my $options = [$type . 'files_maxsize'];
            unshift @$options, $type . 'files_maxsize_unlimited' if ($self->{databases}->{$dbname}->{$type . 'files'}->{limit} eq 'unlimited');
            foreach my $option (@$options) {
                if (defined($self->{option_results}->{$option}) && $self->{option_results}->{$option} ne '' &&
                    $self->{option_results}->{$option} =~ /(\d+)/) {
                    $self->{databases}->{$dbname}->{$type . 'files'}->{total_space} = $self->{option_results}->{$option} * 1024 * 1024;
                    $self->{databases}->{$dbname}->{$type . 'files'}->{limit} = 'overload';
                    last;
                }
            }

            $self->{databases}->{$dbname}->{$type . 'files'}->{free_space} = 
                $self->{databases}->{$dbname}->{$type . 'files'}->{total_space} - $self->{databases}->{$dbname}->{$type . 'files'}->{used_space};
            $self->{databases}->{$dbname}->{$type . 'files'}->{prct_used_space} = 
                $self->{databases}->{$dbname}->{$type . 'files'}->{used_space} * 100 / $self->{databases}->{$dbname}->{$type . 'files'}->{total_space};
            $self->{databases}->{$dbname}->{$type . 'files'}->{prct_free_space} = 100 - $self->{databases}->{$dbname}->{$type . 'files'}->{prct_used_space};
            $self->{databases}->{$dbname}->{$type . 'files'}->{prct_free_space} = 0 if ($self->{databases}->{$dbname}->{$type . 'files'}->{prct_free_space} < 0);
        }
    }
}

1;

__END__

=head1 MODE

Check database data and log files.

=over 8

=item B<--filter-database>

Filter database by name (Can be a regex).

=item B<--datafiles-maxsize>

Overload all data files max size (in MB).

=item B<--logfiles-maxsize>

Overload all log files max size (in MB).

=item B<--datafiles-maxsize-unlimited>

Overload only unlimited autogrowth data files max size (in MB).

=item B<--logfiles-maxsize-unlimited>

Overload only unlimited autogrowth log files max size (in MB).

=item B<--check-underlying-disk>

Check and consider underlying disk space for data and log files.

=item B<--ignore-unlimited>

Thresholds not applied on unlimited autogrowth data and log files.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'datafiles-space-usage', 'datafiles-space-usage-free', 'datafiles-space-usage-prct'
'logfiles-space-usage', 'logfiles-space-usage-free', 'logfiles-space-usage-prct'.

=back

=cut
