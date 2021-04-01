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

package hardware::devices::camera::hikvision::snmp::mode::disk;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub custom_disk_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Disk Total: %s %s Used: %s %s (%.2f%%) Free: %s %s (%.2f%%)",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'disk', type => 0 }
    ];
    
    $self->{maps_counters}->{disk} = [
        { label => 'usage', nlabel => 'disk.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_disk_output'),
                perfdatas => [
                    { value => 'used', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1 },
                ],
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'disk.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_disk_output'),
                perfdatas => [
                    { value => 'free', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1 },
                ],
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'disk.usage.percentage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'Disk Used : %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
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

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_diskSize = '.1.3.6.1.4.1.39165.1.8.0';
    my $oid_diskPercent = '.1.3.6.1.4.1.39165.1.9.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [$oid_diskSize, $oid_diskPercent],
        nothing_quit => 1
    );

    if ($snmp_result->{$oid_diskSize} !~ /([0-9\.]+)\s+(\S+)/) {
        $self->{output}->add_option_msg(short_msg => 'cannot parse disk size: ' . $snmp_result->{$oid_diskSize});
        $self->{output}->option_exit();
    }
    my ($total, $unit) = ($1, $2);
    $total = centreon::plugins::misc::convert_bytes(value => $total, unit => $unit);

    if ($snmp_result->{$oid_diskPercent} !~ /([0-9\.]+)/) {
        $self->{output}->add_option_msg(short_msg => 'cannot parse disk used: ' . $snmp_result->{$oid_diskPercent});
        $self->{output}->option_exit();
    }
    my $prct_used = $1;

    $self->{disk} = {
        free => $total * (100 - $prct_used) / 100,
        used => $total * $prct_used / 100,
        prct_used => $prct_used,
        prct_free => 100 - $prct_used,
        total => $total,
    };
}

1;

__END__

=head1 MODE

Check disk usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
