#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{max_absolute});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_absolute});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_absolute});

    my $msg = sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                      $total_size_value . " " . $total_size_unit,
                      $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_absolute},
                      $total_free_value . " " . $total_free_unit, 100 - $self->{result_values}->{prct_used_absolute});
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'tablespace', type => 1, cb_prefix_output => 'prefix_tablespace_output', message_multiple => 'All tablespaces are OK' },
    ];

    $self->{maps_counters}->{tablespace} = [
        { label => 'tablespace', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'max' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                threshold_use => 'prct_used_absolute',
                perfdatas => [
                    { label => 'used', value => 'used_absolute', template => '%s',
                      unit => 'B', min => 0, max => 'max_absolute', label_extra_instance => 1, instance_use => 'display_absolute' },
                    { label => 'free', value => 'free_absolute', template => '%s',
                      unit => 'B', min => 0, max => 'max_absolute', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "filter-tablespace:s" => { name => 'filter_tablespace' },
                                "skip"                => { name => 'skip' },
                                });
    return $self;
}

sub prefix_tablespace_output {
    my ($self, %options) = @_;

    return "Tablespace '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};
    $self->{sql}->connect();

    my $query;
    if ($self->{sql}->is_version_minimum(version => '11')) {
        $query = q{
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
            WHERE
              t.contents<>'UNDO'
              OR (t.contents='UNDO' AND t.tablespace_name =(SELECT value FROM v$parameter WHERE name='undo_tablespace'))
        };
    } elsif ($self->{sql}->is_version_minimum(version => '9')) {
        $query = q{
            SELECT
                a.tablespace_name         "Tablespace",
                b.status                  "Status",
                b.contents                "Type",
                b.extent_management       "Extent Mgmt",
                a.bytes                   bytes,
                a.maxbytes                bytes_max,
                c.bytes_free + NVL(d.bytes_expired,0)             bytes_free
            FROM
              (
                SELECT
                    a.tablespace_name,
                    SUM(a.bytes)          bytes,
                    SUM(DECODE(a.autoextensible, 'YES', CASE WHEN (a.bytes > a.maxbytes) THEN 0 ELSE a.maxbytes END, 'NO', a.bytes)) maxbytes
                FROM
                    dba_data_files a
                GROUP BY
                    tablespace_name
              ) a,
              sys.dba_tablespaces b,
              (
                SELECT
                    a.tablespace_name,
                    SUM(a.bytes) bytes_free
                FROM
                    dba_free_space a
                GROUP BY
                    tablespace_name
              ) c,
              (
                SELECT
                    a.tablespace_name,
                    SUM(a.bytes) bytes_expired
                FROM
                    dba_undo_extents a
                WHERE
                    status = 'EXPIRED'
                GROUP BY
                    tablespace_name
              ) d
            WHERE
                a.tablespace_name = c.tablespace_name (+)
                AND a.tablespace_name = b.tablespace_name
                AND a.tablespace_name = d.tablespace_name (+)
                AND (b.contents = 'PERMANENT'
                OR (b.contents <> 'PERMANENT'
                AND a.tablespace_name=(select value from v$parameter where name='undo_tablespace')))
            UNION ALL
            SELECT
                d.tablespace_name "Tablespace",
                b.status "Status",
                b.contents "Type",
                b.extent_management "Extent Mgmt",
                sum(a.bytes_free + a.bytes_used) bytes,   -- allocated
                SUM(DECODE(d.autoextensible, 'YES', CASE WHEN (d.bytes > d.maxbytes) THEN 0 ELSE d.maxbytes END, 'NO', d.bytes)) bytes_max,
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
        $query = q{SELECT
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
        my ($name, $status, $type, $extentmgmt, $bytes, $bytes_max) = @$row;
        my $bytes_free = defined($bytes_max) ? $bytes_max - $bytes : -1;
        if (!defined($bytes)) {
            # seems corrupted, cannot get value
            $self->{output}->output_add(long_msg => sprintf("tbs '%s' cannot get data", $name), debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_tablespace}) && $self->{option_results}->{filter_tablespace} ne '' &&
            $name !~ /$self->{option_results}->{filter_tablespace}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{skip}) && $status eq 'OFFLINE')  {
            $self->{output}->output_add(long_msg => "Skipping  '" . $name . "': tbs is offline", debug => 1);
            next;
        }
        $self->{output}->output_add(long_msg => sprintf("tbs '%s' status '%s' type '%s' extent '%s' used:'%i' max:'%i'",
                                                        $name, $status, $type, $extentmgmt, $bytes, $bytes_max),
                                    debug => 1);
        if (!defined($bytes)) {
            # seems corrupted, cannot get value
            $self->{output}->output_add(long_msg => sprintf("tbs '%s' cannot get data", $name), debug => 1);
            next;
        }
        $self->{tablespace}->{$name} = { used => $bytes,
                                         free => $bytes_free,
                                         max => defined($bytes_max) ? $bytes_max : 0,
                                         prct_used => ($bytes/$bytes_max*100),
                                         display => $name };
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

=item B<--skip>

Skip offline tablespaces.

=back

=cut
