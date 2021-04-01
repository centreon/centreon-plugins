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

package storage::purestorage::snmp::mode::stats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'read-bandwidth', set => {
                key_values => [ { name => 'pureArrayReadBandwidth' }, ],
                output_change_bytes => 2,
                output_template => 'Read Bandwith : %s %s/s',
                perfdatas => [
                    { label => 'read_bandwidth', value => 'pureArrayReadBandwidth', template => '%.2f',
                      min => 0, unit => 'b/s' },
                ],
            }
        },
        { label => 'write-bandwidth', set => {
                key_values => [ { name => 'pureArrayWriteBandwidth' }, ],
                output_change_bytes => 2,
                output_template => 'Write Bandwith : %s %s/s',
                perfdatas => [
                    { label => 'write_bandwidth', value => 'pureArrayWriteBandwidth', template => '%.2f',
                      min => 0, unit => 'b/s' },
                ],
            }
        },
        { label => 'read-iops', set => {
                key_values => [ { name => 'pureArrayReadIOPS' } ],
                output_template => 'Read IOPs : %s',
                perfdatas => [
                    { label => 'read_iops', value => 'pureArrayReadIOPS', template => '%s',
                      unit => 'iops', min => 0 },
                ],
            }
        },
        { label => 'write-iops', set => {
                key_values => [ { name => 'pureArrayWriteIOPS' } ],
                output_template => 'Write IOPs : %s',
                perfdatas => [
                    { label => 'write_iops', value => 'pureArrayWriteIOPS', template => '%s',
                      unit => 'iops', min => 0 },
                ],
            }
        },
        { label => 'read-latency', set => {
                key_values => [ { name => 'pureArrayReadLatency' } ],
                output_template => 'Read Latency : %s us/op',
                perfdatas => [
                    { label => 'read_latency', value => 'pureArrayReadLatency', template => '%s',
                      unit => 'us/op', min => 0 },
                ],
            }
        },
        { label => 'write-latency', set => {
                key_values => [ { name => 'pureArrayWriteLatency' } ],
                output_template => 'Write Latency : %s us/op',
                perfdatas => [
                    { label => 'write_latency', value => 'pureArrayWriteLatency', template => '%s',
                      unit => 'us/op', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

my $mapping = {
    pureArrayReadBandwidth  => { oid => '.1.3.6.1.4.1.40482.4.1' },
    pureArrayWriteBandwidth => { oid => '.1.3.6.1.4.1.40482.4.2' },
    pureArrayReadIOPS       => { oid => '.1.3.6.1.4.1.40482.4.3' },
    pureArrayWriteIOPS      => { oid => '.1.3.6.1.4.1.40482.4.4' },
    pureArrayReadLatency    => { oid => '.1.3.6.1.4.1.40482.4.5' },
    pureArrayWriteLatency   => { oid => '.1.3.6.1.4.1.40482.4.6' },
};
my $oid_purePerformance = '.1.3.6.1.4.1.40482.4';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_purePerformance,
                                                nothing_quit => 1);
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');

    $result->{pureArrayReadBandwidth} *= 8;
    $result->{pureArrayWriteBandwidth} *= 8;
    
    $self->{global} = { %$result };
}

1;

__END__

=head1 MODE

Check statistics performance.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='bandwidth'

=item B<--warning-*>

Threshold warning.
Can be: 'read-bandwidth', 'write-bandwidth', 'read-iops', 'write-iops',
'read-latency', 'write-latency'.

=item B<--critical-*>

Threshold critical.
Can be: 'read-bandwidth', 'write-bandwidth', 'read-iops', 'write-iops',
'read-latency', 'write-latency'.

=back

=cut
