#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package network::barracuda::bma::snmp::mode::storage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub prefix_effective_output {
    my ($self, %options) = @_;

    return 'Effective size ';
}

sub prefix_ondisk_output {
    my ($self, %options) = @_;

    return 'On disk size ';
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Storage space ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'effective', type => 0, cb_prefix_output => 'prefix_effective_output', skipped_code => { -10 => 1 } },
        { name => 'ondisk', type => 0, cb_prefix_output => 'prefix_ondisk_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'firmware-space', nlabel => 'storage.firmware.space.usage.percentage', set => {
                key_values => [ { name => 'firmwareStorage' } ],
                output_template => 'firmware used: %.2f%%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'maillog-space', nlabel => 'storage.maillog.space.usage.percentage', set => {
                key_values => [ { name => 'mailLogStorage' } ],
                output_template => 'mail and logs used: %.2f%%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{effective} = [
        { label => 'effective-hourly', nlabel => 'storage.effective.hourly.bytes', set => {
                key_values => [ { name => 'effectiveHour' } ],
                output_template => 'hourly: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'effective-daily', nlabel => 'storage.effective.daily.bytes', set => {
                key_values => [ { name => 'effectiveDay' } ],
                output_template => 'daily: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'effective-delta', nlabel => 'storage.effective.delta.bytespersecond', set => {
                key_values => [ { name => 'effectiveTotal', per_second => 1 } ],
                output_template => 'delta: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B/s' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{ondisk} = [
        { label => 'ondisk-hourly', nlabel => 'storage.ondisk.hourly.bytes', set => {
                key_values => [ { name => 'onDiskSizeHour' } ],
                output_template => 'hourly: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'ondisk-daily', nlabel => 'storage.ondisk.daily.bytes', set => {
                key_values => [ { name => 'onDiskSizeDay' } ],
                output_template => 'daily: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'ondisk-delta', nlabel => 'storage.ondisk.delta.bytespersecond', set => {
                key_values => [ { name => 'onDiskSizeTotal', per_second => 1 } ],
                output_template => 'delta: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B/s' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

my $mapping = {
    firmwareStorage => { oid => '.1.3.6.1.4.1.20632.6.6.5' }, 
    mailLogStorage  => { oid => '.1.3.6.1.4.1.20632.6.6.6' }, 
    effectiveHour   => { oid => '.1.3.6.1.4.1.20632.6.8.1' }, 
    effectiveDay    => { oid => '.1.3.6.1.4.1.20632.6.8.2' },
    effectiveTotal  => { oid => '.1.3.6.1.4.1.20632.6.8.3' },
    onDiskSizeHour  => { oid => '.1.3.6.1.4.1.20632.6.8.4' },
    onDiskSizeDay   => { oid => '.1.3.6.1.4.1.20632.6.8.5' },
    onDiskSizeTotal => { oid => '.1.3.6.1.4.1.20632.6.8.6' }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result);

    $self->{global} = $result;
    $self->{effective} = $result;
    $self->{ondisk} = $result;

    $self->{cache_name} = 'barracuda_bma_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check storage usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'firmware-space', 'maillog-space', 'effective-hourly',
'effective-daily', 'effective-delta', 'ondisk-hourly',
'ondisk-daily', 'ondisk-delta',

=back

=cut
