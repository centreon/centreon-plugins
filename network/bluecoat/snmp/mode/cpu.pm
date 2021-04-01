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

package network::bluecoat::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All cpu usages are ok' },
    ];
    $self->{maps_counters}->{cpu} = [
        { label => 'usage', set => {
                key_values => [ { name => 'idle', diff => 1 }, { name => 'busy', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_data_calc'),
                output_template => '%.2f %%', output_use => 'used_prct', threshold_use => 'used_prct',
                perfdatas => [
                    { label => 'cpu', value => 'used_prct', template => '%.2f', min => 0, max => 100, unit => '%',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub custom_data_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    my $delta_busy = $options{new_datas}->{$self->{instance} . '_busy'} - $options{old_datas}->{$self->{instance} . '_busy'};
    my $delta_idle = $options{new_datas}->{$self->{instance} . '_idle'} - $options{old_datas}->{$self->{instance} . '_idle'};
    my $total = $delta_busy + $delta_idle;
    $self->{result_values}->{used_prct} = 0;
    if ($total > 0) {
        $self->{result_values}->{used_prct} = ($delta_busy) * 100 / $total;
    }
    return 0;
}

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{display} . "' Usage : ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                });
                                
    return $self;
}

my $mapping = {
    sgProxyCpuCoreBusyTime  => { oid => '.1.3.6.1.4.1.3417.2.11.2.4.1.3' },
    sgProxyCpuCoreIdleTime  => { oid => '.1.3.6.1.4.1.3417.2.11.2.4.1.4' },
};
my $oid_table = '.1.3.6.1.4.1.3417.2.11.2.4.1';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = 'bluecoat_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode}. '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    
    $self->{cpu} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_table, start => $mapping->{sgProxyCpuCoreBusyTime}, end => $mapping->{sgProxyCpuCoreIdleTime}, nothing_quit => 1);
    my $i = 0;
    foreach my $oid ($options{snmp}->oid_lex_sort(keys %{$snmp_result})) {
        next if ($oid !~ /^$mapping->{sgProxyCpuCoreBusyTime}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $self->{cpu}->{$i} = {
            display => $i,
            idle => $result->{sgProxyCpuCoreIdleTime}, busy => $result->{sgProxyCpuCoreBusyTime}
        };
        $i++;
    }
}

1;

__END__

=head1 MODE

Check CPU Usage

=over 8

=item B<--warning-usage>

Threshold warning in percent.

=item B<--critical-usage>

Threshold critical in percent.

=back

=cut
