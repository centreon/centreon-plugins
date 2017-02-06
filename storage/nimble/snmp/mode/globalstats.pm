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

package storage::nimble::snmp::mode::globalstats;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::values;
use centreon::plugins::statefile;

my $maps_counters = {
    global => {
        '000_read'   => { set => {
                key_values => [ { name => 'read', diff => 1 } ],
                per_second => 1,
                output_template => 'Read I/O : %s %s/s', output_error_template => "Read I/O : %s",
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'read', value => 'read_per_second', template => '%d',
                      unit => 'B/s' },
                ],
            }
        },
        '001_write'   => { set => {
                key_values => [ { name => 'write', diff => 1 } ],
                per_second => 1,
                output_template => 'Write I/O : %s %s/s', output_error_template => "Write I/O : %s",
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'write', value => 'write_per_second', template => '%d',
                      unit => 'B/s', min => 0 },
                ],
            }
        },
        '002_read-iops'   => { set => {
                key_values => [ { name => 'read_iops', diff => 1 } ],
                per_second => 1,
                output_template => 'Read IOPs : %.2f', output_error_template => "Read IOPs : %s",
                perfdatas => [
                    { label => 'read_iops', value => 'read_iops_per_second',  template => '%.2f',
                      unit => 'iops', min => 0 },
                ],
            }
        },
        '003_write-iops'   => { set => {
                key_values => [ { name => 'write_iops', diff => 1 } ],
                per_second => 1,
                output_template => 'Write IOPs : %.2f', output_error_template => "Write IOPs : %s",
                perfdatas => [
                    { label => 'write_iops', value => 'write_iops_per_second', template => '%.2f',
                      unit => 'iops', min => 0 },
                ],
            }
        },
        '004_read-time'   => { set => {
                key_values => [ { name => 'read_time', diff => 1 } ],
                output_template => 'Read Time : %.3f s', output_error_template => "Read Time : %s",
                perfdatas => [
                    { label => 'read_time', value => 'read_time_absolute',  template => '%.3f',
                      unit => 's', min => 0 },
                ],
            }
        },
        '005_write-time'   => { set => {
                key_values => [ { name => 'write_time', diff => 1 } ],
                output_template => 'Write Time : %.3f s', output_error_template => "Write Time : %s",
                perfdatas => [
                    { label => 'write_time', value => 'write_time_absolute', template => '%.3f',
                      unit => 's', min => 0 },
                ],
            }
        },
    },
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "filter-counters:s" => { name => 'filter_counters' },
                                });
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);

    foreach my $key (('global')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                    'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                    'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(statefile => $self->{statefile_value},
                                                      output => $self->{output},
                                                      perfdata => $self->{perfdata},
                                                      label => $name);
            $maps_counters->{$key}->{$_}->{obj}->set(%{$maps_counters->{$key}->{$_}->{set}});
        }
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach my $key (('global')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }
    
    $self->{statefile_value}->check_options(%options);
}

sub run_global {
    my ($self, %options) = @_;

    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters->{global}}) {
        if (defined($self->{option_results}->{filter_counters}) && $self->{option_results}->{filter_counters} ne '' &&
            $_ !~ /$self->{option_results}->{filter_counters}/) {
            $self->{output}->output_add(long_msg => "skipping counter $_", debug => 1);
            next;
        }

        my $obj = $maps_counters->{global}->{$_}->{obj};
                
        $obj->set(instance => 'global');
    
        my ($value_check) = $obj->execute(new_datas => $self->{new_datas},
                                          values => $self->{global});

        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $obj->output_error();
            $long_msg_append = ', ';
            next;
        }
        my $exit2 = $obj->threshold_check();
        push @exits, $exit2;

        my $output = $obj->output();
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = ', ';
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = ', ';
        }
        
        $obj->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "$short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "$long_msg");
    }    
}

sub run {
    my ($self, %options) = @_;
    
    $self->manage_selection(%options);

    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => $self->{cache_name});
    $self->{new_datas}->{last_timestamp} = time();
    
    $self->run_global();

    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;
    
    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "nimble_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    $self->{global} = {};
    my $oid_globalStats = '.1.3.6.1.4.1.37447.1.3';
    my $oid_ioReads = '.1.3.6.1.4.1.37447.1.3.2.0';
    my $oid_ioReadBytes = '.1.3.6.1.4.1.37447.1.3.8.0';
    my $oid_ioReadTimeMicrosec = '.1.3.6.1.4.1.37447.1.3.6.0';
    my $oid_ioWrites = '.1.3.6.1.4.1.37447.1.3.4.0';
    my $oid_ioWriteBytes = '.1.3.6.1.4.1.37447.1.3.10.0';
    my $oid_ioWriteTimeMicrosec = '.1.3.6.1.4.1.37447.1.3.7.0';
    my $result = $options{snmp}->get_table(oid => $oid_globalStats,
                                           nothing_quit => 1);
    $self->{global}->{read} = defined($result->{$oid_ioReadBytes}) ? $result->{$oid_ioReadBytes} : undef;
    $self->{global}->{read_iops} = defined($result->{$oid_ioReads}) ? $result->{$oid_ioReads} : undef;
    $self->{global}->{read_time} = defined($result->{$oid_ioReadTimeMicrosec}) ? $result->{$oid_ioReadTimeMicrosec} / 1000000 : undef;
    $self->{global}->{write} = defined($result->{$oid_ioWriteBytes}) ? $result->{$oid_ioWriteBytes} : undef;
    $self->{global}->{write_iops} = defined($result->{$oid_ioWrites}) ? $result->{$oid_ioWrites} : undef;
    $self->{global}->{write_time} = defined($result->{$oid_ioWriteTimeMicrosec}) ? $result->{$oid_ioWriteTimeMicrosec} / 1000000: undef;
}

1;

__END__

=head1 MODE

Check global statistics of storage.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'read', 'read-iops', 'write', 'write-iops',
'read-time', 'write-time'.

=item B<--critical-*>

Threshold critical.
Can be: 'read', 'read-iops', 'write', 'write-iops',
'read-time', 'write-time'.

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='-iops$'

=back

=cut
