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

package network::huawei::wlc::snmp::mode::aphealth;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'data link state: ' . $self->{result_values}->{datalinkstate} . ', power-supply: ' . $self->{result_values}->{powersupply};
    return $msg;
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Access points ';
}

sub ap_long_output {
    my ($self, %options) = @_;

    return "checking access point '" . $options{instance_value}->{display} . "'";
}

sub prefix_ap_output {
    my ($self, %options) = @_;

    return "access point '" . $options{instance_value}->{display} . "' ";
}

sub custom_uptime_output {
    my ($self, %options) = @_;

    return sprintf(
        'access point %s online time is: %s', $self->{result_values}->{display},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{onlinetime}, start => 'd')
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name                 => 'ap',
            type               => 3,
            cb_prefix_output   => 'prefix_ap_output',
            cb_long_output     => 'ap_long_output',
            indent_long_output => '    ',
            message_multiple   => 'All access points are ok',
            group              => [
                { name => 'health', type => 0 }
            ]
        }
    ];

    $self->{maps_counters}->{health} = [
        {
            label            => 'status',
            type             => 2,
            critical_default => '%{powersupply} =~ /insufficient|limited/ || %{datalinkstate} !~ /run/',
            warning_default  => '%{powersupply} eq "limited"',
            set              =>
                {
                    key_values                     =>
                        [ { name => 'powersupply' }, { name => 'display' }, { name => 'datalinkstate' } ],
                    closure_custom_output          =>
                        $self->can('custom_status_output'),
                    closure_custom_perfdata        =>
                        sub {return 0;},
                    closure_custom_threshold_check =>
                        \&catalog_status_threshold_ng
                }
        },
        { label => 'temperature', nlabel => 'ap.temperature.celsius', set => {
            key_values      => [ { name => 'temperature' }, { name => 'display' } ],
            output_template => 'access point temperature: %.2f C',
            perfdatas       => [
                { template => '%.2f', unit => 'C', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'onlinetime', nlabel => 'ap.online.time', set => {
            key_values            => [ { name => 'onlinetime' }, { name => 'display' } ],
            closure_custom_output => $self->can('custom_uptime_output'),
            perfdatas             => [
                { template => '%d', unit => '', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'bootcount-total', nlabel => 'ap.boot.total.count', set => {
            key_values      => [ { name => 'bootcount_total' }, { name => 'display' } ],
            output_template => 'access point bootcount total: %d',
            perfdatas       => [
                { template => '%d', unit => '', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'memory', nlabel => 'ap.memory.used.percentage', set => {
            key_values      => [ { name => 'memory' }, { name => 'display' } ],
            output_template => 'access point memory: %.2f %%',
            perfdatas       => [
                { template => '%.2f', unit => '%', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'cpu', nlabel => 'ap.cpu.used.percentage', set => {
            key_values      => [ { name => 'cpu' }, { name => 'display' } ],
            output_template => 'access point cpu: %.2f%%',
            perfdatas       => [
                { template => '%.2f', unit => '%', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'up-port-speed', nlabel => 'ap.up.port.bitspersecond', set => {
            key_values      => [ { name => 'up_port_speed' }, { name => 'display' } ],
            output_template => 'access point up-Port speed: %s b/s',
            perfdatas       => [
                { template => '%s', unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'up-port-packet-err', nlabel => 'ap.up.port.package.error.percentage', set => {
            key_values      => [ { name => 'up_port_per' }, { name => 'display' } ],
            output_template => 'access point up-Port packet errors: %.2f%%',
            perfdatas       => [
                { template => '%.2f', unit => '', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'online-user-num', nlabel => 'ap.online.user.count', set => {
            key_values      => [ { name => 'online_user_num' }, { name => 'display' } ],
            output_template => 'access online user nums: %d',
            perfdatas       => [
                { template => '%d', unit => '', label_extra_instance => 1, instance_use => 'display' }
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
        "filter-name:s"    => { name => 'filter_name' },
        "filter-address:s" => { name => 'filter_address' },
        "filter-group:s"   => { name => 'filter_group' }
    });

    return $self;
}

my $map_power_supply_state = {
    1 => 'normal',
    2 => 'insufficient',
    3 => 'limited',
    4 => 'invalid'
};

my $map_data_link_state = {
    1 => 'down',
    2 => 'run',
    3 => 'noneed'
};

my $mapping = {
    name    => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.4' },# hwWlanApName
    address => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.13' }# hwWlanApIpAddress
};

my $mapping_stat = {
    runtime         => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.18' },# hwWlanApRunTime
    group           => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.5' },# hwWlanApGroup
    temperature     => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.43' },# hwWlanApTemperature
    onlinetime      => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.21' },# hwWlanApOnlineTime
    bootcount_total => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.33' },# hwWlanApBootCountTotal
    memory          => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.40' },# hwWlanApMemoryUseRate
    cpu             => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.41' },# hwWlanApCPUUseRate
    up_port_speed   => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.54' },# hwWlanApUpPortSpeed
    up_port_per     => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.55' },# hwWlanAPUpPortPER
    online_user_num => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.44' },# hwWlanApOnlineUserNum
    powersupply     =>
        { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.80', map => $map_power_supply_state },#  hwWlanAPPowerSupplyState
    datalinkstate   =>
        { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.81', map => $map_data_link_state }#  hwWlanApDataLinkState
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{ap} = {};

    my $request = [ { oid => $mapping->{name}->{oid} } ];
    push @$request, { oid => $mapping->{group}->{oid} }
        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '');

    push @$request, { oid => $mapping->{address}->{oid} }
        if (defined($self->{option_results}->{filter_address}) && $self->{option_results}->{filter_address} ne '');

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids         => $request,
        return_type  => 1,
        nothing_quit => 1
    );

    foreach (sort keys %$snmp_result) {
        next if (!/^$mapping->{name}->{oid}\.(.*)/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if (!defined($result->{name}) || $result->{name} eq '') {
            $self->{output}->output_add(long_msg =>
                "skipping WLC '$instance': cannot get a name. please set it.",
                debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg =>
                "skipping '" . $result->{name} . "': no matching name filter.",
                debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_address}) && $self->{option_results}->{filter_address} ne '' &&
            $result->{address} !~ /$self->{option_results}->{filter_address}/) {
            $self->{output}->output_add(long_msg =>
                "skipping '" . $result->{address} . "': no matching address filter.",
                debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '' &&
            $result->{group} !~ /$self->{option_results}->{filter_group}/) {
            $self->{output}->output_add(long_msg =>
                "skipping '" . $result->{group} . "': no matching group filter.",
                debug => 1);
            next;
        }

        $self->{ap}->{ $result->{name} } = {
            instance   => $instance,
            display    => $result->{name},
            health     => {
                display => $result->{name}
            }
        };
    }

    if (scalar(keys %{$self->{ap}}) <= 0) {
        $self->{output}->output_add(long_msg => 'no AP associated');
        return;
    }

    $options{snmp}->load(
        oids            => [ map($_->{oid}, values(%$mapping_stat)) ],
        instances       => [ map($_->{instance}, values %{$self->{ap}}) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    foreach (sort keys %{$self->{ap}}) {
        my $result = $options{snmp}->map_instance(
            mapping  => $mapping_stat,
            results  => $snmp_result,
            instance => $self->{ap}->{$_}->{instance}
        );

        $self->{ap}->{$_}->{health}->{datalinkstate} = $result->{datalinkstate};
        $self->{ap}->{$_}->{health}->{powersupply} = $result->{powersupply};
        $self->{ap}->{$_}->{health}->{temperature} = $result->{temperature};
        $self->{ap}->{$_}->{health}->{onlinetime} = $result->{onlinetime};
        $self->{ap}->{$_}->{health}->{bootcount_total} = $result->{bootcount_total};
        $self->{ap}->{$_}->{health}->{memory} = $result->{memory};
        $self->{ap}->{$_}->{health}->{cpu} = $result->{cpu};
        $self->{ap}->{$_}->{health}->{up_port_speed} = $result->{up_port_speed} * 1000;
        $self->{ap}->{$_}->{health}->{up_port_per} = $result->{up_port_per};
        $self->{ap}->{$_}->{health}->{online_user_num} = $result->{online_user_num};
    }
}

1;

__END__

=head1 MODE

Check AP health.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^temperature|onlinetime$'

=item B<--filter-name>

Filter access point name (can be a regexp)

=item B<--filter-address>

Filter access point IP address (can be a regexp).

=item B<--filter-group>

Filter access point group (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING. (default: '%{powersupply} eq "limited"').
You can use the following variables: %{powersupply}, %{datalinkstate}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{powersupply} =~ /insufficient|limited/ || %{datalinkstate} !~ /run/').
You can use the following variables: %{powersupply}, %{datalinkstate}, %{display}

=item B<--warning-temperature>

Thresholds.

=item B<--critical-temperature>

Thresholds.

=item B<--warning-onlinetime>

Thresholds.

=item B<--critical-onlinetime>

Thresholds.

=item B<--warning-bootcount-total>

Thresholds.

=item B<--critical-bootcount-total>

Thresholds.

=item B<--warning-memory>

Thresholds.

=item B<--critical-memory>

Thresholds.


=item B<--warning-cpu>

Thresholds.

=item B<--critical-cpu>

Thresholds.

=item B<--warning-up-port-speed>

Thresholds.

=item B<--critical-up-port-speed>

Thresholds.

=item B<--warning-up-port-packet-err>

Thresholds.

=item B<--critical-up-port-packet-err>

Thresholds.

=item B<--warning-online-user-num>

Thresholds.

=item B<--critical-online-user-num>

Thresholds.

=back

=cut
