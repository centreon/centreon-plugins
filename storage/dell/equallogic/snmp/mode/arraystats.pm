#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package storage::dell::equallogic::snmp::mode::arraystats;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;
use centreon::plugins::statefile;

my $maps_counters = {
    '000_connections'   => { set => {
                        key_values => [ { name => 'eqlMemberNumberOfConnections' }, { name => 'display' } ],
                        output_template => 'iSCSI connections : %s',
                        perfdatas => [
                            { label => 'connections', value => 'eqlMemberNumberOfConnections_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    '001_ext-connections'   => { set => {
                        key_values => [ { name => 'eqlMemberNumberOfExtConnections' }, { name => 'display' } ],
                        output_template => 'External iSCSI connections : %s',
                        perfdatas => [
                            { label => 'ext_connections', value => 'eqlMemberNumberOfExtConnections_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    '002_global-read-avg-latency'   => { set => {
                        key_values => [ { name => 'eqlMemberReadAvgLatency' }, { name => 'display' } ],
                        output_template => 'Global read average latency : %s ms',
                        perfdatas => [
                            { label => 'global_read_avg_latency', value => 'eqlMemberReadAvgLatency_absolute', template => '%s',
                              unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    '003_global-write-avg-latency'   => { set => {
                        key_values => [ { name => 'eqlMemberWriteAvgLatency' }, { name => 'display' } ],
                        output_template => 'Global write average latency : %s ms',
                        perfdatas => [
                            { label => 'global_write_avg_latency', value => 'eqlMemberWriteAvgLatency_absolute', template => '%s',
                              unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    '005_read-avg-latency'   => { set => {
                        key_values => [ { name => 'eqlMemberReadLatency', diff => 1 }, { name => 'eqlMemberReadOpCount', diff => 1 }, { name => 'display' } ],
                        output_template => 'Read average latency : %.2f ms', threshold_use => 'read_avg_latency', output_use => 'read_avg_latency',
                        closure_custom_calc => \&custom_read_avg_latency_calc,
                        perfdatas => [
                            { label => 'read_avg_latency', value => 'read_avg_latency', template => '%.2f',
                              unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    '006_write-avg-latency'   => { set => {
                        key_values => [ { name => 'eqlMemberWriteLatency', diff => 1 }, { name => 'eqlMemberWriteOpCount', diff => 1 }, { name => 'display' } ],
                        output_template => 'Write average latency : %.2f ms', threshold_use => 'write_avg_latency', output_use => 'write_avg_latency',
                        closure_custom_calc => \&custom_write_avg_latency_calc,
                        perfdatas => [
                            { label => 'write_avg_latency', value => 'write_avg_latency', template => '%.2f',
                              unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    '007_read-iops'   => { set => {
                        key_values => [ { name => 'eqlMemberReadOpCount', diff => 1 }, { name => 'display' } ],
                        per_second => 1,
                        output_template => 'Read IOPs : %.2f',
                        perfdatas => [
                            { label => 'read_iops',  template => '%.2f', value => 'eqlMemberReadOpCount_per_second',
                              unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    '008_write-iops'   => { set => {
                        key_values => [ { name => 'eqlMemberWriteOpCount', diff => 1 }, { name => 'display' } ],
                        per_second => 1,
                        output_template => 'Write IOPs : %.2f',
                        perfdatas => [
                            { label => 'write_iops', template => '%.2f', value => 'eqlMemberWriteOpCount_per_second',
                              unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    
    '010_traffic-in'   => { set => {
                        key_values => [ { name => 'eqlMemberRxData', diff => 1 }, { name => 'display' } ],
                        per_second => 1, output_change_bytes => 2,
                        output_template => 'Traffic In : %s %s/s',
                        perfdatas => [
                            { label => 'traffic_in', value => 'eqlMemberRxData_per_second', template => '%s',
                              unit => 'b/s', min => 0, cast_int => 1, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    '011_traffic-out'   => { set => {
                        key_values => [ { name => 'eqlMemberTxData', diff => 1 }, { name => 'display' } ],
                        per_second => 1,  output_change_bytes => 2,
                        output_template => 'Traffic Out : %s %s/s',
                        perfdatas => [
                            { label => 'traffic_out', value => 'eqlMemberTxData_per_second', template => '%s',
                              unit => 'b/s', min => 0, cast_int => 1, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
};

sub custom_write_avg_latency_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    my $diff_op = $options{new_datas}->{$self->{instance} . '_eqlMemberWriteOpCount'} - $options{old_datas}->{$self->{instance} . '_eqlMemberWriteOpCount'};
    my $diff_latency = $options{new_datas}->{$self->{instance} . '_eqlMemberWriteLatency'} - $options{old_datas}->{$self->{instance} . '_eqlMemberWriteLatency'};
    if ($diff_op == 0) {
        $self->{result_values}->{write_avg_latency} = 0;
    } else {
        $self->{result_values}->{write_avg_latency} = $diff_latency / $diff_op;
    }
    
    return 0;
}

sub custom_read_avg_latency_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    my $diff_op = $options{new_datas}->{$self->{instance} . '_eqlMemberReadOpCount'} - $options{old_datas}->{$self->{instance} . '_eqlMemberReadOpCount'};
    my $diff_latency = $options{new_datas}->{$self->{instance} . '_eqlMemberReadLatency'} - $options{old_datas}->{$self->{instance} . '_eqlMemberReadLatency'};
     if ($diff_op == 0) {
        $self->{result_values}->{read_avg_latency} = 0;
    } else {
        $self->{result_values}->{read_avg_latency} = $diff_latency / $diff_op;
    }
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-name:s"     => { name => 'filter_name' },
                                });
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
     
    foreach (keys %{$maps_counters}) {
        my ($id, $name) = split /_/;
        if (!defined($maps_counters->{$_}->{threshold}) || $maps_counters->{$_}->{threshold} != 0) {
            $options{options}->add_options(arguments => {
                                                        'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                        'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                           });
        }
        $maps_counters->{$_}->{obj} = centreon::plugins::values->new(statefile => $self->{statefile_value},
                                                  output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $name);
        $maps_counters->{$_}->{obj}->set(%{$maps_counters->{$_}->{set}});
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach (keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }
    
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{member_selected}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All array statistics are ok');
    }
    
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "dell_equallogic_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    $self->{new_datas}->{last_timestamp} = time();
    
    foreach my $id (sort keys %{$self->{member_selected}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits;
        foreach (sort keys %{$maps_counters}) {
            $maps_counters->{$_}->{obj}->set(instance => $id);
        
            my ($value_check) = $maps_counters->{$_}->{obj}->execute(new_datas => $self->{new_datas},
                                                                     values => $self->{member_selected}->{$id});

            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $maps_counters->{$_}->{obj}->output_error();
                $long_msg_append = ', ';
                next;
            }
            my $exit2 = $maps_counters->{$_}->{obj}->threshold_check();
            push @exits, $exit2;

            my $output = $maps_counters->{$_}->{obj}->output();
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = ', ';
            
            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = ', ';
            }
            
            $maps_counters->{$_}->{obj}->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "'" . $self->{member_selected}->{$id}->{display} . "' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "'" . $self->{member_selected}->{$id}->{display} . "' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "'" . $self->{member_selected}->{$id}->{display} . "' $long_msg");
        }
    }
    
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

my $mapping = {
    eqlMemberNumberOfConnections   => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.1' },
    eqlMemberReadLatency   => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.2' },
    eqlMemberWriteLatency   => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.3' },
    eqlMemberReadAvgLatency   => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.4' },
    eqlMemberWriteAvgLatency   => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.5' },
    eqlMemberReadOpCount   => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.6' },
    eqlMemberWriteOpCount   => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.7' },
    eqlMemberTxData   => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.8' },
    eqlMemberRxData   => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.9' },
    eqlMemberNumberOfExtConnections   => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.10' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_eqlMemberName = '.1.3.6.1.4.1.12740.2.1.1.1.9';
    my $oid_eqlMemberConnEntry = '.1.3.6.1.4.1.12740.2.1.12.1';
    
    $self->{member_selected} = {};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_eqlMemberName },
                                                            { oid => $oid_eqlMemberConnEntry },
                                                         ],
                                                         nothing_quit => 1);
    
    foreach my $oid (keys %{$self->{results}->{$oid_eqlMemberConnEntry}}) {
        next if ($oid !~ /^$mapping->{eqlMemberNumberOfConnections}->{oid}\.(\d+\.\d+)/);
        my $member_instance = $1;
        next if (!defined($self->{results}->{$oid_eqlMemberName}->{$oid_eqlMemberName . '.' . $member_instance}));
        my $member_name = $self->{results}->{$oid_eqlMemberName}->{$oid_eqlMemberName . '.' . $member_instance};
        
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_eqlMemberConnEntry}, instance => $member_instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $member_name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $member_name . "': no matching filter.");
            next;
        }
        
        $self->{member_selected}->{$member_name} = { display => $member_name, 
                                                     %{$result}
                                                   };
        $self->{member_selected}->{$member_name}->{eqlMemberTxData} *= 8 if (defined($self->{member_selected}->{$member_name}->{eqlMemberTxData}));
        $self->{member_selected}->{$member_name}->{eqlMemberRxData} *= 8 if (defined($self->{member_selected}->{$member_name}->{eqlMemberRxData}));
    }
    
    if (scalar(keys %{$self->{member_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check global array statistics.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'connections', 'ext-connections', 'global-read-avg-latency' (ms), 'global-write-avg-latency'  (ms),
'read-avg-latency' (ms), 'write-avg-latency' (ms), 'read-iops' (iops), 'write-iops (iops), 'traffic-in' (b/s), 'traffic-out' (b/s).

=item B<--critical-*>

Threshold critical.
Can be: 'connections', 'ext-connections', 'global-read-avg-latency' (ms), 'global-write-avg-latency'  (ms),
'read-avg-latency' (ms), 'write-avg-latency' (ms), 'read-iops' (iops), 'write-iops (iops), 'traffic-in' (b/s), 'traffic-out' (b/s).

=item B<--filter-name>

Filter disk name (can be a regexp).

=back

=cut
