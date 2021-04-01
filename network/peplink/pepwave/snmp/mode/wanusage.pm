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

package network::peplink::pepwave::snmp::mode::wanusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf('health status : %s', $self->{result_values}->{health_status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{health_status} = $options{new_datas}->{$self->{instance} . '_health_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'wan', type => 1, cb_prefix_output => 'prefix_wan_output', message_multiple => 'All WANs are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{wan} = [
        { label => 'health-status', threshold => 0, set => {
                key_values => [ { name => 'health_status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'signal', set => {
                key_values => [ { name => 'signal' }, { name => 'display' } ],
                output_template => 'Signal Strength : %s dBm',
                perfdatas => [
                    { label => 'signal', template => '%s', unit => 'dBm', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-in', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', template => '%d', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', template => '%d',  min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }
    ];
}

sub prefix_wan_output {
    my ($self, %options) = @_;
    
    return "WAN '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s'            => { name => 'filter_name' },
        'warning-health-status:s'  => { name => 'warning_health_status', default => '' },
        'critical-health-status:s' => { name => 'critical_health_status', default => '%{health_status} =~ /fail/' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_health_status', 'critical_health_status']);
}

my %mapping_health = (
    0 => 'fail',
    1 => 'success',
);

my $mapping = {
    wanName             => { oid => '.1.3.6.1.4.1.27662.2.1.2.1.2' },
    wanHealthCheckState => { oid => '.1.3.6.1.4.1.27662.2.1.2.1.4', map => \%mapping_health },
    wanSignal           => { oid => '.1.3.6.1.4.1.27662.2.1.2.1.5' },
};
my $mapping2 = {
    wanDataUsageTxByte  => { oid => '.1.3.6.1.4.1.27662.2.1.4.1.2' },
    wanDataUsageRxByte  => { oid => '.1.3.6.1.4.1.27662.2.1.4.1.3' },
};
my $oid_wanEntry = '.1.3.6.1.4.1.27662.2.1.2.1';
my $oid_wanDataUsageEntry = '.1.3.6.1.4.1.27662.2.1.4.1';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    
    $self->{wan} = {};
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
        { oid => $oid_wanEntry, start => $mapping->{wanName}->{oid}, end => $mapping->{wanSignal}->{oid} },
        { oid => $oid_wanDataUsageEntry },
    ], nothing_quit => 1);
    foreach my $oid (keys %{$snmp_result->{$oid_wanEntry}}) {
        next if ($oid !~ /^$mapping->{wanName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_wanEntry}, instance => $instance);
        my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_wanDataUsageEntry}, instance => $instance . '.3');

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{wanName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{wanName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{wan}->{$instance} = { display => $result->{wanName},
            health_status => $result->{wanHealthCheckState},
            signal => $result->{wanSignal} != -9999 ? $result->{wanSignal} : undef,
            traffic_in => $result2->{wanDataUsageRxByte} * 1024 * 1024 * 8,
            traffic_out => $result2->{wanDataUsageTxByte} * 1024 * 1024 * 8,
        };
    }
    
    if (scalar(keys %{$self->{wan}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No wan found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "peplink_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check wan usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^traffic-in$'

=item B<--filter-name>

Filter wan name (can be a regexp).

=item B<--warning-health-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{health_status}, %{display}

=item B<--critical-health-status>

Set critical threshold for status (Default: '%{health_status} =~ /fail/').
Can used special variables like: %{health_status}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'traffic-in', 'traffic-out'.

=item B<--critical-*>

Threshold critical.
Can be: Can be: 'traffic-in', 'traffic-out'.

=back

=cut
