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

package storage::netapp::ontap::snmp::mode::globalstatus;

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
        { label => 'read', nlabel => 'storage.io.read.usage.bytespersecond', set => {
                key_values => [ { name => 'read', per_second => 1 } ],
                output_template => 'Read I/O : %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0 }
                ]
            }
        },
        { label => 'write', nlabel => 'storage.io.write.usage.bytespersecond', set => {
                key_values => [ { name => 'write', per_second => 1 } ],
                output_template => 'Write I/O : %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0 }
                ]
            }
        }
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

sub manage_selection {
    my ($self, %options) = @_;
    
    my $request = [
        $oid_fsOverallStatus, $oid_fsStatusMessage,
        $oid_miscGlobalStatus, $oid_miscGlobalStatusMessage, 
        $oid_miscHighDiskReadBytes, $oid_miscLowDiskReadBytes,
        $oid_miscHighDiskWriteBytes, $oid_miscLowDiskWriteBytes
    ];
    if (!$options{snmp}->is_snmpv1()) {
        push @{$request}, ($oid_misc64DiskReadBytes, $oid_misc64DiskWriteBytes);
    }
    
    my $snmp_result = $options{snmp}->get_leef(oids => $request, nothing_quit => 1);
    
    $self->{global} = {};
    $self->{global}->{read} = defined($snmp_result->{$oid_misc64DiskReadBytes}) ?
                                $snmp_result->{$oid_misc64DiskReadBytes} : 
                                ($snmp_result->{$oid_miscHighDiskReadBytes} << 32) + $snmp_result->{$oid_miscLowDiskReadBytes};
    $self->{global}->{write} = defined($snmp_result->{$oid_misc64DiskWriteBytes}) ?
                                $snmp_result->{$oid_misc64DiskWriteBytes} : 
                                ($snmp_result->{$oid_miscHighDiskWriteBytes} << 32) + $snmp_result->{$oid_miscLowDiskWriteBytes};

    $snmp_result->{$oid_miscGlobalStatusMessage} =~ s/\n//g;
    $self->{output}->output_add(severity =>  ${$states{$snmp_result->{$oid_miscGlobalStatus}}}[1],
                                short_msg => sprintf("Overall global status is '%s' [message: '%s']", 
                                                ${$states{$snmp_result->{$oid_miscGlobalStatus}}}[0], $snmp_result->{$oid_miscGlobalStatusMessage}));
    $snmp_result->{$oid_fsStatusMessage} =~ s/\n//g;
    $self->{output}->output_add(severity =>  ${$fs_states{$snmp_result->{$oid_fsOverallStatus}}}[1],
                                short_msg => sprintf("Overall file system status is '%s' [message: '%s']", 
                                                ${$fs_states{$snmp_result->{$oid_fsOverallStatus}}}[0], $snmp_result->{$oid_fsStatusMessage}));

    $self->{cache_name} = "cache_netapp_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
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
    
