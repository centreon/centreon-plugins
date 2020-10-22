#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package database::mysql::mode::replication;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_connection_output {
    my ($self, %options) = @_;

    return sprintf(
        'connection status: %s%s',
        $self->{result_values}->{status},
        $self->{result_values}->{status} ne 'ok' ? ' [error message: ' . $self->{result_values}->{error_message} . ']' : ''
    );
}

sub custom_thread_sql_output {
    my ($self, %options) = @_;

    return sprintf(
        'thread sql running: %s%s',
        $self->{result_values}->{running},
        $self->{result_values}->{running} ne 'yes' ? ' [last error message: ' . $self->{result_values}->{error_message} . ']' : ''
    );
}

sub custom_thread_io_output {
    my ($self, %options) = @_;

    return sprintf(
        'thread io running: %s%s',
        $self->{result_values}->{running},
        $self->{result_values}->{running} ne 'yes' ? ' [last error message: ' . $self->{result_values}->{error_message} . ']' : ''
    );
}

sub custom_replication_output {
    my ($self, %options) = @_;

    return sprintf(
        'replication status: %s',
        $self->{result_values}->{replication_status}
    );
}

sub server_long_output {
    my ($self, %options) = @_;

    return "checking database instance '" . $options{instance_value}->{display} . "'";
}

