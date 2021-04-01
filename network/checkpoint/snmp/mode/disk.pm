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

package network::checkpoint::snmp::mode::disk;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_disk_output {
    my ($self, %options) = @_;

    return sprintf(
        'total: %s %s used: %s %s (%.2f%%) free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'disk', type => 1, cb_prefix_output => 'prefix_disk_output', message_multiple => 'All disks are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{disk} = [
        { label => 'usage', nlabel => 'disk.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_disk_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'disk.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_disk_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'disk.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_disk_output {
    my ($self, %options) = @_;

    return "Disk '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

my $mapping = {
    multiDiskName => { oid => '.1.3.6.1.4.1.2620.1.6.7.6.1.2' },
    multiDiskSize => { oid => '.1.3.6.1.4.1.2620.1.6.7.6.1.3' },
    multiDiskUsed => { oid => '.1.3.6.1.4.1.2620.1.6.7.6.1.4' }
};
my $oid_multiDiskEntry = '.1.3.6.1.4.1.2620.1.6.7.6.1';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => 'Need to use SNMP v2c or v3.');
        $self->{output}->option_exit();
    }
    
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_multiDiskEntry,
        start => $mapping->{multiDiskName}->{oid},
        end => $mapping->{multiDiskUsed}->{oid},
        nothing_quit => 1
    );

    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{multiDiskName}->{oid}\.(.*)$/);

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{multiDiskName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{multiDiskName} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{disk}->{ $result->{multiDiskName} } = {
            display => $result->{multiDiskName},
            total => $result->{multiDiskSize},
            prct_used => $result->{multiDiskUsed} * 100 / $result->{multiDiskSize},
            prct_free => 100 - ($result->{multiDiskUsed} * 100 / $result->{multiDiskSize}),
            used => $result->{multiDiskUsed},
            free => $result->{multiDiskSize} - $result->{multiDiskUsed}
        };
    }
}

1;

__END__

=head1 MODE

Check disk usage.

=over 8

=item B<--filter-name>

Filter disk name.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
