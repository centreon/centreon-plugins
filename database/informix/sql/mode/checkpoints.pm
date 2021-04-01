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

package database::informix::sql::mode::checkpoints;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
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
