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
# Authors : Quentin Delance <qdelance@merethis.com>
#
####################################################################################

package database::postgres::mode::vacuum;

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
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
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
    if (($self->{perfdata}->threshold_validate(label => 'dbname', value => $self->{option_results}->{dbname})) eq 'postgres') {
       $self->{output}->add_option_msg(short_msg => "Invalid db.");
       $self->{output}->option_exit();
    }

    
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    # Ensures a DB has been specified
    # otherwise we endup in default system table (postgres)
    # and the check does not support this behaviour (empty pg_stat_user_table => no need to check)
    # FIXME this check should be performed in check_options() but these settings are not available at the moment
    my $data_source = $self->{sql}->{data_source};
    if ($data_source =~ /.*;database=(.*)/) {
       if ($1 eq 'postgres') {
          $self->{output}->add_option_msg(short_msg => "Cannot use system 'postgres' database ; you must use a real database.");
          $self->{output}->option_exit();
       } elsif ($1 eq '') {
          $self->{output}->add_option_msg(short_msg => "Database must be specified.");
          $self->{output}->option_exit();
       }
    } else { 
       $self->{output}->add_option_msg(short_msg => "Need to specify database argument.");
       $self->{output}->option_exit();
    }

    $self->{sql}->connect();
    
    my $target_fields = undef;

    # Autovacuum feature has only been impleted starting PG 8.2 
    # (options needed http://www.postgresql.org/docs/8.2/static/runtime-config-autovacuum.html, no need starting 8.3)
    if ($self->{sql}->is_version_minimum(version => '8.2.0')) {
        $target_fields = 'greatest(last_autovacuum,last_vacuum)';
    } else {
        $target_fields = 'last_vacuum';
    }

    my $query = sprintf("SELECT ROUND(EXTRACT(EPOCH from (select min (now() - %s) 
                 from pg_stat_user_tables where %s is not null)))", $target_fields, $target_fields);
    $self->{sql}->query(query => $query);

    my $result = $self->{sql}->fetchrow_array();
    
    if (defined($result)) {
        
        my $exit_code = $self->{perfdata}->threshold_check(value => $result, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{output}->output_add(severity => $exit_code,
                                    short_msg => sprintf("Most recent vacuum dates back from %d seconds", $result));
        
        $self->{output}->perfdata_add(label => 'last_vacuum',
                                      value => $result,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));
    } else {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'No vacuum performed on this BD yet.');
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check a vacuum (manual or auto) command has been performed on at least one of the tables of the associated DB

=over 8

=item B<--warning>

Threshold warning in seconds, maximum time interval since last vacuum.

=item B<--critical>

Threshold critical in seconds, maximum time interval since last vacuum.

=back

=cut
