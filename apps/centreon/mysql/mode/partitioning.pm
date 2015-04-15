################################################################################
# Copyright 2005-2015 MERETHIS
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
# Authors : Simon Bomm <sbomm@merethis.com>
#
####################################################################################

package apps::centreon::mysql::mode::partitioning;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
#use Time::HiRes;
use Time::Local;
use POSIX;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "tablename:s"    => { name => 'tablename', default => 'data_bin' },
                                  "retentionforward:s"    => { name => 'retentionforward', default => '10' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{warn1} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
 
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();

    my @partitionedTables = split /,/, $self->{option_results}->{tablename};

    my($day, $month, $year) = (localtime)[3,4,5];
    $month = sprintf '%02d', $month+1;
    $day   = sprintf '%02d', $day;
    my $actualTime = timelocal(0,0,0,$day,$month-1,$year);
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All partitions are up to date"));

    #$self->{option_results}->{retentionforward}--;

    foreach my $table (@partitionedTables) {
         
         $self->{sql}->query(query => "SELECT TABLE_NAME,PARTITION_NAME FROM information_schema.PARTITIONS WHERE TABLE_NAME='".$table."' ORDER BY PARTITION_NAME DESC LIMIT 1;");

         my ($tableName, $yyyymmdd) = $self->{sql}->fetchrow_array();
         $yyyymmdd =~ s/^.//;
         $self->{output}->output_add(long_msg => sprintf("Table %s last partition date is %s", $tableName, $yyyymmdd));
         
         my ($partY, $partM, $partD) = $yyyymmdd =~ /^(\d{4})(\d{2})(\d{2})\z/;
          
         my $partTime = timelocal(0,0,0,$partD,$partM-1,$partY);
         if ($partTime < $actualTime + $self->{option_results}->{retentionforward} * 86400) {
             $self->{output}->output_add(severity => 'CRITICAL',
                                         short_msg => sprintf("Partitions for table %s are not up to date (%s)",$tableName, $yyyymmdd));
         }
                      
    }

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check that partitions for MySQL/MariaDB tables are correctly created
The mode should be used with mysql plugin and dyn-mode option.

=over 8

=item B<--tablename>

This option is not mandatory, you can specify one or several table names separated by comma, default value is 'data_bin'

=item B<--retentionforward>

This option must be set accordingly to the number of days of retention forward value in centreon-partioning config file. This value will determine when a CRITICAL would be triggered for missing partitions. Default is 10

=back

=cut