sub prefix_server_output {
    my ($self, %options) = @_;

    return "database instance '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'servers', type => 3, cb_prefix_output => 'prefix_server_output', cb_long_output => 'server_long_output', indent_long_output => '    ', message_multiple => 'All database instances are ok',
          group => [
                { name => 'connection', type => 0, skipped_code => { -10 => 1 } },
                { name => 'thread_sql', type => 0, skipped_code => { -10 => 1 } },
                { name => 'thread_io', type => 0, skipped_code => { -10 => 1 } },
                { name => 'position', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'slaves-running', nlabel => 'instance.slaves.running.count', set => {
                key_values => [ { name => 'slaves_running' }, { name => 'total' } ],
                output_template => 'number of slave instances running: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{connection} = [
        {
            label => 'connection-status',
            type => 2,
            critical_default => '%{status} ne "ok"',
            set => {
                key_values => [ { name => 'status' }, { name => 'error_message' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_connection_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{thread_sql} = [
        {
            label => 'thread-sql-status',
            type => 2,
            set => {
                key_values => [ { name => 'running' }, { name => 'error_message' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_thread_sql_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{thread_io} = [
        {
            label => 'thread-io-status',
            type => 2,
            set => {
                key_values => [ { name => 'running' }, { name => 'error_message' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_thread_io_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{position} = [
         { label => 'slave-latency', nlabel => 'instance.slave.latency.seconds', set => {
                key_values => [ { name => 'latency' } ],
                output_template => 'slave has %s seconds latency behind master',
                perfdatas => [
                    { template => '%d', unit => 's', label_extra_instance => 1 }
                ]
            }
        },
        {
            label => 'replication-status',
            unknown_default => '%{replication_status} =~ /configurationIssue/i',
            warning_default => '%{replication_status} =~ /inProgress/i',
            critical_default => '%{replication_status} =~ /connectIssueToMaster/i',
            type => 2,
            set => {
                key_values => [ { name => 'replication_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_replication_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub sql_query_show_slave_status {
    my ($self, %options) = @_;

    if ($options{sql}->is_mariadb() && $options{sql}->is_version_minimum(version => '10.2.x')) {
        $options{sql}->query(query => q{
            SHOW ALL SLAVES STATUS
        });
    } else {
        $options{sql}->query(query => q{
            SHOW SLAVE STATUS
        });
    }
}

sub check_connection {
    my ($self, %options) = @_;

    my ($exit, $msg_error) = $options{sql}->connect(dontquit => 1);
    if ($exit == -1) {
        $self->{servers}->{ $options{name} }->{connection}->{status} = 'error';
        $self->{servers}->{ $options{name} }->{connection}->{error_message} = $msg_error;
    }
}

sub check_slave {
    my ($self, %options) = @_;

    return if ($self->{servers}->{ $options{name} }->{connection}->{status} ne 'ok');

    $self->sql_query_show_slave_status(sql => $options{sql});

    my $result = $options{sql}->fetchrow_hashref();
    my $slave_running = 0;
    if (defined($result->{Slave_IO_Running})) {
        my $running = 'no';

        if ($result->{Slave_IO_Running} =~ /^yes$/i) {
            $slave_running = 1;
            $running = 'yes';
        }
        $self->{servers}->{ $options{name} }->{thread_io} = {
            display => $options{name},
            running => $running,
            error_message => defined($result->{Last_Error}) ? $result->{Last_Error} : ''
        };
    }
    if (defined($result->{Slave_SQL_Running})) {
        my $running = 'no';

        if ($result->{Slave_SQL_Running} =~ /^yes$/i) {
            $slave_running = 1;
            $running = 'yes';
        }
        $self->{servers}->{ $options{name} }->{thread_sql} = {
            display => $options{name},
            running => $running,
            error_message => defined($result->{Last_Error}) ? $result->{Last_Error} : ''
        };
    }

    $self->{servers}->{ $options{name} }->{is_slave} = $slave_running;
    $self->{global}->{slaves_running} += $slave_running;
}

sub check_master_slave_position {
    my ($self, %options) = @_;

    return if ($self->{servers}->{ $options{name_master} }->{connection}->{status} ne 'ok');
    return if ($self->{servers}->{ $options{name_slave} }->{connection}->{status} ne 'ok');
    return if ($self->{servers}->{ $options{name_slave} }->{is_slave} == 0);

    $options{sql_master}->query(query => q{
        SHOW MASTER STATUS
    });
    my $master_result = $options{sql_master}->fetchrow_hashref();

    $self->sql_query_show_slave_status(sql => $options{sql});
    my $slave_result = $options{sql_slave}->fetchrow_hashref();

    $self->{servers}->{ $options{name_slave} }->{position} = {
        display => $options{name_slave},
        latency => $slave_result->{Seconds_Behind_Master},
        replication_status => 'ok'
    };

    $options{sql_slave}->query(query => q{
        SHOW FULL PROCESSLIST
    });

    my ($slave_sql_thread_ko, $slave_sql_thread_warning, $slave_sql_thread_ok) = (1, 1, 1);
    while ((my $row = $options{sql_slave}->fetchrow_hashref())) {
        my $state = $row->{State};
        $slave_sql_thread_ko = 0 if (defined($state) && $state =~ /^(Waiting to reconnect after a failed binlog dump request|Connecting to master|Reconnecting after a failed binlog dump request|Waiting to reconnect after a failed master event read|Waiting for the slave SQL thread to free enough relay log space)$/i);
        $slave_sql_thread_warning = 0 if (defined($state) && $state =~ /^Waiting for the next event in relay log|Reading event from the relay log$/i);
        $slave_sql_thread_ok = 0 if (defined($state) && $state =~ /^Has read all relay log; waiting for the slave I\/O thread to update it$/i);
    }

    if ($slave_sql_thread_ko == 0) {
        $self->{servers}->{ $options{name_slave} }->{position}->{replication_status} = 'connectIssueToMaster';
    } elsif (($master_result->{File} ne $slave_result->{Master_Log_File} ||
              $master_result->{Position} !=  $slave_result->{Read_Master_Log_Pos}) &&
             ($slave_sql_thread_warning == 0 || $slave_sql_thread_ok == 0)
    ) {
        $self->{servers}->{ $options{name_slave} }->{position}->{replication_status} = 'inProgress';
    } else {
        $master_result->{File} =~ /(\d+)$/;
        my $master_bin_num = $1;
        $slave_result->{Master_Log_File} =~ /(\d+)$/;
        my $slave_bin_num = $1;
        my $diff_binlog = abs($master_bin_num - $slave_bin_num);

        # surely of missconfiguration of the plugin
        if ($diff_binlog > 1 && $slave_result->{Seconds_Behind_Master} < 10) {
            $self->{servers}->{ $options{name_slave} }->{position}->{replication_status} = 'configurationIssue';
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    
    if (ref($options{sql}) ne 'ARRAY') {
        $self->{output}->add_option_msg(short_msg => "Need to use --multiple options.");
        $self->{output}->option_exit();
    }
    if (scalar(@{$options{sql}}) < 2) {
        $self->{output}->add_option_msg(short_msg => "Need to specify two MySQL Server.");
        $self->{output}->option_exit();
    }

    my ($sql_server1, $sql_server2) = @{$options{sql}};
    my ($server1_name, $server2_name) = ($sql_server1->get_id(), $sql_server2->get_id());

    $self->{global} = {
        total => 2,
        slaves_running => 0
    };
    $self->{servers} = {
        $server1_name => {
            display => $server1_name,
            connection => {
                display => $server1_name,
                status => 'ok',
                error_message => ''
            }
        },
        $server2_name => {
            display => $server2_name,
            connection => {
                display => $server2_name,
                status => 'ok',
                error_message => ''
            }
        }
    };

    $self->check_connection(name => $server1_name, sql => $sql_server1);
    $self->check_connection(name => $server2_name, sql => $sql_server2);

    $self->check_slave(name => $server1_name, sql => $sql_server1);
    $self->check_slave(name => $server2_name, sql => $sql_server2);

    $self->check_master_slave_position(
        name_master => $server1_name,
        name_slave => $server2_name,
        sql_master => $sql_server1,
        sql_slave => $sql_server2
    );
    $self->check_master_slave_position(
        name_master => $server2_name,
        name_slave => $server1_name,
        sql_master => $sql_server2,
        sql_slave => $sql_server1
    );
}

1;

__END__

=head1 MODE

Check MySQL replication (need to use --multiple).

=over 8

=item B<--unknown-connection-status>

Set unknown threshold for status.
Can used special variables like:  %{status}, %{error_message}, %{display}

=item B<--warning-connection-status>

Set warning threshold for status.
Can used special variables like:  %{status}, %{error_message}, %{display}

=item B<--critical-connection-status>

Set critical threshold for status (Default: '%{status} ne "ok"').
Can used special variables like: %{status}, %{error_message}, %{display}

=item B<--unknown-replication-status>

Set unknown threshold for status (Default: '%{replication_status} =~ /configurationIssue/i').
Can used special variables like: %{replication_status}, %{display}

=item B<--warning-replication-status>

Set warning threshold for status (Default: '%{replication_status} =~ /inProgress/i').
Can used special variables like: %{replication_status}, %{display}

=item B<--critical-replication-status>

Set critical threshold for status (Default: '%{replication_status} =~ /connectIssueToMaster/i').
Can used special variables like: %{replication_status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'slaves-running', 'slave-latency' (s).

=back

=cut
