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

package storage::netapp::snmp::mode::globalstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use centreon::plugins::values;

my $maps_counters = {
    read   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [
                                        { name => 'read', diff => 1 },
                                      ],
                        per_second => 1,
                        output_template => 'Read I/O : %s %s/s',
                        output_change_bytes => 1,
                        perfdatas => [
                            { value => 'read_per_second', template => '%d',
                              unit => 'B/s', min => 0 },
                        ],
                    }
               },
    write   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'write', diff => 1 },
                                      ],
                        per_second => 1,
                        output_template => 'Write I/O : %s %s/s',
                        output_change_bytes => 1,
                        perfdatas => [
                            { value => 'write_per_second', template => '%d',
                              unit => 'B/s', min => 0 },
                        ],
                    }
               },
};

my %states = (
    1 => ['other', 'WARNING'], 
    2 => ['unknown', 'UNKNOWN'], 
    3 => ['ok', 'OK'], 
    4 => ['non critical', 'WARNING'],
    5 => ['critical', 'CRITICAL'],
    6 => ['nonRecoverable', 'WARNING'],
);
my %fs_states = (
    1 => ['ok', 'OK'], 
    2 => ['nearly full', 'WARNING'], 
    3 => ['full', 'CRITICAL'], 
);

my $oid_fsOverallStatus = '.1.3.6.1.4.1.789.1.5.7.1.0';
my $oid_fsStatusMessage = '.1.3.6.1.4.1.789.1.5.7.2.0';
my $oid_miscGlobalStatus = '.1.3.6.1.4.1.789.1.2.2.4.0';
my $oid_miscGlobalStatusMessage = '.1.3.6.1.4.1.789.1.2.2.25.0';
my $oid_misc64DiskReadBytes = '.1.3.6.1.4.1.789.1.2.2.32.0';
my $oid_misc64DiskWriteBytes = '.1.3.6.1.4.1.789.1.2.2.33.0';
my $oid_miscHighDiskReadBytes = '.1.3.6.1.4.1.789.1.2.2.15.0';
my $oid_miscLowDiskReadBytes = '.1.3.6.1.4.1.789.1.2.2.16.0';
my $oid_miscHighDiskWriteBytes = '.1.3.6.1.4.1.789.1.2.2.17.0';
my $oid_miscLowDiskWriteBytes = '.1.3.6.1.4.1.789.1.2.2.18.0';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    $self->{statefile_value} = centreon::plugins::statefile->new(%options);  
    foreach (keys %{$maps_counters}) {
        $options{options}->add_options(arguments => {
                                                     'warning-' . $_ . ':s'    => { name => 'warning-' . $_ },
                                                     'critical-' . $_ . ':s'    => { name => 'critical-' . $_ },
                                      });
        my $class = $maps_counters->{$_}->{class};
        $maps_counters->{$_}->{obj} = $class->new(statefile => $self->{statefile_value},
                                                  output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $_);
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
    
    $self->{results}->{$oid_miscGlobalStatusMessage} =~ s/\n//g;
    $self->{output}->output_add(severity =>  ${$states{$self->{results}->{$oid_miscGlobalStatus}}}[1],
                                short_msg => sprintf("Overall global status is '%s' [message: '%s']", 
                                                ${$states{$self->{results}->{$oid_miscGlobalStatus}}}[0], $self->{results}->{$oid_miscGlobalStatusMessage}));
    $self->{results}->{$oid_fsStatusMessage} =~ s/\n//g;
    $self->{output}->output_add(severity =>  ${$fs_states{$self->{results}->{$oid_fsOverallStatus}}}[1],
                                short_msg => sprintf("Overall file system status is '%s' [message: '%s']", 
                                                ${$fs_states{$self->{results}->{$oid_fsOverallStatus}}}[0], $self->{results}->{$oid_fsStatusMessage}));
    
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "cache_netapp_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    $self->{new_datas}->{last_timestamp} = time();
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->set(instance => 'global');
    
        my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{global},
                                                                 new_datas => $self->{new_datas});

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
        
        $maps_counters->{$_}->{obj}->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "$short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "$long_msg");
    }
    
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $request = [$oid_fsOverallStatus, $oid_fsStatusMessage,
                   $oid_miscGlobalStatus, $oid_miscGlobalStatusMessage, 
                   $oid_miscHighDiskReadBytes, $oid_miscLowDiskReadBytes,
                   $oid_miscHighDiskWriteBytes, $oid_miscLowDiskWriteBytes];
    if (!$self->{snmp}->is_snmpv1()) {
        push @{$request}, ($oid_misc64DiskReadBytes, $oid_misc64DiskWriteBytes);
    }
    
    $self->{results} = $self->{snmp}->get_leef(oids => $request, nothing_quit => 1);
    
    $self->{global} = {};
    $self->{global}->{read} = defined($self->{results}->{$oid_misc64DiskReadBytes}) ?
                                $self->{results}->{$oid_misc64DiskReadBytes} : 
                                ($self->{results}->{$oid_miscHighDiskReadBytes} << 32) + $self->{results}->{$oid_miscLowDiskReadBytes};
    $self->{global}->{write} = defined($self->{results}->{$oid_misc64DiskWriteBytes}) ?
                                $self->{results}->{$oid_misc64DiskWriteBytes} : 
                                ($self->{results}->{$oid_miscHighDiskWriteBytes} << 32) + $self->{results}->{$oid_miscLowDiskWriteBytes};

}

1;

__END__

=head1 MODE

Check the overall status of the appliance and some metrics (total read bytes per seconds and total write bytes per seconds).
If you are in cluster mode, the following mode doesn't work. Ask to netapp to add it :)

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'read', 'write'.

=item B<--critical-*>

Threshold critical.
Can be: 'read', 'write'.

=back

=cut
    