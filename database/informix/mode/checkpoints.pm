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

package database::informix::mode::checkpoints;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning-cp:s"          => { name => 'warning_cp', },
                                  "critical-cp:s"         => { name => 'critical_cp', },
                                  "warning-flush:s"       => { name => 'warning_flush', },
                                  "critical-flush:s"      => { name => 'critical_flush', },
                                  "warning-crit:s"        => { name => 'warning_crit', },
                                  "critical-crit:s"       => { name => 'critical_crit', },
                                  "warning-block:s"       => { name => 'warning_block', },
                                  "critical-block:s"      => { name => 'critical_block', },
                                  "filter-trigger:s"      => { name => 'filter_trigger', },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning-cp', value => $self->{option_results}->{warning_cp})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-cp threshold '" . $self->{option_results}->{warning_cp} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-cp', value => $self->{option_results}->{critical_cp})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-cp threshold '" . $self->{option_results}->{critical_cp} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-flush', value => $self->{option_results}->{warning_flush})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-flush threshold '" . $self->{option_results}->{warning_flush} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-flush', value => $self->{option_results}->{critical_flush})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-flush threshold '" . $self->{option_results}->{critical_flush} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-crit', value => $self->{option_results}->{warning_crit})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-crit threshold '" . $self->{option_results}->{warning_crit} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-crit', value => $self->{option_results}->{critical_crit})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-crit threshold '" . $self->{option_results}->{critical_crit} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-block', value => $self->{option_results}->{warning_block})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-block threshold '" . $self->{option_results}->{warning_block} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-block', value => $self->{option_results}->{critical_block})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-block threshold '" . $self->{option_results}->{critical_block} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    
    $self->{sql}->query(query => q{
    SELECT intvl, caller, cp_time, block_time, flush_time, crit_time FROM syscheckpoint
});
    $self->{output}->output_add(severity => 'OK',
                                short_msg => "All checkpoint times are ok.");
    my $count = 0;
    while ((my $row = $self->{sql}->fetchrow_hashref())) {    
        my $id = $row->{intvl};
        my $name = centreon::plugins::misc::trim($row->{caller});
        my ($cp_time, $block_time, $flush_time, $crit_time) = ($row->{cp_time}, $row->{block_time}, $row->{flush_time}, $row->{crit_time}); 
        
        next if (defined($self->{option_results}->{filter_trigger}) && $name !~ /$self->{option_results}->{filter_trigger}/);
        
        $count++;
        my $exit1 = $self->{perfdata}->threshold_check(value => $cp_time, threshold => [ { label => 'critical-cp', 'exit_litteral' => 'critical' }, { label => 'warning-cp', exit_litteral => 'warning' } ]);
        my $exit2 = $self->{perfdata}->threshold_check(value => $block_time, threshold => [ { label => 'critical-block', 'exit_litteral' => 'critical' }, { label => 'warning-block', exit_litteral => 'warning' } ]);
        my $exit3 = $self->{perfdata}->threshold_check(value => $flush_time, threshold => [ { label => 'critical-flush', 'exit_litteral' => 'critical' }, { label => 'warning-flush', exit_litteral => 'warning' } ]);
        my $exit4 = $self->{perfdata}->threshold_check(value => $crit_time, threshold => [ { label => 'critical-crit', 'exit_litteral' => 'critical' }, { label => 'warning-crit', exit_litteral => 'warning' } ]);
        my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2, $exit3, $exit4 ]);
        
        $self->{output}->output_add(long_msg => sprintf("Checkpoint %s %s : Total Time %.4f, Block Time %.4f, Flush Time %.4f, Ckpt Time %.4f", 
                                                        $name, $id, $cp_time, $block_time, $flush_time, $crit_time)
                                    );
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Checkpoint %s %s : Total Time %.4f, Block Time %.4f, Flush Time %.4f, Ckpt Time %.4f", 
                                                             $name, $id, $cp_time, $block_time, $flush_time, $crit_time)
                                        );
        }
        $self->{output}->perfdata_add(label => 'cp_' . $name . "_" . $id,
                                      value => sprintf("%.4f", $cp_time),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_cp'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_cp'),
                                      min => 0);
        $self->{output}->perfdata_add(label => 'block_' . $name . "_" . $id,
                                      value => sprintf("%.4f", $block_time),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_block'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_block'),
                                      min => 0);
        $self->{output}->perfdata_add(label => 'flush_' . $name . "_" . $id,
                                      value => sprintf("%.4f", $flush_time),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_flush'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_flush'),
                                      min => 0);
        $self->{output}->perfdata_add(label => 'crit_' . $name . "_" . $id,
                                      value => sprintf("%.4f", $crit_time),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_crit'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_crit'),
                                      min => 0);
    }
    
    if ($count == 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => "Cannot find checkpoints (maybe the --name filter option).");
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Informix Checkpoints. 4 values:
- cp_time: Total checkpoint duration from request time to checkpoint completion.
- flush_time: Time taken to flush all the bufferpools.
- crit_time: This is the amount of time it takes for all transactions to recognize a checkpoint has been requested.
- block_time: Transaction blocking time.

=over 8

=item B<--warning-cp>

Threshold warning 'cp_time' in seconds.

=item B<--critical-cp>

Threshold critical 'cp_time' in seconds.

=item B<--warning-flush>

Threshold warning 'flush_time' in seconds.

=item B<--critical-flush>

Threshold critical 'flush_time' in seconds.

=item B<--warning-crit>

Threshold warning 'crit_time' in seconds.

=item B<--critical-crit>

Threshold critical 'crit_time' in seconds.

=item B<--warning-block>

Threshold warning 'block_time' in seconds.

=item B<--critical-block>

Threshold critical 'block_time' in seconds.

=item B<--filter-trigger>

Filter events that can trigger a checkpoint with a regexp.

=back

=cut
