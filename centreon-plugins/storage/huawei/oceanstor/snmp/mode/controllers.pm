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

package storage::huawei::oceanstor::snmp::mode::controllers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use storage::huawei::oceanstor::snmp::mode::resources qw($health_status $running_status);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'health status: %s [running status: %s]',
        $self->{result_values}->{health_status},
        $self->{result_values}->{running_status}
    );
}

sub ctrl_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking controller '%s'",
        $options{instance_value}->{id}
    );
}

sub prefix_ctrl_output {
    my ($self, %options) = @_;

    return sprintf(
        "controller '%s' ",
        $options{instance_value}->{id}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'controllers', type => 3, cb_prefix_output => 'prefix_ctrl_output', cb_long_output => 'ctrl_long_output',
          indent_long_output => '    ', message_multiple => 'All controllers are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'cpu', type => 0, skipped_code => { -10 => 1 } },
                { name => 'memory', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{health_status} =~ /degraded|partially broken/i',
            critical_default => '%{health_status} =~ /fault|fail/i',
            set => {
                key_values => [ { name => 'health_status' }, { name => 'running_status' }, { name => 'id' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{cpu} = [
         { label => 'cpu-utilization', nlabel => 'controller.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_usage' } ],
                output_template => 'cpu usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{memory} = [
         { label => 'memory-usage', nlabel => 'controller.memory.usage.percentage', set => {
                key_values => [ { name => 'memory_usage' } ],
                output_template => 'memory used: %.2f %%',
                output_change_bytes => 1,
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
        'filter-id:s' => { name => 'filter_id' }
    });

    return $self;
}

my $mapping = {
    health_status  => { oid => '.1.3.6.1.4.1.34774.4.1.23.5.2.1.2', map => $health_status }, # hwInfoControllerHealthStatus
    running_status => { oid => '.1.3.6.1.4.1.34774.4.1.23.5.2.1.3', map => $running_status }, # hwInfoControllerRunningStatus
    cpu_usage      => { oid => '.1.3.6.1.4.1.34774.4.1.23.5.2.1.8' }, # hwInfoControllerCPUUsage
    memory_usage   => { oid => '.1.3.6.1.4.1.34774.4.1.23.5.2.1.9' }, # hwInfoControllerMemoryUsage
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_controller_id = '.1.3.6.1.4.1.34774.4.1.23.5.2.1.1'; # hwInfoControllerID
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_controller_id,
        nothing_quit => 1
    );

    $self->{controllers} = {};
    foreach (keys %$snmp_result) {
        /^$oid_controller_id\.(.*)$/;
        my $instance = $1;

        if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $snmp_result->{$_} !~ /$self->{option_results}->{filter_id}/) {
            $self->{output}->output_add(long_msg => "skipping controller '" . $snmp_result->{$_} . "'.", debug => 1);
            next;
        }

        $self->{controllers}->{ $snmp_result->{$_} } = {
            id => $snmp_result->{$_},
            instance => $instance
        };
    }

    return if (scalar(keys %{$self->{controllers}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ map($_->{instance}, values(%{$self->{controllers}})) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{controllers}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $self->{controllers}->{$_}->{instance});

        $self->{controllers}->{$_}->{memory} = { memory_usage => $result->{memory_usage} };
        $self->{controllers}->{$_}->{cpu} = { cpu_usage => $result->{cpu_usage} };
        $self->{controllers}->{$_}->{status} = {
            running_status => $result->{running_status},
            health_status => $result->{health_status},
            id => $_
        };
    }
}

1;

__END__

=head1 MODE

Check controllers.

=over 8

=item B<--filter-id>

Filter controller by ID (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{health_status}, %{running_status}, %{id}

=item B<--warning-status>

Set warning threshold for status (Default: '%{health_status} =~ /degraded|partially broken/i').
Can used special variables like: %{health_status}, %{running_status}, %{id}

=item B<--critical-status>

Set critical threshold for status (Default: '%{health_status} =~ /fault|fail/i').
Can used special variables like: %{health_status}, %{running_status}, %{id}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization', 'memory-usage'.

=back

=cut
