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

package storage::nimble::snmp::mode::globalstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'read', nlabel => 'system.io.read.usage.bytespersecond', set => {
                key_values => [ { name => 'read', per_second => 1 } ],
                output_template => 'Read I/O : %s %s/s', output_error_template => "Read I/O : %s",
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'read', template => '%d', unit => 'B/s' },
                ],
            }
        },
        { label => 'write', nlabel => 'system.io.write.usage.bytespersecond', set => {
                key_values => [ { name => 'write', per_second => 1 } ],
                output_template => 'Write I/O : %s %s/s', output_error_template => "Write I/O : %s",
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'write', template => '%d', unit => 'B/s', min => 0 },
                ],
            }
        },
        { label => 'read-iops', nlabel => 'system.io.read.usage.iops', set => {
                key_values => [ { name => 'read_iops', per_second => 1 } ],
                output_template => 'Read IOPs : %.2f', output_error_template => "Read IOPs : %s",
                perfdatas => [
                    { label => 'read_iops', template => '%.2f', unit => 'iops', min => 0 },
                ],
            }
        },
        { label => 'write-iops', nlabel => 'system.io.write.usage.iops', set => {
                key_values => [ { name => 'write_iops', per_second => 1 } ],
                output_template => 'Write IOPs : %.2f', output_error_template => "Write IOPs : %s",
                perfdatas => [
                    { label => 'write_iops', template => '%.2f', unit => 'iops', min => 0 },
                ],
            }
        },
        { label => 'read-time', nlabel => 'system.io.read.time.seconds', set => {
                key_values => [ { name => 'read_time', diff => 1 } ],
                output_template => 'Read Time : %.3f s', output_error_template => "Read Time : %s",
                perfdatas => [
                    { label => 'read_time', template => '%.3f', unit => 's', min => 0 },
                ],
            }
        },
        { label => 'write-time', nlabel => 'system.io.write.time.seconds', set => {
                key_values => [ { name => 'write_time', diff => 1 } ],
                output_template => 'Write Time : %.3f s', output_error_template => "Write Time : %s",
                perfdatas => [
                    { label => 'write_time', template => '%.3f', unit => 's', min => 0 },
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
    });

    return $self;
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
    my $result = $options{snmp}->get_table(
        oid => $oid_globalStats,
        nothing_quit => 1
    );
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
