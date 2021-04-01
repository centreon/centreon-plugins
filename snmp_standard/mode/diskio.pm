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

package snmp_standard::mode::diskio;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_init => 'skip_global', cb_prefix_output => 'prefix_global_output', cb_suffix_output => 'suffix_output' },
        { name => 'sum', type => 0, cb_init => 'skip_global', cb_prefix_output => 'prefix_sum_output', cb_suffix_output => 'suffix_output' },
        { name => 'disk', type => 1, cb_prefix_output => 'prefix_disk_output', message_multiple => 'All devices are ok' }
    ];
    $self->{maps_counters}->{global} = [
        { label => 'total-read', set => {
                key_values => [ { name => 'total_read', per_second => 1 } ],
                output_template => 'Read I/O : %s %s/s', output_error_template => "Read I/O : %s",
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'total_read', template => '%d',
                      unit => 'B/s', min => 0 },
                ],
            }
        },
        { label => 'total-write', set => {
                key_values => [ { name => 'total_write', per_second => 1 } ],
                output_template => 'Write I/O : %s %s/s', output_error_template => "Write I/O : %s",
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'total_write', template => '%d',
                      unit => 'B/s', min => 0 },
                ],
            }
        },
        { label => 'total-read-iops', set => {
                key_values => [ { name => 'total_read_iops', per_second => 1 } ],
                output_template => 'Read IOPs : %.2f', output_error_template => "Read IOPs : %s",
                perfdatas => [
                    { label => 'total_read_iops', template => '%.2f',
                      unit => 'iops', min => 0 },
                ],
            }
        },
        { label => 'total-write-iops', set => {
                key_values => [ { name => 'total_write_iops', per_second => 1 } ],
                output_template => 'Write IOPs : %.2f', output_error_template => "Write IOPs : %s",
                perfdatas => [
                    { label => 'total_write_iops', template => '%.2f',
                      unit => 'iops', min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{sum} = [
        { label => 'sum-read-write', set => {
                key_values => [ { name => 'sum_read_write', per_second => 1 } ],
                output_template => 'R+W I/O : %s %s/s', output_error_template => "R+W I/O : %s",
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'sum_read_write', template => '%d',
                      unit => 'B/s', min => 0 },
                ],
            }
        },
        { label => 'sum-read-write-iops', set => {
                key_values => [ { name => 'sum_read_write_iops', per_second => 1 } ],
                output_template => 'R+W IOPs : %.2f', output_error_template => "R+W IOPs : %s",
                perfdatas => [
                    { label => 'sum_read_write_iops', template => '%.2f',
                      unit => 'iops', min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{disk} = [
        { label => 'read', set => {
                key_values => [ { name => 'read', per_second => 1 }, { name => 'display' } ],
                output_template => 'Read I/O : %s %s/s', output_error_template => "Read I/O : %s",
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'read', template => '%d',
                      unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write', set => {
                key_values => [ { name => 'write', per_second => 1 }, { name => 'display' } ],
                output_template => 'Write I/O : %s %s/s', output_error_template => "Write I/O : %s",
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'write', template => '%d',
                      unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'read-iops', set => {
                key_values => [ { name => 'read_iops', per_second => 1 }, { name => 'display' } ],
                output_template => 'Read IOPs : %.2f', output_error_template => "Read IOPs : %s",
                perfdatas => [
                    { label => 'read_iops', template => '%.2f',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write-iops', set => {
                key_values => [ { name => 'write_iops', per_second => 1 }, { name => 'display' } ],
                output_template => 'Write IOPs : %.2f', output_error_template => "Write IOPs : %s",
                perfdatas => [
                    { label => 'write_iops', template => '%.2f',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'name'              => { name => 'use_name' },
        'device:s'          => { name => 'device' },
        'regexp'            => { name => 'use_regexp' },
        'regexp-isensitive' => { name => 'use_regexpi' }                               
    });

    return $self;
}

sub skip_global {
    my ($self, %options) = @_;
    
    scalar(keys %{$self->{disk}}) > 1 ? return(0) : return(1);
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "All devices [";
}

sub prefix_sum_output {
    my ($self, %options) = @_;
    
    return "Server overall [";
}

sub prefix_disk_output {
    my ($self, %options) = @_;
    
    return "Device '" . $options{instance_value}->{display} . "' ";
}

sub suffix_output {
    my ($self, %options) = @_;
    
    return "]";
}

my $oid_diskIODevice = '.1.3.6.1.4.1.2021.13.15.1.1.2';
my $oid_diskIOReads = '.1.3.6.1.4.1.2021.13.15.1.1.5';
my $oid_diskIOWrites = '.1.3.6.1.4.1.2021.13.15.1.1.6';
my $oid_diskIONReadX = '.1.3.6.1.4.1.2021.13.15.1.1.12'; # in B
my $oid_diskIONWrittenX = '.1.3.6.1.4.1.2021.13.15.1.1.13'; # in B

sub add_result {
    my ($self, %options) = @_;
    
    $self->{disk}->{$options{instance}} = { read => undef, write => undef, read_iops => undef, write_iops => undef };
    $self->{disk}->{$options{instance}}->{display} = $self->{results}->{$oid_diskIODevice}->{$oid_diskIODevice . '.' . $options{instance}};    
    if (defined($self->{results}->{$oid_diskIONReadX}->{$oid_diskIONReadX . '.' . $options{instance}}) && $self->{results}->{$oid_diskIONReadX}->{$oid_diskIONReadX . '.' . $options{instance}} != 0) {
        $self->{disk}->{$options{instance}}->{read} = $self->{results}->{$oid_diskIONReadX}->{$oid_diskIONReadX . '.' . $options{instance}};
        $self->{global}->{total_read} += $self->{disk}->{$options{instance}}->{read};
    }
    if (defined($self->{results}->{$oid_diskIONWrittenX}->{$oid_diskIONWrittenX . '.' . $options{instance}}) && $self->{results}->{$oid_diskIONWrittenX}->{$oid_diskIONWrittenX . '.' . $options{instance}} != 0) {
        $self->{disk}->{$options{instance}}->{write} = $self->{results}->{$oid_diskIONWrittenX}->{$oid_diskIONWrittenX . '.' . $options{instance}};
        $self->{global}->{total_write} += $self->{disk}->{$options{instance}}->{write};
    }    
    if (defined($self->{results}->{$oid_diskIOReads}->{$oid_diskIOReads . '.' . $options{instance}}) && $self->{results}->{$oid_diskIOReads}->{$oid_diskIOReads . '.' . $options{instance}} != 0) {
        $self->{disk}->{$options{instance}}->{read_iops} = $self->{results}->{$oid_diskIOReads}->{$oid_diskIOReads . '.' . $options{instance}};
        $self->{global}->{total_read_iops} += $self->{disk}->{$options{instance}}->{read_iops};
    }
    if (defined($self->{results}->{$oid_diskIOWrites}->{$oid_diskIOWrites . '.' . $options{instance}}) && $self->{results}->{$oid_diskIOWrites}->{$oid_diskIOWrites . '.' . $options{instance}} != 0) {
        $self->{disk}->{$options{instance}}->{write_iops} = $self->{results}->{$oid_diskIOWrites}->{$oid_diskIOWrites . '.' . $options{instance}};
        $self->{global}->{total_write_iops} += $self->{disk}->{$options{instance}}->{write_iops};
    }

    if ($self->{global}->{total_read} && $self->{global}->{total_write}) {
        $self->{sum}->{sum_read_write} = $self->{global}->{total_read} + $self->{global}->{total_write};
    }
    if ($self->{global}->{total_read_iops} && $self->{global}->{total_write_iops}) {
        $self->{sum}->{sum_read_write_iops} = $self->{global}->{total_read_iops} + $self->{global}->{total_write_iops};
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    
    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "snmpstandard_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{device}) ? md5_hex($self->{option_results}->{device}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    
    $self->{global} = { total_read => 0, total_write => 0, total_read_iops => 0, total_write_iops => 0 };
    $self->{sum} = { sum_read_write => 0, sum_read_write_iops => 0 };
    $self->{results} = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_diskIODevice },
                                                            { oid => $oid_diskIOReads },
                                                            { oid => $oid_diskIOWrites },
                                                            { oid => $oid_diskIONReadX },
                                                            { oid => $oid_diskIONWrittenX },
                                                         ],
                                                         , nothing_quit => 1);
 
    if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{device})) {
        if (!defined($self->{results}->{$oid_diskIODevice}->{$oid_diskIODevice . '.' . $self->{option_results}->{device}})) {
            $self->{output}->add_option_msg(short_msg => "No device found for id '" . $self->{option_results}->{device} . "'.");
            $self->{output}->option_exit();
        }
        $self->add_result(instance => $self->{option_results}->{device});
    } else {
        foreach my $oid (keys %{$self->{results}->{$oid_diskIODevice}}) {
            $oid =~ /\.(\d+)$/;
            my $instance = $1;
            my $filter_name = $self->{results}->{$oid_diskIODevice}->{$oid}; 
            if (!defined($self->{option_results}->{device}) || $self->{option_results}->{device} eq '') {
                $self->add_result(instance => $instance);
                next;
            }
            if (defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{device}/i) {
                $self->add_result(instance => $instance);
            }
            if (defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{device}/) {
                $self->add_result(instance => $instance);
            }
            if (!defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name eq $self->{option_results}->{device}) {
                $self->add_result(instance => $instance);
            }
        }    
    }
    
    if (scalar(keys %{$self->{disk}}) <= 0 && !defined($options{disco})) {
        if (defined($self->{option_results}->{device})) {
            $self->{output}->add_option_msg(short_msg => "No device found '" . $self->{option_results}->{device} . "' (or counter values are 0).");
        } else {
            $self->{output}->add_option_msg(short_msg => "No device found (or values are 0).");
        }
        $self->{output}->option_exit();
    }    
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'deviceid']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(disco => 1, %options);
    foreach (sort keys %{$self->{disk}}) {
        $self->{output}->add_disco_entry(name => $self->{results}->{$oid_diskIODevice}->{$oid_diskIODevice . '.' . $_},
                                         deviceid => $_);
    }
}


1;

__END__

=head1 MODE

Check read/write I/O disks (bytes per secondes, IOPs). 

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'read', 'write', 'read-iops', 'write-iops',
'total-read', 'total-write', 'total-read-iops', 'total-write-iops',
'sum-read-write', 'sum-read-write-iops'.

=item B<--critical-*>

Threshold critical.
Can be: 'read', 'write', 'read-iops', 'write-iops',
'total-read', 'total-write', 'total-read-iops', 'total-write-iops',
'sum-read-write', 'sum-read-write-iops'.

=item B<--device>

Set the device (number expected) ex: 1, 2,... (empty means 'check all devices').

=item B<--name>

Allows to use device name with option --device instead of devoce oid index.

=item B<--regexp>

Allows to use regexp to filter devices (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=back

=cut
