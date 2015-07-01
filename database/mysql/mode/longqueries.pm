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
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package database::mysql::mode::longqueries;

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
                                  "seconds:s"           => { name => 'seconds', default => 60 },
                                  "filter-user:s"       => { name => 'filter_user' },
                                  "filter-command:s"    => { name => 'filter_command', default => '^(?!(sleep)$)' },
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
    if (!defined($self->{option_results}->{seconds}) || $self->{option_results}->{seconds} !~ /^[0-9]+$/) {
        $self->{output}->add_option_msg(short_msg => "Please set the option --seconds.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    
    $self->{sql}->query(query => q{SELECT USER, COMMAND, TIME, INFO FROM information_schema.processlist ORDER BY TIME DESC});
    my $long_queries = 0;
    my @queries = ();
    
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        next if (defined($self->{option_results}->{filter_user}) && $self->{option_results}->{filter_user} ne '' &&
                 $row->{USER} !~ /$self->{option_results}->{filter_user}/i);
        next if (defined($self->{option_results}->{filter_command}) && $self->{option_results}->{filter_command} ne '' &&
                 $row->{COMMAND} !~ /$self->{option_results}->{filter_command}/i);
        if (defined($self->{option_results}->{seconds}) && $self->{option_results}->{seconds} ne '' && $row->{TIME} >= $self->{option_results}->{seconds}) {
            push @queries, { time => $row->{TIME}, query => $row->{INFO} };
            $long_queries++;
        }
    }
    
    my $exit_code = $self->{perfdata}->threshold_check(value => $long_queries, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    
    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("%s queries over %s seconds",
                                                     $long_queries, $self->{option_results}->{seconds}));
    $self->{output}->perfdata_add(label => 'longqueries',
                                  value => $long_queries,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);
    
    for (my $i = 0; $i < 10 && $i < scalar(@queries); $i++) {
        $queries[$i]->{query} =~ s/\|/-/mg;
        $self->{output}->output_add(long_msg => sprintf("[time: %s] [query: %s]",
                                                        $queries[$i]->{time}, substr($queries[$i]->{query}, 0, 1024)));
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check current number of long queries.

=over 8

=item B<--warning>

Threshold warning (number of long queries).

=item B<--critical>

Threshold critical (number of long queries).

=item B<--critical>

Threshold critical (number of long queries).

=item B<--filter-user>

Filter by user (can be a regexp).

=item B<--filter-command>

Filter by command (can be a regexp. Default: '^(?!(sleep)$)').

=back

=cut
