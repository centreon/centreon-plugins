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

package database::oracle::mode::tablespaceusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'tablespace', type => 1, cb_prefix_output => 'prefix_tablespace_output', message_multiple => 'All tablespaces are OK' },
    ];

    $self->{maps_counters}->{tablespace} = [
        { label => 'tablespace', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_calc => \&custom_usage_calc,
                closure_custom_output => \&custom_usage_output,
                closure_custom_perfdata => \&custom_usage_perfdata,
                closure_custom_threshold_check => \&custom_usage_threshold,
            }
        },
    ];
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'tbs_' . $self->{result_values}->{display} . '_usage';
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        $label = 'tbs_' . $self->{result_values}->{display} . '_free';
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{prct_used} = $options{new_datas}->{$self->{instance} . '_prct_used'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_free'};

    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-tablespace:s' => { name => 'filter_tablespace' },
        'units:s'             => { name => 'units', default => '%' },
        'free'                => { name => 'free' },
        'skip'                => { name => 'skip' },
        'notemp'              => { name => 'notemp' },
        'add-container'       => { name => 'add_container' },
    });

    return $self;
}

sub prefix_tablespace_output {
    my ($self, %options) = @_;

    return "Tablespace '" . $options{instance_value}->{display} . "' ";
}

sub manage_container {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_container}));

    # request from check_oracle_health.
    return if (!$self->{sql}->is_version_minimum(version => '9'));
    
    my $tbs_sql_undo = q{
        -- freier platz durch expired extents
        -- speziell fuer undo tablespaces
        -- => bytes_expired
        SELECT
            tablespace_name, bytes_expired, con_id
        FROM
            (
                SELECT
                    tablespace_name,
                    SUM (bytes) bytes_expired,
                    status,
                    con_id
                FROM
                    cdb_undo_extents
                GROUP BY
                    con_id, tablespace_name, status
            )
        WHERE
            status = 'EXPIRED'
    };
    my $tbs_sql_undo_empty = q{
        SELECT NULL AS tablespace_name, NULL AS bytes_expired, NULL AS con_id FROM DUAL
    };
    my $tbs_sql_temp = q{
        UNION ALL
        SELECT
            e.name||'_'||b.tablespace_name "Tablespace",
            b.status "Status",
            b.contents "Type",
            b.extent_management "Extent Mgmt",
            sum(a.bytes_free + a.bytes_used) bytes,   -- allocated
            SUM(DECODE(d.autoextensible, 'YES', d.maxbytes, 'NO', d.bytes)) bytes_max,
            SUM(a.bytes_free + a.bytes_used - NVL(c.bytes_used, 0)) bytes_free
        FROM
            sys.v_$TEMP_SPACE_HEADER a, -- has con_id
            sys.cdb_tablespaces b, -- has con_id
            sys.v_$Temp_extent_pool c,
            cdb_temp_files d, -- has con_id
            v$containers e
        WHERE
            a.file_id = c.file_id(+)
            AND a.file_id = d.file_id
            AND a.tablespace_name = c.tablespace_name(+)
            AND a.tablespace_name = d.tablespace_name
            AND a.tablespace_name = b.tablespace_name
            AND a.con_id = c.con_id(+)
            AND a.con_id = d.con_id
            AND a.con_id = b.con_id
            AND a.con_id = e.con_id
        GROUP BY
            e.name,
            b.con_id,
            b.status,
            b.contents,
            b.extent_management,
            b.tablespace_name
        ORDER BY
            1
    };

    my $query = sprintf(
        q{
            SELECT /*+ opt_param('optimizer_adaptive_features','false') */
                e.name||'_'||a.tablespace_name         "Tablespace",
                b.status                  "Status",
                b.contents                "Type",
                b.extent_management       "Extent Mgmt",
                a.bytes                   bytes,
                a.maxbytes                bytes_max,
                c.bytes_free + NVL(d.bytes_expired,0)             bytes_free
            FROM
              (
                -- belegter und maximal verfuegbarer platz pro datafile
                -- nach tablespacenamen zusammengefasst
                -- => bytes
                -- => maxbytes
                SELECT
                    a.con_id,
                    a.tablespace_name,
                    SUM(a.bytes)          bytes,
                    SUM(DECODE(a.autoextensible, 'YES', a.maxbytes, 'NO', a.bytes)) maxbytes
                FROM
                    cdb_data_files a
                GROUP BY
                    con_id, tablespace_name
              ) a,
              sys.cdb_tablespaces b,
              (
                -- freier platz pro tablespace
                -- => bytes_free
                SELECT
                    a.con_id,
                    a.tablespace_name,
                    SUM(a.bytes) bytes_free
                FROM
                    cdb_free_space a
                GROUP BY
                    con_id, tablespace_name
              ) c,
              (
                %s
              ) d,
              v$containers e
            WHERE
                a.tablespace_name = c.tablespace_name (+)
                AND a.tablespace_name = b.tablespace_name
                AND a.tablespace_name = d.tablespace_name (+)
                AND a.con_id = c.con_id(+)
                AND a.con_id = b.con_id
                AND a.con_id = d.con_id(+)
                AND a.con_id = e.con_id
                %s
            %s
        }, 
        defined($self->{option_results}->{notemp}) ? $tbs_sql_undo_empty : $tbs_sql_undo,
        defined($self->{option_results}->{notemp}) ? "AND (b.contents != 'TEMPORARY' AND b.contents != 'UNDO')" : '',
        defined($self->{option_results}->{notemp}) ?  "" : $tbs_sql_temp
    );

    $self->{sql}->query(query => $query);
    my $result = $self->{sql}->fetchall_arrayref();

    foreach my $row (@$result) {
        my ($name, $status, $type, $extentmgmt, $bytes, $bytes_max, $bytes_free) = @$row;

        if (defined($self->{option_results}->{notemp}) && ($type eq 'UNDO' || $type eq 'TEMPORARY')) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': temporary or undo.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_tablespace}) && $self->{option_results}->{filter_tablespace} ne '' &&
            $name !~ /$self->{option_results}->{filter_tablespace}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        if (!defined($bytes)) {
            # seems corrupted, cannot get value
            $self->{output}->output_add(long_msg => sprintf("tbs '%s' cannot get data", $name), debug => 1);
            next;
        }
        if (defined($self->{option_results}->{skip}) && $status eq 'OFFLINE')  {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': tbs is offline", debug => 1);
            next;
        }

        my ($percent_used, $percent_free, $used, $free, $size);
        if ((!defined($bytes_max)) || ($bytes_max eq '')) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': bytes max not defined.", debug => 1);
            next;
        } elsif ($bytes_max > $bytes) {
            $percent_used = ($bytes - $bytes_free) / $bytes_max * 100;
            $size = $bytes_max;
            $free = $bytes_free + ($bytes_max - $bytes);
            $used = $size - $free;
        } else {
            $percent_used = ($bytes - $bytes_free) / $bytes * 100;
            $size = $bytes;
            $free = $bytes_free;
            $used = $size - $free;
        }

        $self->{tablespace}->{$name} = { 
            used => $used,
            free => $free,
            total => $size,
            prct_used => $percent_used,
            display => lc($name)
        };
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{sql} = $options{sql};
    $self->{sql}->connect();
    
    # request from check_oracle_health.
    my $query;
    if ($self->{sql}->is_version_minimum(version => '11')) {
         $query = sprintf(
            q{
             SELECT
              tum.tablespace_name "Tablespace",
              t.status "Status",
              t.contents "Type",
              t.extent_management "Extent Mgmt",
              tum.used_space*t.block_size bytes,
              tum.tablespace_size*t.block_size bytes_max
             FROM
              DBA_TABLESPACE_USAGE_METRICS tum
             INNER JOIN
              dba_tablespaces t on tum.tablespace_name=t.tablespace_name
             %s
            },
            defined($self->{option_results}->{notemp}) ? 
                "WHERE (t.contents != 'TEMPORARY' AND t.contents != 'UNDO')" : 
                ''
        );
    } elsif ($self->{sql}->is_version_minimum(version => '9')) {
        my $tbs_sql_undo = q{
            SELECT
                tablespace_name, bytes_expired
            FROM
                (
                    SELECT
                        a.tablespace_name,
                        SUM (a.bytes) bytes_expired,
                        a.status
                    FROM
                        dba_undo_extents a
                    GROUP BY
                        tablespace_name, status
                )
            WHERE
                status = 'EXPIRED'
        };
        my $tbs_sql_undo_empty = q{
            SELECT NULL AS tablespace_name, NULL AS bytes_expired FROM DUAL
        };
        my $tbs_sql_temp = q{
            UNION ALL
            SELECT
                d.tablespace_name "Tablespace",
                b.status "Status",
                b.contents "Type",
                b.extent_management "Extent Mgmt",
                sum(a.bytes_free + a.bytes_used) bytes,   -- allocated
                SUM(DECODE(d.autoextensible, 'YES', d.maxbytes, 'NO', d.bytes)) bytes_max,
                SUM(a.bytes_free + a.bytes_used - NVL(c.bytes_used, 0)) bytes_free
            FROM
                sys.v_$TEMP_SPACE_HEADER a,
                sys.dba_tablespaces b,
                sys.v_$Temp_extent_pool c,
                dba_temp_files d
            WHERE
                c.file_id(+)             = a.file_id
                and c.tablespace_name(+) = a.tablespace_name
                and d.file_id            = a.file_id
                and d.tablespace_name    = a.tablespace_name
                and b.tablespace_name    = a.tablespace_name
            GROUP BY
                b.status,
                b.contents,
                b.extent_management,
                d.tablespace_name
            ORDER BY
                1
        };

        $query = sprintf(
            q{
                SELECT /*+ opt_param('optimizer_adaptive_features','false') */
                    a.tablespace_name         "Tablespace",
                    b.status                  "Status",
                    b.contents                "Type",
                    b.extent_management       "Extent Mgmt",
                    a.bytes                   bytes,
                    a.maxbytes                bytes_max,
                    c.bytes_free + NVL(d.bytes_expired,0)             bytes_free
                FROM
                  (
                    -- belegter und maximal verfuegbarer platz pro datafile
                    -- nach tablespacenamen zusammengefasst
                    -- => bytes
                    -- => maxbytes
                    SELECT
                        a.tablespace_name,
                        SUM(a.bytes)          bytes,
                        SUM(DECODE(a.autoextensible, 'YES', a.maxbytes, 'NO', a.bytes)) maxbytes
                    FROM
                        dba_data_files a
                    GROUP BY
                        tablespace_name
                  ) a,
                  sys.dba_tablespaces b,
                  (
                    -- freier platz pro tablespace
                    -- => bytes_free
                    SELECT
                        a.tablespace_name,
                        SUM(a.bytes) bytes_free
                    FROM
                        dba_free_space a
                    GROUP BY
                        tablespace_name
                  ) c,
                  (
                    %s
                  ) d
                WHERE
                    a.tablespace_name = c.tablespace_name (+)
                    AND a.tablespace_name = b.tablespace_name
                    AND a.tablespace_name = d.tablespace_name (+)
                    %s
                %s
            }, 
            defined($self->{option_results}->{notemp}) ? $tbs_sql_undo_empty : $tbs_sql_undo,
            defined($self->{option_results}->{notemp}) ? "AND (b.contents != 'TEMPORARY' AND b.contents != 'UNDO')" : '',
            defined($self->{option_results}->{notemp}) ? "" : $tbs_sql_temp
        );
    } elsif ($self->{sql}->is_version_minimum(version => '8')) {
        $query = q{SELECT
                a.tablespace_name         "Tablespace",
                b.status                  "Status",
                b.contents                "Type",
                b.extent_management       "Extent Mgmt",
                a.bytes                   bytes,
                a.maxbytes                bytes_max,
                c.bytes_free              bytes_free
            FROM
              (
                -- belegter und maximal verfuegbarer platz pro datafile
                -- nach tablespacenamen zusammengefasst
                -- => bytes
                -- => maxbytes
                SELECT
                    a.tablespace_name,
                    SUM(a.bytes)          bytes,
                    SUM(DECODE(a.autoextensible, 'YES', a.maxbytes, 'NO', a.bytes)) maxbytes
                FROM
                    dba_data_files a
                GROUP BY
                    tablespace_name
              ) a,
              sys.dba_tablespaces b,
              (
                -- freier platz pro tablespace
                -- => bytes_free
                SELECT
                    a.tablespace_name,
                    SUM(a.bytes) bytes_free
                FROM
                    dba_free_space a
                GROUP BY
                    tablespace_name
              ) c
            WHERE
                a.tablespace_name = c.tablespace_name (+)
                AND a.tablespace_name = b.tablespace_name
                AND (b.contents = 'PERMANENT'
                OR (b.contents <> 'PERMANENT'
                AND a.tablespace_name=(select value from v$parameter where name='undo_tablespace')))
            UNION ALL
            SELECT
                a.tablespace_name "Tablespace",
                b.status "Status",
                b.contents "Type",
                b.extent_management "Extent Mgmt",
                sum(a.bytes_free + a.bytes_used) bytes,   -- allocated
                d.maxbytes bytes_max,
                SUM(a.bytes_free + a.bytes_used - NVL(c.bytes_used, 0)) bytes_free
            FROM
                sys.v_$TEMP_SPACE_HEADER a,
                sys.dba_tablespaces b,
                sys.v_$Temp_extent_pool c,
                dba_temp_files d
            WHERE
                c.file_id(+)             = a.file_id
                and c.tablespace_name(+) = a.tablespace_name
                and d.file_id            = a.file_id
                and d.tablespace_name    = a.tablespace_name
                and b.tablespace_name    = a.tablespace_name
            GROUP BY
                a.tablespace_name,
                b.status,
                b.contents,
                b.extent_management,
                d.maxbytes
            ORDER BY
                1
        };
    } else {
        $query = q{
            SELECT
                a.tablespace_name         "Tablespace",
                b.status                  "Status",
                b.contents                "Type",
                'DICTIONARY'              "Extent Mgmt",
                a.bytes                   bytes,
                a.maxbytes                bytes_max,
                c.bytes_free              bytes_free
            FROM
              (
                -- belegter und maximal verfuegbarer platz pro datafile
                -- nach tablespacenamen zusammengefasst
                -- => bytes
                -- => maxbytes
                SELECT
                    a.tablespace_name,
                    SUM(a.bytes)          bytes,
                    SUM(a.bytes) maxbytes
                FROM
                    dba_data_files a
                GROUP BY
                    tablespace_name
              ) a,
              sys.dba_tablespaces b,
              (
                -- freier platz pro tablespace
                -- => bytes_free
                SELECT
                    a.tablespace_name,
                    SUM(a.bytes) bytes_free
                FROM
                    dba_free_space a
                GROUP BY
                    tablespace_name
              ) c
            WHERE
                a.tablespace_name = c.tablespace_name (+)
                AND a.tablespace_name = b.tablespace_name
        };
    }
    $self->{sql}->query(query => $query);
    my $result = $self->{sql}->fetchall_arrayref();

    $self->{tablespace} = {};
    foreach my $row (@$result) {
        my ($name, $status, $type, $extentmgmt, $bytes, $bytes_max, $bytes_free) = @$row;

        if (defined($self->{option_results}->{notemp}) && ($type eq 'UNDO' || $type eq 'TEMPORARY')) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': temporary or undo.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_tablespace}) && $self->{option_results}->{filter_tablespace} ne '' &&
            $name !~ /$self->{option_results}->{filter_tablespace}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        if (!defined($bytes)) {
            # seems corrupted, cannot get value
            $self->{output}->output_add(long_msg => sprintf("tbs '%s' cannot get data", $name), debug => 1);
            next;
        }
        if (defined($self->{option_results}->{skip}) && $status eq 'OFFLINE')  {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': tbs is offline", debug => 1);
            next;
        }

        my ($percent_used, $percent_free, $used, $free, $size);
        if ($self->{sql}->is_version_minimum(version => '11')) {
            $percent_used = $bytes / $bytes_max * 100;
            $size = $bytes_max;
            $free = $bytes_max - $bytes;
            $used = $bytes;
        } elsif ((!defined($bytes_max)) || ($bytes_max eq '')) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': bytes max not defined.", debug => 1);
            next;
        } elsif ($bytes_max > $bytes) {
            $percent_used = ($bytes - $bytes_free) / $bytes_max * 100;
            $size = $bytes_max;
            $free = $bytes_free + ($bytes_max - $bytes);
            $used = $size - $free;
        } else {
            $percent_used = ($bytes - $bytes_free) / $bytes * 100;
            $size = $bytes;
            $free = $bytes_free;
            $used = $size - $free;
        }

        $self->{tablespace}->{$name} = { 
            used => $used,
            free => $free,
            total => $size,
            prct_used => $percent_used,
            display => lc($name)
        };
    }

    $self->manage_container();
    $self->{sql}->disconnect();

    if (scalar(keys %{$self->{tablespace}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No tablespaces found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Oracle tablespaces usage.

=over 8

=item B<--warning-tablespace>

Threshold warning.

=item B<--critical-tablespace>

Threshold critical.

=item B<--filter-tablespace>

Filter tablespace by name. Can be a regex

=item B<--units>

Default is '%', can be 'B'

=item B<--free>

Perfdata show free space

=item B<--notemp>

skip temporary or undo tablespaces.

=item B<--add-container>

Add tablespaces of container databases.

=item B<--skip>

Skip offline tablespaces.

=back

=cut
