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

package network::radware::alteon::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'mp_cpu', type => 0, cb_prefix_output => 'prefix_mp_cpu_output', skipped_code => { -10 => 1 } },
        { name => 'sp_ga_avg', type => 0, skipped_code => { -10 => 1 } },
        { name => 'sp_ga', type => 1, cb_init => 'skip_sp_ga', cb_prefix_output => 'prefix_sp_ga_output', message_multiple => 'All SP GA CPU are ok' },
    ];
    
    $self->{maps_counters}->{mp_cpu} = [
        { label => 'mp-1s', set => {
                key_values => [ { name => 'mp_1s' } ],
                output_template => '%.2f%% (1sec)',
                perfdatas => [
                    { label => 'mp_cpu_1s', value => 'mp_1s', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'mp-4s', set => {
                key_values => [ { name => 'mp_4s' } ],
                output_template => '%.2f%% (4sec)',
                perfdatas => [
                    { label => 'mp_cpu_4s', value => 'mp_4s', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'mp-64s', set => {
                key_values => [ { name => 'mp_64s' } ],
                output_template => '%.2f%% (64sec)',
                perfdatas => [
                    { label => 'mp_cpu_64s', value => 'mp_64s', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{sp_ga_avg} = [
        { label => 'sp-ga-avg-1s', set => {
                key_values => [ { name => 'sp_1s' } ],
                output_template => 'SP GA Average CPU Usage: %.2f%% (1sec)',
                perfdatas => [
                    { label => 'avg_spga_cpu_1s', value => 'sp_1s', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'sp-ga-avg-4s', set => {
                key_values => [ { name => 'sp_4s' } ],
                output_template => '%.2f%% (4sec)',
                perfdatas => [
                    { label => 'avg_spga_cpu_4s', value => 'sp_4s', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'sp-ga-avg-64s', set => {
                key_values => [ { name => 'sp_64s' } ],
                output_template => '%.2f%% (64sec)',
                perfdatas => [
                    { label => 'avg_spga_cpu_64s', value => 'sp_64s', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{sp_ga} = [
        { label => 'sp-ga-1s', set => {
                key_values => [ { name => 'sp_1s' }, { name => 'display' } ],
                output_template => '%.2f%% (1sec)',
                perfdatas => [
                    { label => 'spga_cpu_1s', value => 'sp_1s', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'sp-ga-4s', set => {
                key_values => [ { name => 'sp_4s' }, { name => 'display' } ],
                output_template => '%.2f%% (4sec)',
                perfdatas => [
                    { label => 'spga_cpu_4s', value => 'sp_4s', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'sp-ga-64s', set => {
                key_values => [ { name => 'sp_64s' }, { name => 'display' } ],
                output_template => '%.2f%% (64sec)',
                perfdatas => [
                    { label => 'spga_cpu_64s', value => 'sp_64s', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_mp_cpu_output {
    my ($self, %options) = @_;
    
    return "MP CPU Usage: ";
}

sub prefix_sp_ga_output {
    my ($self, %options) = @_;
    
    return "SP GA CPU '" . $options{instance_value}->{display} . "' Usage: ";
}

sub skip_sp_ga {
    my ($self, %options) = @_;

    scalar(keys %{$self->{sp_ga}}) <= 0 ? return(1) : return(0);
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
    mpCpuStatsUtil1Second   => { oid => '.1.3.6.1.4.1.1872.2.5.1.2.2.1' },
    mpCpuStatsUtil4Seconds  => { oid => '.1.3.6.1.4.1.1872.2.5.1.2.2.2' },
    mpCpuStatsUtil64Seconds => { oid => '.1.3.6.1.4.1.1872.2.5.1.2.2.3' },
};
my $mapping2 = {
    spGAStatsCpuUtil1Second     => { oid => '.1.3.6.1.4.1.1872.2.5.1.2.13.1.1.3' },
    spGAStatsCpuUtil4Seconds    => { oid => '.1.3.6.1.4.1.1872.2.5.1.2.13.1.1.4' },
    spGAStatsCpuUtil64Seconds   => { oid => '.1.3.6.1.4.1.1872.2.5.1.2.13.1.1.5' },
};
my $oid_mpCpuStats = '.1.3.6.1.4.1.1872.2.5.1.2.2';
my $oid_spGAStatsCpuUtilTableEntry = '.1.3.6.1.4.1.1872.2.5.1.2.13.1.1';

sub manage_selection {
    my ($self, %options) = @_;
  
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ { oid => $oid_mpCpuStats }, { oid => $oid_spGAStatsCpuUtilTableEntry } ],
        return_type => 1, nothing_quit => 1);
    $self->{sp_ga} = {};
    my ($avg_sp_1s, $avg_sp_4s, $avg_sp_64s) = (0, 0, 0);
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping2->{spGAStatsCpuUtil64Seconds}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $instance);

        $self->{sp_ga}->{$instance} = {
            display => $instance,
            sp_1s   => $result->{spGAStatsCpuUtil1Second},
            sp_4s   => $result->{spGAStatsCpuUtil4Seconds},
            sp_64s  => $result->{spGAStatsCpuUtil64Seconds},
        };
        $avg_sp_1s += $result->{spGAStatsCpuUtil1Second};
        $avg_sp_4s += $result->{spGAStatsCpuUtil4Seconds};
        $avg_sp_64s += $result->{spGAStatsCpuUtil64Seconds};
    }

    $self->{sp_ga_avg} = {};
    if (scalar(keys %{$self->{sp_ga}}) > 1) {
        $self->{sp_ga_avg} = {
            sp_1s   => $avg_sp_1s / scalar(keys %{$self->{sp_ga}}),
            sp_4s   => $avg_sp_4s / scalar(keys %{$self->{sp_ga}}),
            sp_64s  => $avg_sp_64s / scalar(keys %{$self->{sp_ga}}),
        };
    }

    $self->{mp_cpu} = { 
        mp_1s => $snmp_result->{$mapping->{mpCpuStatsUtil1Second}->{oid} . '.0'}, 
        mp_4s => $snmp_result->{$mapping->{mpCpuStatsUtil4Seconds}->{oid} . '.0'}, 
        mp_64s => $snmp_result->{$mapping->{mpCpuStatsUtil64Seconds}->{oid} . '.0'}, 
    };
}

1;

__END__

=head1 MODE

Check MP cpu usage (ALTEON-CHEETAH-SWITCH-MIB).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(64s)$'

=item B<--warning-*>

Threshold warning.
Can be: 'mp-1s', 'mp-4s', 'mp-64s', 
'sp-ga-1s', 'sp-ga-4s', 'sp-ga-64s',
'sp-ga-avg-1s', 'sp-ga-avg-4s', 'sp-ga-avg-64s'.

=item B<--critical-*>

Threshold critical.
Can be: 'mp-1s', 'mp-4s', 'mp-64s', 
'sp-ga-1s', 'sp-ga-4s', 'sp-ga-64s',
'sp-ga-avg-1s', 'sp-ga-avg-4s', 'sp-ga-avg-64s'.

=back

=cut
    
