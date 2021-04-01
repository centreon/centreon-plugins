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

package network::f5::bigip::snmp::mode::tmmusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'memory_used', unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct_used}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    
    my $msg = sprintf("Memory Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                      $total_size_value . " " . $total_size_unit,
                      $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                      $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    return - 10 if ($options{new_datas}->{$self->{instance} . '_sysTmmStatMemoryTotal'} == 0);
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_sysTmmStatMemoryTotal'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_sysTmmStatMemoryUsed'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'tmm', type => 1, cb_prefix_output => 'prefix_tmm_output', message_multiple => 'All TMM are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{tmm} = [
        { label => 'memory-usage', set => {
                key_values => [ { name => 'display' }, { name => 'sysTmmStatMemoryTotal' }, { name => 'sysTmmStatMemoryUsed' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'cpu-1m', set => {
                key_values => [ { name => 'sysTmmStatTmUsageRatio1m' }, { name => 'display' } ],
                output_template => 'CPU Usage 1min : %s %%', output_error_template => "CPU Usage 1min : %s",
                perfdatas => [
                    { label => 'cpu_1m', value => 'sysTmmStatTmUsageRatio1m',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'cpu-5m', set => {
                key_values => [ { name => 'sysTmmStatTmUsageRatio5m' }, { name => 'display' } ],
                output_template => 'CPU Usage 5min : %s %%', output_error_template => "CPU Usage 5min : %s",
                perfdatas => [
                    { label => 'cpu_5m', value => 'sysTmmStatTmUsageRatio5m',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'current-client-connections', set => {
                key_values => [ { name => 'sysTmmStatClientCurConns' }, { name => 'display' } ],
                output_template => 'Current Client Connections : %s', output_error_template => "Current Client Connections : %s",
                perfdatas => [
                    { label => 'current_client_connections', value => 'sysTmmStatClientCurConns',  template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-client-connections', set => {
                key_values => [ { name => 'sysTmmStatClientTotConns', diff => 1 }, { name => 'display' } ],
                output_template => 'Total Client Connections : %s', output_error_template => "Total Client Connections : %s",
                perfdatas => [
                    { label => 'total_client_connections', value => 'sysTmmStatClientTotConns',  template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'current-server-connections', set => {
                key_values => [ { name => 'sysTmmStatServerCurConns' }, { name => 'display' } ],
                output_template => 'Current Server Connections : %s', output_error_template => "Current Server Connections : %s",
                perfdatas => [
                    { label => 'current_server_connections', value => 'sysTmmStatServerCurConns',  template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-server-connections', set => {
                key_values => [ { name => 'sysTmmStatServerTotConns', diff => 1 }, { name => 'display' } ],
                output_template => 'Total Server Connections : %s', output_error_template => "Total Server Connections : %s",
                perfdatas => [
                    { label => 'total_server_connections', value => 'sysTmmStatServerTotConns',  template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_tmm_output {
    my ($self, %options) = @_;
    
    return "TMM '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
    });

    return $self;
}

my $mapping = {
    sysTmmStatTmmId             => { oid => '.1.3.6.1.4.1.3375.2.1.8.2.3.1.1' },
    sysTmmStatClientTotConns    => { oid => '.1.3.6.1.4.1.3375.2.1.8.2.3.1.11' },
    sysTmmStatClientCurConns    => { oid => '.1.3.6.1.4.1.3375.2.1.8.2.3.1.12' },
    sysTmmStatServerTotConns    => { oid => '.1.3.6.1.4.1.3375.2.1.8.2.3.1.18' },
    sysTmmStatServerCurConns    => { oid => '.1.3.6.1.4.1.3375.2.1.8.2.3.1.19' },
    sysTmmStatMemoryTotal       => { oid => '.1.3.6.1.4.1.3375.2.1.8.2.3.1.31' }, # B
    sysTmmStatMemoryUsed        => { oid => '.1.3.6.1.4.1.3375.2.1.8.2.3.1.32' }, # B
    sysTmmStatTmUsageRatio1m    => { oid => '.1.3.6.1.4.1.3375.2.1.8.2.3.1.38' },
    sysTmmStatTmUsageRatio5m    => { oid => '.1.3.6.1.4.1.3375.2.1.8.2.3.1.39' },
};
my $oid_sysTmmStatEntry = '.1.3.6.1.4.1.3375.2.1.8.2.3.1';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    
    my $results = $options{snmp}->get_table(
        oid => $oid_sysTmmStatEntry,
        nothing_quit => 1
    );
    
    $self->{tmm} = {};
    foreach my $oid (keys %$results) {
        next if ($oid !~ /^$mapping->{sysTmmStatTmmId}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{sysTmmStatTmmId} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{sysTmmStatTmmId} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{tmm}->{$result->{sysTmmStatTmmId}} = { 
            display => $result->{sysTmmStatTmmId},
            %$result
        };
    }
    
    if (scalar(keys %{$self->{tmm}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No TMM found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "f5_bipgip_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check TMM usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example : --filter-counters='^memory-usage$'

=item B<--filter-name>

Filter by TMM name (regexp can be used).

=item B<--warning-*>

Threshold warning.
Can be: 'cpu-1m', 'cpu-5m', 'memory-usage' (%), 'total-client-connections', 'current-client-connections',
'total-server-connections', 'current-server-connections'.

=item B<--critical-*>

Threshold critical.
Can be: 'cpu-1m', 'cpu-5m', 'memory-usage' (%), 'total-client-connections', 'current-client-connections',
'total-server-connections', 'current-server-connections'.

=back

=cut
