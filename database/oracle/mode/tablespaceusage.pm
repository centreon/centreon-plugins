################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Stephane Duret <sduret@merethis.com>
#
####################################################################################

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
    if ($self->{sql}->is_version_minimum(version => '9')) {
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
                    SUM(DECODE(a.autoextensible, 'YES', a.maxbytes, 'NO', a.bytes)) maxbytes
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
        if ((!defined($bytes_max)) || ($bytes_max == 0)) {
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
