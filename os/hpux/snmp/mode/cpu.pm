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

package os::hpux::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'user', set => {
                key_values => [ { name => 'total', diff => 1 }, { name => 'user', diff => 1 } ],
                closure_custom_calc => $self->can('custom_data_calc'), closure_custom_calc_extra_options => { label_ref => 'user' },
                output_template => 'User %.2f %%', output_use => 'user_prct', threshold_use => 'user_prct',
                perfdatas => [
                    { label => 'user', value => 'user_prct', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'sys', set => {
                key_values => [ { name => 'total', diff => 1 }, { name => 'sys', diff => 1 } ],
                closure_custom_calc => $self->can('custom_data_calc'), closure_custom_calc_extra_options => { label_ref => 'sys' },
                output_template => 'System %.2f %%', output_use => 'sys_prct', threshold_use => 'sys_prct',
                perfdatas => [
                    { label => 'sys', value => 'sys_prct', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'nice', set => {
                key_values => [ { name => 'total', diff => 1 }, { name => 'nice', diff => 1 } ],
                closure_custom_calc => $self->can('custom_data_calc'), closure_custom_calc_extra_options => { label_ref => 'nice' },
                output_template => 'Nice %.2f %%', output_use => 'nice_prct', threshold_use => 'nice_prct',
                perfdatas => [
                    { label => 'nice', value => 'nice_prct', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'idle', set => {
                key_values => [ { name => 'total', diff => 1 }, { name => 'idle', diff => 1 } ],
                closure_custom_calc => $self->can('custom_data_calc'), closure_custom_calc_extra_options => { label_ref => 'idle' },
                output_template => 'Idle %.2f %%', output_use => 'idle_prct', threshold_use => 'idle_prct',
                perfdatas => [
                    { label => 'idle', value => 'idle_prct', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
}

sub custom_data_calc {
    my ($self, %options) = @_;

    my $label = $options{extra_options}->{label_ref};
    my $delta_value = $options{new_datas}->{$self->{instance} . '_' . $label} - $options{old_datas}->{$self->{instance} . '_' . $label};
    my $delta_total = $options{new_datas}->{$self->{instance} . '_total'} - $options{old_datas}->{$self->{instance} . '_total'};

    $self->{result_values}->{$label . '_prct'} = 0;
    if ($delta_total > 0) {
        $self->{result_values}->{$label . '_prct'} = $delta_value * 100 / $delta_total;
    }
    return 0;
}

sub prefix_output {
    my ($self, %options) = @_;

    return "CPU Usage : ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                "filter-counters:s" => { name => 'filter_counters' },
                                });
                                
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "hpux_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    
    my $oid_computerSystemUserCPU = '.1.3.6.1.4.1.11.2.3.1.1.13.0';
    my $oid_computerSystemSysCPU = '.1.3.6.1.4.1.11.2.3.1.1.14.0';
    my $oid_computerSystemIdleCPU = '.1.3.6.1.4.1.11.2.3.1.1.15.0';
    my $oid_computerSystemNiceCPU = '.1.3.6.1.4.1.11.2.3.1.1.16.0';
    
    my $result = $options{snmp}->get_leef(oids => [$oid_computerSystemUserCPU, $oid_computerSystemSysCPU, 
                                                   $oid_computerSystemIdleCPU, $oid_computerSystemNiceCPU],
                                         nothing_quit => 1);
    $self->{global} = {
        total => $result->{$oid_computerSystemUserCPU} + $result->{$oid_computerSystemSysCPU} + $result->{$oid_computerSystemIdleCPU} + $result->{$oid_computerSystemNiceCPU},
        sys => $result->{$oid_computerSystemSysCPU},
        user => $result->{$oid_computerSystemUserCPU},
        idle => $result->{$oid_computerSystemIdleCPU},
        nice => $result->{$oid_computerSystemNiceCPU},
    };
}
    
1;

__END__

=head1 MODE

Check system CPUs.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example : --filter-counters='^idle$'

=item B<--warning-*>

Threshold warning.
Can be: 'user', 'sys', 'idle', 'nice'.

=item B<--critical-*>

Threshold critical.
Can be: 'user', 'sys', 'idle', 'nice'.

=back

=cut