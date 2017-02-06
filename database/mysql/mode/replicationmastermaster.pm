#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package database::mysql::mode::replicationmastermaster;

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
}

sub check_replication {
    my ($self, %options) = @_;
    
    my ($master, $slave) = ($options{master}, $options{slave});
    
    my ($slave_status, $slave_status_error) = (0, "");
    my ($position_status, $position_status_error) = (0, "");
    
    my ($total_srv, $last_error);

    my ($io_thread_status_srv, $sql_thread_status_srv);
    if ($self->{$slave->get_id()}->{exit} != -1) {
        $slave->query(query => q{
            SHOW SLAVE STATUS
        });
        my $result = $slave->fetchrow_hashref();
        my $slave_io_running = $result->{Slave_IO_Running};
        my $slave_sql_running = $result->{Slave_SQL_Running};
        $last_error = $result->{Last_Error};
        
        if (defined($slave_io_running) && $slave_io_running =~ /^yes$/i) {
            $io_thread_status_srv = 0;
        } else {
            $io_thread_status_srv = 1;
        }
        if (defined($slave_sql_running) && $slave_sql_running =~ /^yes$/i) {
            $sql_thread_status_srv = 0;
        } else {
            $sql_thread_status_srv = 1;
        }
    } else {
        $io_thread_status_srv = 100;
        $sql_thread_status_srv = 100;
    }

    $total_srv = $io_thread_status_srv + $sql_thread_status_srv;
    
    # Check if a thread is down
    if ($total_srv == 1) {
        $slave_status = -1;
        $slave_status_error = "A Replication thread is down on '" . $slave->get_id() . "'.";
        if ($sql_thread_status_srv != 0) {
            if (defined($last_error) && $last_error ne "") {
                $slave_status = 1;
                $slave_status_error .= " SQL Thread is stopped because of an error (error='" . $last_error . "').";
            }
        }
    }
    
    # Check if we need to SKIP
    if ($io_thread_status_srv == 100) {
        $slave_status = -1;
        $slave_status_error .= " Skip check on '" . $slave->get_id() . "'.";
    }

    if ($total_srv > 1) {
        $slave_status = 1;
        $slave_status_error .= " not a slave '"  . $slave->get_id() . "' (maybe because we cannot check the server).";
    }
    
    ####
    # Check Slave position
    ####    
    if ($self->{$master->get_id()}->{exit} == -1) {
        $position_status = -1;
        $position_status_error = "Can't get master position on '" . $master->get_id() . "'.";
    } else {
        # Get Master Position
        $master->query(query => q{
            SHOW MASTER STATUS
        });
        my $result = $master->fetchrow_hashref();
        my $master_file = $result->{File};
        my $master_position = $result->{Position};
        
        $slave->query(query => q{
            SHOW SLAVE STATUS
        });
        my $result2 = $slave->fetchrow_hashref();
        my $slave_file = $result2->{Master_Log_File}; # 'Master_Log_File'
        my $slave_position = $result2->{Read_Master_Log_Pos}; # 'Read_Master_Log_Pos'
        my $num_sec_lates = $result2->{Seconds_Behind_Master};

        my $exit_code_sec = $self->{perfdata}->threshold_check(value => $num_sec_lates, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        if (!$self->{output}->is_status(value => $exit_code_sec, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit_code_sec,
                                        short_msg => sprintf("Slave '%s' has %d seconds latency behind master", $slave->get_id(), $num_sec_lates));
        }
        $self->{output}->perfdata_add(label => 'slave_latency_' . $slave->get_id(), unit => 's',
                                      value => $num_sec_lates,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
        
        my $slave_sql_thread_ko = 1;
        my $slave_sql_thread_warning = 1;
        my $slave_sql_thread_ok = 1;
        
        $slave->query(query => q{
            SHOW FULL PROCESSLIST
        });
        while ((my $row = $slave->fetchrow_hashref())) {
            my $state = $row->{State};
            $slave_sql_thread_ko = 0 if (defined($state) && $state =~ /^(Waiting to reconnect after a failed binlog dump request|Connecting to master|Reconnecting after a failed binlog dump request|Waiting to reconnect after a failed master event read|Waiting for the slave SQL thread to free enough relay log space)$/i);
            $slave_sql_thread_warning = 0 if (defined($state) && $state =~ /^Waiting for the next event in relay log|Reading event from the relay log$/i);
            $slave_sql_thread_ok = 0 if (defined($state) && $state =~ /^Has read all relay log; waiting for the slave I\/O thread to update it$/i);
        }
        
        if ($slave_sql_thread_ko == 0) {
            $position_status = 1;
            $position_status_error .= " Slave replication has connection issue with the master.";
        } elsif (($master_file ne $slave_file || $master_position != $slave_position) && $slave_sql_thread_warning == 0) {
            $position_status = -1;
            $position_status_error .= " Slave replication is late but it's progressing..";
        } elsif (($master_file ne $slave_file || $master_position != $slave_position) && $slave_sql_thread_ok == 0) {
            $position_status = -1;
            $position_status_error .= " Slave replication is late but it's progressing..";
        }
    }

    $self->replication_add($slave_status, "Slave Thread Status '" . $slave->get_id() . "'", $slave_status_error);
	$self->replication_add($position_status, "Position Status '" . $slave->get_id() . "'", $position_status_error);
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    
    if (ref($options{sql}) ne 'ARRAY') {
        $self->{output}->add_option_msg(short_msg => "Need to use --multiple options.");
        $self->{output}->option_exit();
    }
    if (scalar(@{$options{sql}}) < 2) {
        $self->{output}->add_option_msg(short_msg => "Need to specify two MySQL Server.");
        $self->{output}->option_exit();
    }

    my ($msg_error1, $msg_error2);
    my ($sql_one, $sql_two) = @{$options{sql}};
    
    ($self->{$sql_one->get_id()}->{exit}, $msg_error1) = $sql_one->connect(dontquit => 1);
    ($self->{$sql_two->get_id()}->{exit}, $msg_error2) = $sql_two->connect(dontquit => 1);
    $self->{output}->output_add(severity => 'OK',
                                short_msg => "No problems. Replication is ok.");
    if ($self->{$sql_one->get_id()}->{exit} == -1) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => "Connection Status '" . $sql_one->get_id() . "': " . $msg_error1);
    } else {
        $self->{output}->output_add(long_msg => "Connection Status '" . $sql_one->get_id() . "' [OK]");
    }
    if ($self->{$sql_two->get_id()}->{exit} == -1) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => "Connection Status '" . $sql_two->get_id() . "': " . $msg_error2);
    } else {
        $self->{output}->output_add(long_msg => "Connection Status '" . $sql_two->get_id() . "' [OK]");
    }
    
    $self->check_replication(master => $sql_one, slave => $sql_two);
    $self->check_replication(master => $sql_two, slave => $sql_one);
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub replication_add {
	my ($self, $lstate, $str_display, $lerr) = @_;
	my $status;
    my $status_msg;

	if ($lstate == 0) {
		$status = 'OK';
	} elsif ($lstate == -1) {
		$status = 'WARNING';
	} elsif ($lstate == -2) {
		$status = 'CRITICAL';
        $status_msg = 'SKIP';
	} else {
		$status = 'CRITICAL';
	}

    my $output;
	if (defined($lerr) && $lerr ne "") {
		$output = $str_display . " [" . (defined($status_msg) ? $status_msg : $status) . "] [" . $lerr . "]";
	} else {
		$output = $str_display . " [" . (defined($status_msg) ? $status_msg : $status) . "]";
	}
    if (!$self->{output}->is_status(value => $status, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $status,
                                    short_msg => $output);
    }
    
	$self->{output}->output_add(long_msg => $output);
}

1;

__END__

=head1 MODE

Check MySQL replication master/master (need to use --multiple).

=over 8

=item B<--warning>

Threshold warning in seconds (slave latency).

=item B<--critical>

Threshold critical in seconds (slave latency).

=back

=cut
