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

package database::oracle::mode::listtablespaces;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $order = ['name', 'total', 'free', 'used', 'prct_used', 'type', 'status'];

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-tablespace:s' => { name => 'filter_tablespace' },
        'notemp'              => { name => 'notemp' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();

    # request from check_oracle_health.
    my $query;
    if ($options{sql}->is_version_minimum(version => '11')) {
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
    } elsif ($options{sql}->is_version_minimum(version => '9')) {
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
            defined($self->{option_results}->{notemp}) ?  $tbs_sql_undo_empty : $tbs_sql_undo,
            defined($self->{option_results}->{notemp}) ?  "AND (b.contents != 'TEMPORARY' AND b.contents != 'UNDO')" : '',
            defined($self->{option_results}->{notemp}) ?   "" : $tbs_sql_temp
        );
    } elsif ($options{sql}->is_version_minimum(version => '8')) {
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
    $options{sql}->query(query => $query);
    my $result = $options{sql}->fetchall_arrayref();

    my $tablespaces = {};
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
        if ($options{sql}->is_version_minimum(version => '11')) {
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

        $tablespaces->{$name} = { 
            used => $used,
            free => $free,
            total => $size,
            prct_used => $percent_used,
            name => $name,
            type => $type,
            status => $status
        };
    }

    $options{sql}->disconnect();
    return $tablespaces;
}

sub run {
    my ($self, %options) = @_;

    my $tablespaces = $self->manage_selection(%options);
    foreach (sort keys %$tablespaces) {
        my $entry = '';
        foreach my $label (@$order) {
            $entry .= '[' . $label . ' = ' . $tablespaces->{$_}->{$label} . '] ';
        }
        $self->{output}->output_add(long_msg => $entry);
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List tablespaces:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => $order);
}

sub disco_show {
    my ($self, %options) = @_;

    my $tablespaces = $self->manage_selection(%options);
    foreach (sort keys %$tablespaces) {
        $self->{output}->add_disco_entry(%{$tablespaces->{$_}});
    }
}

1;

__END__

=head1 MODE

List oracle tablespaces.

=over 8

=item B<--filter-tablespace>

Filter tablespace by name. Can be a regex.

=item B<--notemp>

skip temporary or undo tablespaces.

=back

=cut
