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

package centreon::common::airespace::snmp::mode::apstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = $self->{result_values}->{admstatus} eq 'disable' ? 'is disabled' : ('status: ' . $self->{result_values}->{opstatus});
    return $msg;
}

sub custom_radio_channel_util_calc {
    my ($self, %options) = @_;

    return -10 if ($options{new_datas}->{$self->{instance} . '_admstatus'} eq 'disable');
    $self->{result_values}->{channels_util} = $options{new_datas}->{$self->{instance} . '_channels_util'};
    return 0;
}

sub skip_global {
    my ($self, %options) = @_;

    scalar(keys %{$self->{ap}}) == 1 ? return(1) : return(0);
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

sub prefix_interface_output {
    my ($self, %options) = @_;

    return "radio interface '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', cb_init => 'skip_global', },
        { name => 'ap', type => 3, cb_prefix_output => 'prefix_ap_output', cb_long_output => 'ap_long_output', indent_long_output => '    ', message_multiple => 'All access points are ok',
            group => [
                { name => 'ap_global', type => 0 },
                { name => 'interfaces', type => 1, display_long => 1, cb_prefix_output => 'prefix_interface_output',  message_multiple => 'radio interfaces are ok', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'accesspoints.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { label => 'total', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'total-associated', nlabel => 'accesspoints.associated.count', set => {
                key_values => [ { name => 'associated' } ],
                output_template => 'associated: %s',
                perfdatas => [
                    { label => 'total_associated', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'total-disassociating', nlabel => 'accesspoints.disassociating.count', set => {
                key_values => [ { name => 'disassociating' } ],
                output_template => 'disassociating: %s',
                perfdatas => [
                    { label => 'total_disassociating', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'total-downloading', nlabel => 'accesspoints.downloading.count', display_ok => 0, set => {
                key_values => [ { name => 'downloading' } ],
                output_template => 'downloading: %s',
                perfdatas => [
                    { label => 'total_downloading', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'total-enabled', nlabel => 'accesspoints.enabled.count', set => {
                key_values => [ { name => 'enable' } ],
                output_template => 'enabled: %s',
                perfdatas => [
                    { label => 'total_enabled', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'total-disabled', nlabel => 'accesspoints.disabled.count', set => {
                key_values => [ { name => 'disable' } ],
                output_template => 'disabled: %s',
                perfdatas => [
                    { label => 'total_disabled', template => '%s', min => 0 }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{ap_global} = [
        { label => 'status', type => 2, critical_default => '%{admstatus} eq "enable" and %{opstatus} !~ /associated|downloading/', set => {
                key_values => [ { name => 'opstatus' }, { name => 'admstatus' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{interfaces} = [
        { label => 'radio-status', type => 2, critical_default => '%{admstatus} eq "enable" and %{opstatus} eq "down"', set => {
                key_values => [ { name => 'opstatus' }, { name => 'admstatus' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'radio-interface-channels-utilization', nlabel => 'accesspoint.radio.interface.channels.utilization.percentage', set => {
                key_values => [ { name => 'channels_util' }, { name => 'admstatus' } ],
                closure_custom_calc => $self->can('custom_radio_channel_util_calc'),
                output_template => 'channels utilization: %s %%',
                perfdatas => [
                    { label => 'radio_interface_channels_utilization', template => '%s', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s'        => { name => 'filter_name' },
        'filter-group:s'       => { name => 'filter_group' },
        'add-radio-interfaces' => { name => 'add_radio_interfaces' }
    });

    return $self;
}

my $map_admin_status = {
    1 => 'enable',
    2 => 'disable'
};
my $map_operation_status = {
    1 => 'associated',
    2 => 'disassociating',
    3 => 'downloading'
};
my $map_radio_operation_status = {
    1 => 'down',
    2 => 'up'
};

my $mapping = {
    ap_name    => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.3' }, # bsnAPName
    group_name => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.30' } # bsnAPGroupVlanName
};
my $mapping2 = {
    opstatus  => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.6', map => $map_operation_status }, # bsnAPOperationStatus
    admstatus => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.37', map => $map_admin_status } # bsnAPAdminStatus
};
my $mapping3 = {
    opstatus      => { oid => '.1.3.6.1.4.1.14179.2.2.2.1.12', map => $map_radio_operation_status }, # bsnAPIfOperStatus
    admstatus     => { oid => '.1.3.6.1.4.1.14179.2.2.2.1.34', map => $map_admin_status }, # bsnAPIfAdminStatus
    channels_util => { oid => '.1.3.6.1.4.1.14179.2.2.13.1.3' } # bsnAPIfLoadChannelUtilization
};
my $oid_agentInventoryMachineModel = '.1.3.6.1.4.1.14179.1.1.1.3';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{ap} = {};
    $self->{global} = { total => 0, associated => 0, disassociating => 0, downloading => 0, enable => 0, disable => 0 };

    my $request = [ { oid => $oid_agentInventoryMachineModel }, { oid => $mapping->{ap_name}->{oid} } ];
    push @$request, { oid => $mapping->{group_name}->{oid} }
        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '');
    
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => $request,
        return_type => 1,
        nothing_quit => 1
    );

    $self->{output}->output_add(
        long_msg => 'Model: ' . 
            (defined($snmp_result->{$oid_agentInventoryMachineModel . '.0'}) ? $snmp_result->{$oid_agentInventoryMachineModel . '.0'} : 'unknown')
    );

    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{ap_name}->{oid}\.(.*)/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{ap_name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{ap_name} . "'.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '' &&
            $result->{group_name} !~ /$self->{option_results}->{filter_group}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{ap_name} . "'.", debug => 1);
            next;
        }

        $self->{ap}->{ $result->{ap_name} } = {
            instance => $instance,
            display => $result->{ap_name},
            ap_global => { display => $result->{ap_name} },
            interfaces => {}
        };
    }

    if (scalar(keys %{$self->{ap}}) <= 0) {
        $self->{output}->output_add(long_msg => 'no AP associated (can be: slave wireless controller or your filter)');
        return ;
    }

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping2)) ],
        instances => [ map($_->{instance}, values %{$self->{ap}}) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    my $snmp_result_radio;
    $snmp_result_radio = $options{snmp}->get_multiple_table(oids => [map({ oid => $_->{oid} }, values(%$mapping3))], return_type => 1)
        if (defined($self->{option_results}->{add_radio_interfaces}));

    foreach (keys %{$self->{ap}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $self->{ap}->{$_}->{instance});

        $self->{global}->{total}++;
        $self->{global}->{ $result->{opstatus} }++;
        $self->{global}->{ $result->{admstatus} }++;
        $self->{ap}->{$_}->{ap_global}->{opstatus} = $result->{opstatus};
        $self->{ap}->{$_}->{ap_global}->{admstatus} = $result->{admstatus};

        next if (!defined($self->{option_results}->{add_radio_interfaces}));

        foreach my $oid (keys %$snmp_result_radio) {
            next if ($oid !~ /^$mapping3->{admstatus}->{oid}\.$self->{ap}->{$_}->{instance}\.(\d+)/);
            my $result_radio = $options{snmp}->map_instance(mapping => $mapping3, results => $snmp_result_radio, instance => $self->{ap}->{$_}->{instance} . '.' . $1);
            $self->{ap}->{$_}->{interfaces}->{$1} = {
                display => $1,
                %$result_radio
            };
        }
    }
}

1;

__END__

=head1 MODE

Check AP status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total-disassociating|total-associated$'

=item B<--filter-name>

Filter access point name (can be a regexp).

=item B<--filter-group>

Filter access point group (can be a regexp).

=item B<--add-radio-interfaces>

Monitor radio interfaces channels utilization.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admstatus} eq "enable" and %{opstatus} !~ /associated|downloading/').
Can used special variables like: %{admstatus}, %{opstatus}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total', 'total-associated', 'total-disassociating', 'total-downloading', 
'total-enabled', 'total-disabled', 'radio-interface-channels-utilization' (%).

=back

=cut
