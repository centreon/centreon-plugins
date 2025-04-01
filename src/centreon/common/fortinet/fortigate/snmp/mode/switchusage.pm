#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package centreon::common::fortinet::fortigate::snmp::mode::switchusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status} . ' [admin: ' . $self->{result_values}->{admin} . ']';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'switch',
            type             => 1,
            cb_prefix_output => 'prefix_ap_output',
            message_multiple => 'All switches are ok',
            skipped_code     => { -10 => 1 }
        }
    ];

    $self->{maps_counters}->{switch} = [
        { label => 'status', threshold => 0, set => {
            key_values                     => [ { name => 'status' }, { name => 'admin' }, { name => 'display' } ],
            closure_custom_output          => $self->can('custom_status_output'),
            closure_custom_perfdata        => sub {return 0;},
            closure_custom_threshold_check => \&catalog_status_threshold
        }
        },
        { label => 'cpu', nlabel => 'switch.cpu.utilization.percentage', set => {
            key_values      => [ { name => 'cpu' }, { name => 'display' } ],
            output_template => 'cpu usage: %.2f %%',
            perfdatas       => [
                { label  => 'cpu', template => '%.2f',
                    unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'memory', nlabel => 'switch.memory.usage.bytes', set => {
            key_values      => [ { name => 'memory' }, { name => 'display' } ],
            output_template => 'memory usage: %.2f %%',
            perfdatas       => [
                { label  => 'memory', template => '%.2f',
                    unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        }
    ];
}

sub prefix_ap_output {
    my ($self, %options) = @_;

    return "Switch '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'filter-name:s'     => { name => 'filter_name' },
            'filter-ip:s'       => { name => 'filter_ip' },
            'unknown-status:s'  => { name => 'unknown_status', default => '' },
            'warning-status:s'  => { name => 'warning_status', default => '' },
            'critical-status:s' => {
                name    => 'critical_status',
                default => '%{admin} eq "authorized" and %{status} eq "down"'
            }
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [ 'unknown_status', 'warning_status', 'critical_status' ]);
}

my %map_admin_connection_state = (
    0 => 'discovered', 1 => 'disable', 2 => 'authorized',
);

my %map_switch_status = (
    0 => 'down', 1 => 'up'
);

my $mapping = {
    fgSwDeviceAuthorized => { oid => '.1.3.6.1.4.1.12356.101.24.1.1.1.6', map => \%map_admin_connection_state },
    fgSwDeviceName       => { oid => '.1.3.6.1.4.1.12356.101.24.1.1.1.4' },
    fgSwDeviceIp         => { oid => '.1.3.6.1.4.1.12356.101.24.1.1.1.9' }
};

my $mapping2 = {
    fgSwDeviceStatus => { oid => '.1.3.6.1.4.1.12356.101.24.1.1.1.7', map => \%map_switch_status },
    fgSwCpu          => { oid => '.1.3.6.1.4.1.12356.101.24.1.1.1.11' },
    fgSwMemory       => { oid => '.1.3.6.1.4.1.12356.101.24.1.1.1.12' }
};
my $oid_fgSwDeviceTable = '.1.3.6.1.4.1.12356.101.24.1.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid          => $oid_fgSwDeviceTable,
        start        => $mapping->{fgSwDeviceName}->{oid},
        end          => $mapping->{fgSwDeviceIp}->{oid},
        nothing_quit => 1
    );

    $self->{switch} = {};
    foreach my $oid (sort keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{fgSwDeviceName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{fgSwDeviceName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(
                long_msg => "skipping switch '" . $result->{fgSwDeviceName} . "'.",
                debug    => 1
            );
            next;
        }

        if (defined($self->{option_results}->{filter_ip}) && $self->{option_results}->{filter_ip} ne '' &&
            $result->{fgSwDeviceIp} !~ /$self->{option_results}->{filter_ip}/) {
            $self->{output}->output_add(
                long_msg => "skipping switch '" . $result->{fgSwDeviceIp} . "'.",
                debug    => 1
            );
            next;
        }

        $self->{switch}->{$instance} = {
            display => $result->{fgSwDeviceName},
            admin   => $result->{fgSwDeviceAuthorized},
            status  => 'n/a',
        };
    }

    if (scalar(keys %{$self->{switch}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No switch found.");
        $self->{output}->option_exit();
    }

    $options{snmp}->load(
        oids            => [
            $mapping2->{fgSwDeviceStatus}->{oid},
            $mapping2->{fgSwCpu}->{oid},
            $mapping2->{fgSwMemory}->{oid},
        ],
        instances       => [ keys %{$self->{switch}} ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{switch}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $_);

        $self->{switch}->{$_}->{status} = $result->{fgSwDeviceStatus};
        $self->{switch}->{$_}->{cpu} = $result->{fgSwCpu};
        $self->{switch}->{$_}->{memory} = $result->{fgSwMemory};
    }

    $self->{cache_name} = 'fortigate_' . $self->{mode} . '_' . $options{snmp}->get_hostname() . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ?
            md5_hex($self->{option_results}->{filter_counters}) :
            md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ?
            md5_hex($self->{option_results}->{filter_name}) :
            md5_hex('all'));
}

1;

__END__

=head1 MODE

Check switch usage through Fortigate Switch Controller.

=over 8

=item B<--warning-cpu>

Warning threshold (%).

=item B<--critical-cpu>

Critical threshold (%).

=item B<--warning-memory>

Warning threshold (%).

=item B<--critical-memory>

Critical threshold (%).

=item B<--filter-name>

Filter by switch name (can be a regexp).

=item B<--filter-ip>

Filter by switch IP (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '').
You can use the following variables: %{admin}, %{status}, %{display}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: %{admin}, %{status}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{admin} eq "authorized" and %{status} eq "down"').
You can use the following variables: %{admin}, %{status}, %{display}

=back

=cut
