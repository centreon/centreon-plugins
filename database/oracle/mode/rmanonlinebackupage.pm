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

package database::oracle::mode::rmanonlinebackupage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use DateTime;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                  "timezone:s"              => { name => 'timezone', },
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
    
    if (defined($self->{option_results}->{timezone})) {
        $ENV{TZ} = $self->{option_results}->{timezone};
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    my $query = q{SELECT min(((time - date '1970-01-01') * 86400)) as last_time
                  FROM v$backup
                  WHERE STATUS='ACTIVE'
    };
    $self->{sql}->query(query => $query);
    my $result = $self->{sql}->fetchall_arrayref();

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("Backup online modes are ok."));

    foreach my $row (@$result) {
        next if (!defined($$row[0]));
        my $last_time = $$row[0];
        
        my @values = localtime($last_time);
        my $dt = DateTime->new(
                        year       => $values[5] + 1900,
                        month      => $values[4] + 1,
                        day        => $values[3],
                        hour       => $values[2],
                        minute     => $values[1],
                        second     => $values[0],
                        time_zone  => 'UTC',
        );
        my $offset = $last_time - $dt->epoch;
        $last_time = $last_time + $offset;
        
        my $launched = time() - $last_time;
        my $launched_convert = centreon::plugins::misc::change_seconds(value => $launched);
        $self->{output}->output_add(long_msg => sprintf("backup online mode since %s (%s)", $launched_convert, locatime($last_time)));
        my $exit_code = $self->{perfdata}->threshold_check(value => $launched, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("backup online mode since %s (%s)", $launched_convert, locatime($last_time)));
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Oracle backup online mode.

=over 8

=item B<--warning>

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=item B<--timezone>

Timezone of oracle server (If not set, we use current server execution timezone)

=back

=cut
