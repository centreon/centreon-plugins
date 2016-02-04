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

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"           => { name => 'warning', },
                                  "critical:s"          => { name => 'critical', },
                                  "filter:s"            => { name => 'filter', },
                                  "skip:s"              => { name => 'skip', },
                                  "free"                => { name => 'free', },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{output}->output_add(severity => 'OK',
                                short_msg => "All tablespaces are ok.");

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

    foreach my $row (@$result) {
        my ($name, $status, $type, $extentmgmt, $bytes, $bytes_max, $bytes_free) = @$row;
        next if (defined($self->{option_results}->{filter}) && $name !~ /$self->{option_results}->{filter}/);
        next if (defined($self->{option_results}->{skip}) && $status =~ /offline/i);

        if (!defined($bytes)) {
            # seems corrupted, cannot get value
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => sprintf("tbs '%s' cannot get data", $name));
            next;
        }

        $status = lc $status;
        $type = lc $type;
        my ($percent_used, $percent_free, $used, $free, $size);
        if ($self->{sql}->is_version_minimum(version => '11')) {
            $percent_used = $bytes / $bytes_max * 100;
            $size = $bytes_max;
            $free = $bytes_max - $bytes;
            $used = $bytes;
        } elsif ((!defined($bytes_max)) || ($bytes_max == 0)) {
            $percent_used = ($bytes - $bytes_free) / $bytes * 100;
            $size = $bytes;
            $free = $bytes_free;
            $used = $size - $free;
        } else {
            $percent_used = ($bytes - $bytes_free) / $bytes_max * 100;
            $size = $bytes_max;
            $free = $bytes_free + ($bytes_max - $bytes);
            $used = $size - $free;
        }
        $percent_free = 100 - $percent_used;
        my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $used);
        my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $free);
        my ($size_value, $size_unit) = $self->{perfdata}->change_bytes(value => $size);
        $self->{output}->output_add(long_msg => sprintf("tbs '%s' Used: %.2f%s (%.2f%%) Free: %.2f%s (%.2f%%) Size: %.2f%s",
                                                        $name, $used_value, $used_unit, $percent_used, $free_value, $free_unit, $percent_free, $size_value, $size_unit));

        if (defined($self->{option_results}->{free})) {
            my $exit_code = $self->{perfdata}->threshold_check(value => $percent_free, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
            if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit_code,
                                            short_msg => sprintf("tbs '%s' Free: %.2f%s (%.2f%%) Size: %.2f%s", $name, $free_value, $free_unit, $percent_free, $size_value, $size_unit));
            }
            $self->{output}->perfdata_add(label => sprintf("tbs_%s_free",lc $name),
                                          unit => 'B',
                                          value => $free,
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $size, cast_int => 1),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $size, cast_int => 1),
                                          min => 0,
                                          max => $size);
        } else {
            my $exit_code = $self->{perfdata}->threshold_check(value => $percent_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
            if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit_code,
                                            short_msg => sprintf("tbs '%s' Used: %.2f%s (%.2f%%) Size: %.2f%s", $name, $used_value, $used_unit, $percent_used, $size_value, $size_unit));
            }
            $self->{output}->perfdata_add(label => sprintf("tbs_%s_usage",lc $name),
                                          unit => 'B',
                                          value => $used,
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $size, cast_int => 1),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $size, cast_int => 1),
                                          min => 0,
                                          max => $size);
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Oracle tablespaces usage.

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--filter>

Filter tablespace.

=item B<--skip>

Skip offline tablespaces.

=item B<--free>

Check free space instead of used space.

=back

=cut
