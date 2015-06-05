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
# Authors : Kevin Duret <kduret@merethis.com>
#
####################################################################################

package apps::jive::sql::mode::etljobstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $thresholds = {
    status => [
        ['^1$', 'OK'],
        ['^3$', 'CRITICAL'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "retention:s"             => { name => 'retention', default => 1 },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ('status', $1, $2);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    my $retention = $self->{option_results}->{retention};
    # CURRENT_TIMESTAMP should be compatible with the jive databases: Oracle, MS SQL, MySQL, Postgres.
    # INTERVAL also.
    my $query = q{SELECT etl_job_id, state, start_ts, end_ts FROM jivedw_etl_job WHERE start_ts > CURRENT_TIMESTAMP -  INTERVAL '} . $retention . q{' DAY};
    $self->{sql}->query(query => $query);
    my $job_etl_problems = {};
    my $total_problems = 0;
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        my $exit = $self->get_severity(section => 'status', value => $row->{state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(long_msg => sprintf("%s: job '%i' state is %s [start_time: %s]", $exit, $row->{etl_job_id}, $row->{state}, $row->{start_ts}));
            $job_etl_problems->{$exit} = 0 if (!defined($job_etl_problems->{$exit}));
            $job_etl_problems->{$exit}++;
            $total_problems++;
         }
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'no job etl problems');
    foreach (keys %{$job_etl_problems}) {
        $self->{output}->output_add(severity => $_,
                                    short_msg => sprintf("job etl had %i problems during the last %i days", $job_etl_problems->{$_}, $self->{option_results}->{retention}));
    }
    
    $self->{output}->perfdata_add(label => 'job_etl_problems',
                                  value => $total_problems,
                                  min => 0);

    $self->{output}->display();
    $self->{output}->exit();
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

1;

__END__

=head1 MODE

Check jive ETL job status.
Please use with dyn-mode option.

=over 8

=item B<--retention>

Retention in days (default : 1).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='CRITICAL,^(?!(1)$)'

=back

=cut
