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

package centreon::common::cisco::standard::snmp::mode::load;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu_core', type => 1, cb_prefix_output => 'prefix_cpu_core_output', message_separator => ' ', message_multiple => 'All core cpu loads are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{cpu_core} = [
        { label => 'core-load-1m', nlabel => 'core.cpu.load.1m.count', set => {
                key_values => [ { name => 'cpmCPULoadAvg1min' }, { name => 'display' } ],
                output_template => '%.2f (1m)',
                perfdatas => [
                    { value => 'cpmCPULoadAvg1min', template => '%.2f',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'core-load-5m', nlabel => 'core.cpu.load.5m.count', set => {
                key_values => [ { name => 'cpmCPULoadAvg5min' }, { name => 'display' } ],
                output_template => '%.2f (5m)',
                perfdatas => [
                    { value => 'cpmCPULoadAvg5min', template => '%.2f',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'core-load-15m', nlabel => 'core.cpu.load.15m.count', set => {
                key_values => [ { name => 'cpmCPULoadAvg15min' }, { name => 'display' } ],
                output_template => '%.2f (15m)',
                perfdatas => [
                    { value => 'cpmCPULoadAvg15min', template => '%.2f',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_cpu_core_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{display} . "' load ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $mapping = {
    cpmCPUTotalPhysicalIndex  => { oid => '.1.3.6.1.4.1.9.9.109.1.1.1.1.2' },
    cpmCPULoadAvg1min         => { oid => '.1.3.6.1.4.1.9.9.109.1.1.1.1.24' },
    cpmCPULoadAvg5min         => { oid => '.1.3.6.1.4.1.9.9.109.1.1.1.1.25' },
    cpmCPULoadAvg15min        => { oid => '.1.3.6.1.4.1.9.9.109.1.1.1.1.26' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_cpmCPUTotalEntry = '.1.3.6.1.4.1.9.9.109.1.1.1.1';
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_cpmCPUTotalEntry, start => $mapping->{cpmCPULoadAvg1min}->{oid}, end => $mapping->{cpmCPULoadAvg15min}->{oid} },
            { oid => $mapping->{cpmCPUTotalPhysicalIndex}->{oid} },
        ],
        return_type => 1,
        nothing_quit => 1
    );

    $self->{cpu_core} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{cpmCPULoadAvg1min}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        $self->{cpu_core}->{$instance} = {
            display => $instance,
            %$result
        };
    }

    my $oid_entPhysicalDescr = '.1.3.6.1.2.1.47.1.1.1.1.2';
    $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{cpmCPUTotalPhysicalIndex} != 0 ? $oid_entPhysicalDescr . '.' . $_->{cpmCPUTotalPhysicalIndex} : (), values(%{$self->{cpu_core}})) ]
    );
    foreach (values %{$self->{cpu_core}}) {
        next if (!defined($snmp_result->{ $oid_entPhysicalDescr . '.' . $_->{cpmCPUTotalPhysicalIndex} }));
        $_->{display} = $snmp_result->{ $oid_entPhysicalDescr . '.' . $_->{cpmCPUTotalPhysicalIndex} };
    }
}

1;

__END__

=head1 MODE

Check cpu load usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'core-load-1m', 'core-load-5m', 'core-load-15m'.

=back

=cut
