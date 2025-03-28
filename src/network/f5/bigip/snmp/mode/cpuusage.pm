#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::f5::bigip::snmp::mode::cpuusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_usage_perfdata {
    my ($self, %options) = @_;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPU are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{cpu} = [
        { label => 'usage-5s', set => {
                key_values => [ { name => 'sysMultiHostCpuUsageRatio5s' }, { name => 'display' } ],
                output_template => 'CPU Usage 5sec : %s %%', output_error_template => "CPU Usage 5sec : %s",
                perfdatas => [
                    { label => 'usage_5s', value => 'sysMultiHostCpuUsageRatio5s',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'usage-1m', set => {
                key_values => [ { name => 'sysMultiHostCpuUsageRatio1m' }, { name => 'display' } ],
                output_template => 'CPU Usage 1min : %s %%', output_error_template => "CPU Usage 1min : %s",
                perfdatas => [
                    { label => 'usage_1m', value => 'sysMultiHostCpuUsageRatio1m',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'usage-5m', set => {
                key_values => [ { name => 'sysMultiHostCpuUsageRatio5m' }, { name => 'display' } ],
                output_template => 'CPU Usage 5min : %s %%', output_error_template => "CPU Usage 5min : %s",
                perfdatas => [
                    { label => 'usage_5m', value => 'sysMultiHostCpuUsageRatio5m',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'user-5s', set => {
                key_values => [ { name => 'sysMultiHostCpuUser5s' }, { name => 'display' } ],
                output_template => 'CPU User 5sec : %s %%', output_error_template => "CPU User 5sec : %s",
                perfdatas => [
                    { label => 'user_5s', value => 'sysMultiHostCpuUser5s',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'user-1m', set => {
                key_values => [ { name => 'sysMultiHostCpuUser1m' }, { name => 'display' } ],
                output_template => 'CPU User 1min : %s %%', output_error_template => "CPU User 1min : %s",
                perfdatas => [
                    { label => 'user_1m', value => 'sysMultiHostCpuUser1m',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'user-5m', set => {
                key_values => [ { name => 'sysMultiHostCpuUser5m' }, { name => 'display' } ],
                output_template => 'CPU User 5min : %s %%', output_error_template => "CPU User 5min : %s",
                perfdatas => [
                    { label => 'user_5m', value => 'sysMultiHostCpuUser5m',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'iowait-5s', set => {
                key_values => [ { name => 'sysMultiHostCpuIowait5s' }, { name => 'display' } ],
                output_template => 'CPU IO Wait 5sec : %s %%', output_error_template => "CPU IO Wait 5sec : %s",
                perfdatas => [
                    { label => 'iowait_5s', value => 'sysMultiHostCpuIowait5s',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'iowait-1m', set => {
                key_values => [ { name => 'sysMultiHostCpuIowait1m' }, { name => 'display' } ],
                output_template => 'CPU IO Wait 1min : %s %%', output_error_template => "CPU IO Wait 1min : %s",
                perfdatas => [
                    { label => 'iowait_1m', value => 'sysMultiHostCpuIowait1m',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'iowait-5m', set => {
                key_values => [ { name => 'sysMultiHostCpuIowait5m' }, { name => 'display' } ],
                output_template => 'CPU IO Wait 5min : %s %%', output_error_template => "CPU IO Wait 5min : %s",
                perfdatas => [
                    { label => 'iowait_5m', value => 'sysMultiHostCpuIowait5m',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'system-5s', set => {
                key_values => [ { name => 'sysMultiHostCpuSystem5s' }, { name => 'display' } ],
                output_template => 'CPU System 5sec : %s %%', output_error_template => "CPU System 5sec : %s",
                perfdatas => [
                    { label => 'system_5s', value => 'sysMultiHostCpuSystem5s',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'system-1m', set => {
                key_values => [ { name => 'sysMultiHostCpuSystem1m' }, { name => 'display' } ],
                output_template => 'CPU System 1min : %s %%', output_error_template => "CPU System 1min : %s",
                perfdatas => [
                    { label => 'system_1m', value => 'sysMultiHostCpuSystem1m',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'system-5m', set => {
                key_values => [ { name => 'sysMultiHostCpuSystem5m' }, { name => 'display' } ],
                output_template => 'CPU System 5min : %s %%', output_error_template => "CPU System 5min : %s",
                perfdatas => [
                    { label => 'system_5m', value => 'sysMultiHostCpuSystem5m',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'idle-5s', set => {
                key_values => [ { name => 'sysMultiHostCpuIdle5s' }, { name => 'display' } ],
                output_template => 'CPU Idle 5sec : %s %%', output_error_template => "CPU Idle 5sec : %s",
                perfdatas => [
                    { label => 'idle_5s', value => 'sysMultiHostCpuIdle5s',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'idle-1m', set => {
                key_values => [ { name => 'sysMultiHostCpuIdle1m' }, { name => 'display' } ],
                output_template => 'CPU Idle 1min : %s %%', output_error_template => "CPU Idle 1min : %s",
                perfdatas => [
                    { label => 'idle_1m', value => 'sysMultiHostCpuIdle1m',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'idle-5m', set => {
                key_values => [ { name => 'sysMultiHostCpuIdle5m' }, { name => 'display' } ],
                output_template => 'CPU Idle 5min : %s %%', output_error_template => "CPU Idle 5min : %s",
                perfdatas => [
                    { label => 'idle_5m', value => 'sysMultiHostCpuIdle5m',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    return "CPU '" . $options{instance_value}->{display} . "' ";
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
    sysMultiHostCpuId           => { oid => '.1.3.6.1.4.1.3375.2.1.7.5.2.1.3' },
    sysMultiHostCpuUsageRatio5s => { oid => '.1.3.6.1.4.1.3375.2.1.7.5.2.1.19' },
    sysMultiHostCpuUsageRatio1m => { oid => '.1.3.6.1.4.1.3375.2.1.7.5.2.1.27' },
    sysMultiHostCpuUsageRatio5m => { oid => '.1.3.6.1.4.1.3375.2.1.7.5.2.1.35' },
    sysMultiHostCpuUser5s       => { oid => '.1.3.6.1.4.1.3375.2.1.7.5.2.1.12' },
    sysMultiHostCpuUser1m       => { oid => '.1.3.6.1.4.1.3375.2.1.7.5.2.1.20' },
    sysMultiHostCpuUser5m       => { oid => '.1.3.6.1.4.1.3375.2.1.7.5.2.1.28' },
    sysMultiHostCpuIowait5s     => { oid => '.1.3.6.1.4.1.3375.2.1.7.5.2.1.18' },
    sysMultiHostCpuIowait1m     => { oid => '.1.3.6.1.4.1.3375.2.1.7.5.2.1.26' },
    sysMultiHostCpuIowait5m     => { oid => '.1.3.6.1.4.1.3375.2.1.7.5.2.1.34' },
    sysMultiHostCpuSystem5s     => { oid => '.1.3.6.1.4.1.3375.2.1.7.5.2.1.14' },
    sysMultiHostCpuSystem1m     => { oid => '.1.3.6.1.4.1.3375.2.1.7.5.2.1.22' },
    sysMultiHostCpuSystem5m     => { oid => '.1.3.6.1.4.1.3375.2.1.7.5.2.1.30' },
    sysMultiHostCpuIdle5s       => { oid => '.1.3.6.1.4.1.3375.2.1.7.5.2.1.15' },
    sysMultiHostCpuIdle1m       => { oid => '.1.3.6.1.4.1.3375.2.1.7.5.2.1.23' },
    sysMultiHostCpuIdle5m       => { oid => '.1.3.6.1.4.1.3375.2.1.7.5.2.1.31' },
};
my $oid_sysMultiHostCpuEntry = '.1.3.6.1.4.1.3375.2.1.7.5.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    
    my $results = $options{snmp}->get_table(
        oid => $oid_sysMultiHostCpuEntry,
        nothing_quit => 1
    );
    
    $self->{cpu} = {};
    foreach my $oid (keys %$results) {
        next if ($oid !~ /^$mapping->{sysMultiHostCpuId}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{sysMultiHostCpuId} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{sysMultiHostCpuId} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{cpu}->{$result->{sysMultiHostCpuId}} = { 
            display => $result->{sysMultiHostCpuId},
            %$result
        };
    }
    
    if (scalar(keys %{$self->{cpu}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No CPU found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "f5_bipgip_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check CPU usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example : --filter-counters='^usage$'

=item B<--filter-name>

Filter by CPU id (regexp can be used).
Example : --filter-name='2'

=item B<--warning-*>

Warning threshold.
Can be: 'usage-1m', 'usage-5m', 'iowait-5s'.

=item B<--critical-*>

Critical threshold.
Can be: 'usage-1m', 'usage-5m', 'iowait-5s'.

=back

=cut
