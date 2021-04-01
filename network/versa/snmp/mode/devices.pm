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

package network::versa::snmp::mode::devices;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_sessions_active_output {
    my ($self, %options) = @_;

    return sprintf(
        'sessions active: %s (%s)',
        $self->{result_values}->{sessions_active},
        $self->{result_values}->{sessions_max}
    );
}

sub custom_sessions_failed_output {
    my ($self, %options) = @_;

    return sprintf(
        'sessions failed: %s (%s)',
        $self->{result_values}->{sessions_failed},
        $self->{result_values}->{sessions_max}
    );
}

sub prefix_device_output {
    my ($self, %options) = @_;
    
    return "Device '" . $options{instance_value}->{vsn_id} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'devices', type => 1, cb_prefix_output => 'prefix_device_output', message_multiple => 'All devices are ok' }
    ];
    
    $self->{maps_counters}->{devices} = [
        { label => 'cpu-utilization', nlabel => 'device.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_load' } ],
                output_template => 'cpu load: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'memory-usage', nlabel => 'device.memory.usage.percentage', set => {
                key_values => [ { name => 'memory' } ],
                output_template => 'memory used: %.2f%%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'sessions-active', nlabel => 'device.sessions.active.count', set => {
                key_values => [ { name => 'sessions_active' }, { name => 'sessions_max' } ],
                closure_custom_output => $self->can('custom_sessions_active_output'),
                perfdatas => [
                    { template => '%s', min => 0, max => 'sessions_max', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'sessions-active-prct', nlabel => 'device.sessions.active.percentage', display_ok => 0, set => {
                key_values => [ { name => 'sessions_active_prct' } ],
                output_template => 'sessions active: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'sessions-failed', nlabel => 'device.sessions.failed.count', set => {
                key_values => [ { name => 'sessions_failed' }, { name => 'sessions_max' } ],
                closure_custom_output => $self->can('custom_sessions_failed_output'),
                perfdatas => [
                    { template => '%s', min => 0, max => 'sessions_max', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'sessions-failed-prct', nlabel => 'device.sessions.failed.percentage', display_ok => 0, set => {
                key_values => [ { name => 'sessions_failed_prct' } ],
                output_template => 'sessions failed: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
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
        'filter-vsn-id:s' => { name => 'filter_vsn_id' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_deviceTableEntry = '.1.3.6.1.4.1.42359.2.2.1.1.1.1';

    my $mapping_device = {
        vsn_id          => { oid => '.1.3.6.1.4.1.42359.2.2.1.1.1.1.1' }, # deviceVSNId
        cpu_load        => { oid => '.1.3.6.1.4.1.42359.2.2.1.1.1.1.2' }, # deviceCPULoad
        memory          => { oid => '.1.3.6.1.4.1.42359.2.2.1.1.1.1.3' }, # deviceMemoryLoad
        sessions_active => { oid => '.1.3.6.1.4.1.42359.2.2.1.1.1.1.5' }, # deviceActiveSessions
        sessions_failed => { oid => '.1.3.6.1.4.1.42359.2.2.1.1.1.1.6' }, # deviceFailedSessions
        sessions_max    => { oid => '.1.3.6.1.4.1.42359.2.2.1.1.1.1.7' }  # deviceMaxSessions
    };
    
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_deviceTableEntry,
        end => $mapping_device->{sessions_max}->{oid},
        nothing_quit => 1
    );

    $self->{devices} = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping_device->{cpu_load}->{oid}\.(.*)/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping_device, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_vsn_id}) && $self->{option_results}->{filter_vsn_id} ne '' &&
            $result->{vsn_id} !~ /$self->{option_results}->{filter_vsn_id}/) {
            $self->{output}->output_add(long_msg => "skipping device '" . $result->{vsn_id} . "'.", debug => 1);
            next;
        }

        $self->{devices}->{ $result->{vsn_id} } = $result;
        $self->{devices}->{ $result->{vsn_id} }->{sessions_active_prct} = $result->{sessions_active} * 100/ $result->{sessions_max};
        $self->{devices}->{ $result->{vsn_id} }->{sessions_failed_prct} = $result->{sessions_failed} * 100/ $result->{sessions_max};
    }
}

1;

__END__

=head1 MODE

Check device system statistics (cpu, memory, sessions).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='cpu_load'

=item B<--filter-vsn-id>

Filter monitoring on vsn id (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization', 'memory-usage', 'sessions-active', 'sessions-active-prct',
'sessions-failed', 'sessions-failed-prct'. 

=back

=cut
