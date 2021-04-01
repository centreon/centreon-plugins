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

package centreon::common::fortinet::fortigate::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf("memory total: %s %s used: %s %s (%.2f%%) free: %s %s (%.2f%%)",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
    );
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return "Cluster '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'memory', type => 0 },
        { name => 'cluster', type => 1, cb_prefix_output => 'prefix_cluster_output' }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'used', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1 },
                ]
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'free', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1 },
                ]
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'memory used : %.2f %%',
                perfdatas => [
                    { label => 'used_prct', value => 'prct_used', template => '%.2f', min => 0, max => 100,
                      unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cluster} = [
        { label => 'cluster-usage-prct', nlabel => 'cluster.memory.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'memory' } ],
                output_template => 'memory used: %.2f %%',
                perfdatas => [
                    { value => 'memory', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1 },
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'cluster'    => { name => 'cluster' }
    });

    return $self;
}

my $oid_fgSystemInfo = '.1.3.6.1.4.1.12356.101.4.1';
my $oid_fgSysMemUsage = '.1.3.6.1.4.1.12356.101.4.1.4';
my $oid_fgSysMemCapacity = '.1.3.6.1.4.1.12356.101.4.1.5';
my $oid_fgHaSystemMode = '.1.3.6.1.4.1.12356.101.13.1.1'; # '.0' to have the mode
my $oid_fgHaStatsMemUsage = '.1.3.6.1.4.1.12356.101.13.2.1.1.4';
my $oid_fgHaStatsHostname = '.1.3.6.1.4.1.12356.101.13.2.1.1.11';

my $maps_ha_mode = { 1 => 'standalone', 2 => 'activeActive', 3 => 'activePassive' };

sub memory_ha {
    my ($self, %options) = @_;

    $self->{cluster} = {};
    foreach ($options{snmp}->oid_lex_sort(keys %{$options{snmp_result}->{$oid_fgHaStatsMemUsage}})) {
        /\.(\d+)$/;

        $self->{cluster}->{ $options{snmp_result}->{$oid_fgHaStatsHostname}->{$oid_fgHaStatsHostname . '.' . $1} } = {
            display => $options{snmp_result}->{$oid_fgHaStatsHostname}->{$oid_fgHaStatsHostname . '.' . $1},
            memory => $options{snmp_result}->{$oid_fgHaStatsMemUsage}->{$_}
        };
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $table_oids = [ { oid => $oid_fgSystemInfo, start => $oid_fgSysMemUsage, end => $oid_fgSysMemCapacity } ];
    if (defined($self->{option_results}->{cluster})) {
        push @$table_oids, { oid => $oid_fgHaSystemMode },
            { oid => $oid_fgHaStatsMemUsage },
            { oid => $oid_fgHaStatsHostname };
    }

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => $table_oids, 
        nothing_quit => 1
    );

    $self->{memory} = {
        prct_used => $snmp_result->{$oid_fgSystemInfo}->{$oid_fgSysMemUsage . '.0'},
        total => $snmp_result->{$oid_fgSystemInfo}->{$oid_fgSysMemCapacity . '.0'} * 1024
    };
    $self->{memory}->{prct_free} = 100 - $self->{memory}->{prct_used};
    $self->{memory}->{used} = int(($self->{memory}->{total} * $self->{memory}->{prct_used}) / 100);
    $self->{memory}->{free} = $self->{memory}->{total} - $self->{memory}->{used};

    if (defined($self->{option_results}->{cluster})) {
        my $ha_mode = $snmp_result->{$oid_fgHaSystemMode}->{$oid_fgHaSystemMode . '.0'};
        my $ha_mode_str = defined($maps_ha_mode->{$ha_mode}) ? $maps_ha_mode->{$ha_mode} : 'unknown';
        $self->{output}->output_add(long_msg => 'high availabily mode is ' . $ha_mode_str);
        if ($ha_mode_str =~ /active/) {
            $self->memory_ha(snmp => $options{snmp}, snmp_result => $snmp_result);
        }
    }
}

1;

__END__

=head1 MODE

Check system memory usage (FORTINET-FORTIGATE).

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage-free', 'usage-prct', 'cluster-usage-prct'.

=item B<--cluster>

Add cluster memory informations.

=back

=cut
