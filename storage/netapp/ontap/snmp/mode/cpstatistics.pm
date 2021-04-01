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

package storage::netapp::ontap::snmp::mode::cpstatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1, -11 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'timer', nlabel => 'storage.cp.timer.operations.count', display_ok => 0, set => {
                key_values => [ { name => 'timer', diff => 1 }, ],
                output_template => 'CP timer : %s',
                perfdatas => [
                    { value => 'timer', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'snapshot', nlabel => 'storage.cp.snapshot.operations.count', display_ok => 0, set => {
                key_values => [ { name => 'snapshot', diff => 1 }, ],
                output_template => 'CP snapshot : %s',
                perfdatas => [
                    { value => 'snapshot', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'lowerwater', nlabel => 'storage.cp.lowerwatermark.operations.count', display_ok => 0, set => {
                key_values => [ { name => 'lowerwater', diff => 1 }, ],
                output_template => 'CP low water mark : %s',
                perfdatas => [
                    { value => 'lowerwater', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'highwater', nlabel => 'storage.cp.highwatermark.operations.count', display_ok => 0, set => {
                key_values => [ { name => 'highwater', diff => 1 }, ],
                output_template => 'CP high water mark : %s',
                perfdatas => [
                    { value => 'highwater', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'logfull', nlabel => 'storage.cp.logfull.operations.count', display_ok => 0, set => {
                key_values => [ { name => 'logfull', diff => 1 }, ],
                output_template => 'CP nv-log full : %s',
                perfdatas => [
                    { value => 'logfull', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'back', nlabel => 'storage.cp.back2back.operations.count', display_ok => 0, set => {
                key_values => [ { name => 'back', diff => 1 }, ],
                output_template => 'CP back-to-back : %s',
                perfdatas => [
                    { value => 'back', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'flush', nlabel => 'storage.cp.flushunlog.operations.count', display_ok => 0, set => {
                key_values => [ { name => 'flush', diff => 1 }, ],
                output_template => 'CP flush unlogged write data : %s',
                perfdatas => [
                    { value => 'flush', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'sync', nlabel => 'storage.cp.syncrequests.operations.count', display_ok => 0, set => {
                key_values => [ { name => 'sync', diff => 1 }, ],
                output_template => 'CP sync requests : %s',
                perfdatas => [
                    { value => 'sync', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'lowvbuf', nlabel => 'storage.cp.lowvirtualbuffers.operations.count', display_ok => 0, set => {
                key_values => [ { name => 'lowvbuf', diff => 1 }, ],
                output_template => 'CP low virtual buffers : %s',
                perfdatas => [
                    { value => 'lowvbuf', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'deferred', nlabel => 'storage.cp.deferred.operations.count', display_ok => 0, set => {
                key_values => [ { name => 'deferred', diff => 1 }, ],
                output_template => 'CP deferred : %s',
                perfdatas => [
                    { value => 'deferred', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'lowdatavecs', nlabel => 'storage.cp.lowdatavecs.operations.count', display_ok => 0, set => {
                key_values => [ { name => 'lowdatavecs', diff => 1 }, ],
                output_template => 'CP low datavecs : %s',
                perfdatas => [
                    { value => 'lowdatavecs', template => '%d', min => 0 },
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

my $oid_cpFromTimerOps = '.1.3.6.1.4.1.789.1.2.6.2.0';
my $oid_cpFromSnapshotOps = '.1.3.6.1.4.1.789.1.2.6.3.0';
my $oid_cpFromLowWaterOps = '.1.3.6.1.4.1.789.1.2.6.4.0';
my $oid_cpFromHighWaterOps = '.1.3.6.1.4.1.789.1.2.6.5.0';
my $oid_cpFromLogFullOps = '.1.3.6.1.4.1.789.1.2.6.6.0';
my $oid_cpFromCpOps = '.1.3.6.1.4.1.789.1.2.6.7.0';
my $oid_cpTotalOps = '.1.3.6.1.4.1.789.1.2.6.8.0';
my $oid_cpFromFlushOps = '.1.3.6.1.4.1.789.1.2.6.9.0';
my $oid_cpFromSyncOps = '.1.3.6.1.4.1.789.1.2.6.10.0';
my $oid_cpFromLowVbufOps = '.1.3.6.1.4.1.789.1.2.6.11.0';
my $oid_cpFromCpDeferredOps = '.1.3.6.1.4.1.789.1.2.6.12.0';
my $oid_cpFromLowDatavecsOps = '.1.3.6.1.4.1.789.1.2.6.13.0';

sub manage_selection {
    my ($self, %options) = @_;

    my $request = [
        $oid_cpFromTimerOps, $oid_cpFromSnapshotOps,
        $oid_cpFromLowWaterOps, $oid_cpFromHighWaterOps,
        $oid_cpFromLogFullOps, $oid_cpFromCpOps,
        $oid_cpTotalOps, $oid_cpFromFlushOps,
        $oid_cpFromSyncOps, $oid_cpFromLowVbufOps,
        $oid_cpFromCpDeferredOps, $oid_cpFromLowDatavecsOps
    ];
    
    my $snmp_result = $options{snmp}->get_leef(oids => $request, nothing_quit => 1);

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'All CP statistics are ok'
    );

    $self->{global} = {};
    $self->{global}->{timer} = defined($snmp_result->{$oid_cpFromTimerOps}) ? $snmp_result->{$oid_cpFromTimerOps} : undef;
    $self->{global}->{snapshot} = defined($snmp_result->{$oid_cpFromSnapshotOps}) ? $snmp_result->{$oid_cpFromSnapshotOps} : undef;
    $self->{global}->{lowerwater} = defined($snmp_result->{$oid_cpFromLowWaterOps}) ? $snmp_result->{$oid_cpFromLowWaterOps} : undef;
    $self->{global}->{highwater} = defined($snmp_result->{$oid_cpFromHighWaterOps}) ? $snmp_result->{$oid_cpFromHighWaterOps} : undef;
    $self->{global}->{logfull} = defined($snmp_result->{$oid_cpFromLogFullOps}) ? $snmp_result->{$oid_cpFromLogFullOps} : undef;
    $self->{global}->{back} = defined($snmp_result->{$oid_cpFromCpOps}) ? $snmp_result->{$oid_cpFromCpOps} : undef;
    $self->{global}->{flush} = defined($snmp_result->{$oid_cpFromFlushOps}) ? $snmp_result->{$oid_cpFromFlushOps} : undef;
    $self->{global}->{sync} = defined($snmp_result->{$oid_cpFromSyncOps}) ? $snmp_result->{$oid_cpFromSyncOps} : undef;
    $self->{global}->{lowvbuf} = defined($snmp_result->{$oid_cpFromLowVbufOps}) ? $snmp_result->{$oid_cpFromLowVbufOps} : undef;
    $self->{global}->{deferred} = defined($snmp_result->{$oid_cpFromCpDeferredOps}) ? $snmp_result->{$oid_cpFromCpDeferredOps} : undef;
    $self->{global}->{lowdatavecs} = defined($snmp_result->{$oid_cpFromLowDatavecsOps}) ? $snmp_result->{$oid_cpFromLowDatavecsOps} : undef;

    $self->{cache_name} = "cache_netapp_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check consistency point metrics.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'timer', 'snapshot', 'lowerwater', 'highwater', 
'logfull', 'back', 'flush', 'sync', 'lowvbuf', 'deferred', 'lowdatavecs'.

=item B<--critical-*>

Threshold critical.
Can be: 'timer', 'snapshot', 'lowerwater', 'highwater', 
'logfull', 'back', 'flush', 'sync', 'lowvbuf', 'deferred', 'lowdatavecs'.

=back

=cut
    
