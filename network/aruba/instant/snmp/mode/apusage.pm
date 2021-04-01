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

package network::aruba::instant::snmp::mode::apusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = "Status is '" . $self->{result_values}->{status} . "'";
    return $msg;
}

sub custom_memory_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Memory Total: %s %s Used: %s %s (%.2f%%) Free: %s %s (%.2f%%)",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free});
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'ap', type => 1, cb_prefix_output => 'prefix_ap_output',
          message_multiple => 'All access points are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-ap', nlabel => 'accesspoints.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total access points: %s',
                perfdatas => [
                    { value => 'total', template => '%s', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{ap} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'clients', nlabel => 'clients.current.count', set => {
                key_values => [ { name => 'clients' }, { name => 'display' } ],
                output_template => 'Current Clients: %s',
                perfdatas => [
                    { label => 'clients', value => 'clients', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'cpu', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu' }, { name => 'display' } ],
                output_template => 'Cpu: %.2f%%',
                perfdatas => [
                    { label => 'cpu', value => 'cpu', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'mem-usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' },
                    { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { label => 'mem_used', value => 'used', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'mem-usage-free', display_ok => 0, nlabel => 'memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' },
                    { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { label => 'mem_free', value => 'free', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'mem-usage-prct', display_ok => 0, nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'Memory Used: %.2f %%',
                perfdatas => [
                    { label => 'mem_used_prct', value => 'prct_used', template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' },
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
        'filter-name:s'     => { name => 'filter_name' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} !~ /up/i' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_ap_output {
    my ($self, %options) = @_;
    
    return "Access Point '" . $options{instance_value}->{display} . "' ";
}

my $map_ap_status = {
    1 => 'up', 2 => 'down'
};

my $mapping = {
    aiAPName            => { oid => '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.2' },
    aiAPIPAddress       => { oid => '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.3' },
    aiAPCPUUtilization  => { oid => '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.7' },
    aiAPMemoryFree      => { oid => '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.8' },
    aiAPTotalMemory     => { oid => '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.10' },
    aiAPStatus          => { oid => '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.11', map => $map_ap_status },
};
my $oid_aiAccessPointEntry = '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1';
my $oid_aiClientAPIPAddress = '.1.3.6.1.4.1.14823.2.3.3.1.2.4.1.4';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_aiAccessPointEntry, start => $mapping->{aiAPName}->{oid}, end => $mapping->{aiAPStatus}->{oid} },
            { oid => $oid_aiClientAPIPAddress },
         ], 
    );

    my $link_ap = {};
    $self->{global} = { total => 0 };
    $self->{ap} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_aiAccessPointEntry}}) {
        next if ($oid !~ /^$mapping->{aiAPName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_aiAccessPointEntry}, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{aiAPName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping access point '" . $result->{aiAPName} . "'.", debug => 1);
            next;
        }

        $self->{global}->{total}++;
        $self->{ap}->{$result->{aiAPName}} = {
            display => $result->{aiAPName},
            status => $result->{aiAPStatus},
            cpu => $result->{aiAPCPUUtilization},
            total => $result->{aiAPTotalMemory},
            free => $result->{aiAPMemoryFree},
            used => $result->{aiAPTotalMemory} - $result->{aiAPMemoryFree},
            prct_free => $result->{aiAPMemoryFree} * 100 / $result->{aiAPTotalMemory},
            prct_used => 100 - ($result->{aiAPMemoryFree} * 100 / $result->{aiAPTotalMemory}),
            clients => 0,
        };
        $link_ap->{$result->{aiAPIPAddress}} = $self->{ap}->{$result->{aiAPName}};
    }

    if (scalar(keys %{$snmp_result->{$oid_aiAccessPointEntry}}) == 0 && scalar(keys %{$snmp_result->{$oid_aiClientAPIPAddress}}) > 0) {
        $self->{ap}->{default} = {
            display => 'default',
            clients => 0,
        };
    }

    foreach my $oid (keys %{$snmp_result->{$oid_aiClientAPIPAddress}}) {
        my $ap_ipaddress = $snmp_result->{$oid_aiClientAPIPAddress}->{$oid};
        if (defined($link_ap->{$ap_ipaddress})) {
            $link_ap->{$ap_ipaddress}->{clients}++;
        } else {
            $self->{ap}->{default}->{clients}++;
        }
    }
}

1;

__END__

=head1 MODE

Check access point usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^cpu$'

=item B<--filter-name>

Filter access point name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /up/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-ap', 'cpu', 'clients', 
'mem-usage' (B), 'mem-usage-free' (B), 'mem-usage-prct' (%).

=back

=cut
