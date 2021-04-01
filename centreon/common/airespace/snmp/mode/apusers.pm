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

package centreon::common::airespace::snmp::mode::apusers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return 'Users ';
}

sub prefix_ssid_output {
    my ($self, %options) = @_;
    
    return "SSID '" . $options{instance_value}->{display} . "' ";
}

sub prefix_ap_output {
    my ($self, %options) = @_;
    
    return "Access point '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_global_output', type => 0 },
        { name => 'ssid', type => 1, cb_prefix_output => 'prefix_ssid_output', message_multiple => 'All users by SSID are ok' },
        { name => 'ap', type => 1, cb_prefix_output => 'prefix_ap_output', message_multiple => 'All users by access point are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'users.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { label => 'total', template => '%s', unit => 'users', min => 0 },
                ]
            }
        },
        { label => 'total-idle', nlabel => 'users.idle.count', set => {
                key_values => [ { name => 'total_idle' } ],
                output_template => 'idle: %s',
                perfdatas => [
                    { label => 'total_idle', template => '%s', unit => 'users', min => 0 }
                ]
            }
        },
        { label => 'total-aaapending', nlabel => 'users.aaapending.count', set => {
                key_values => [ { name => 'total_aaapending' } ],
                output_template => 'aaaPending: %s',
                perfdatas => [
                    { label => 'total_aaapending', template => '%s', unit => 'users', min => 0 }
                ]
            }
        },
        { label => 'total-authenticated', nlabel => 'users.authenticated.count', set => {
                key_values => [ { name => 'total_authenticated' } ],
                output_template => 'authenticated: %s',
                perfdatas => [
                    { label => 'total_authenticated', template => '%s', unit => 'users', min => 0 }
                ]
            }
        },
        { label => 'total-associated', nlabel => 'users.associated.count', set => {
                key_values => [ { name => 'total_associated' } ],
                output_template => 'associated: %s',
                perfdatas => [
                    { label => 'total_associated', template => '%s', unit => 'users', min => 0 }
                ]
            }
        },
        { label => 'total-disassociated', nlabel => 'users.disassociated.count', set => {
                key_values => [ { name => 'total_disassociated' } ],
                output_template => 'disassociated: %s',
                perfdatas => [
                    { label => 'total_disassociated', template => '%s', unit => 'users', min => 0 }
                ]
            }
        },
        { label => 'total-powersave', nlabel => 'users.powersave.count', set => {
                key_values => [ { name => 'total_powersave' } ],
                output_template => 'powersave: %s',
                perfdatas => [
                    { label => 'total_powersave', template => '%s', unit => 'users', min => 0 }
                ]
            }
        },
        { label => 'total-tobedeleted', nlabel => 'users.tobedeleted.count', set => {
                key_values => [ { name => 'total_tobedeleted' } ],
                output_template => 'to be deleted: %s',
                perfdatas => [
                    { label => 'total_tobedeleted', template => '%s', unit => 'users', min => 0 }
                ]
            }
        },
        { label => 'total-probing', nlabel => 'users.probing.count', set => {
                key_values => [ { name => 'total_probing' } ],
                output_template => 'probing: %s',
                perfdatas => [
                    { label => 'total_probing', template => '%s', unit => 'users', min => 0 }
                ]
            }
        },
        { label => 'total-blacklisted', nlabel => 'users.blacklisted.count', set => {
                key_values => [ { name => 'total_blacklisted' } ],
                output_template => 'blacklisted: %s',
                perfdatas => [
                    { label => 'total_blacklisted', template => '%s', unit => 'users', min => 0 }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{ssid} = [
        { label => 'ssid', nlabel => 'ssid.users.total.count', set => {
                key_values => [ { name => 'total' }, { name => 'display' } ],
                output_template => 'users: %s',
                perfdatas => [
                    { label => 'ssid', template => '%s', unit => 'users', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{ap} = [
        { label => 'ap', nlabel => 'accesspoint.users.total.count', set => {
                key_values => [ { name => 'total' }, { name => 'display' } ],
                output_template => 'users: %s',
                perfdatas => [
                    { label => 'ap', template => '%s', unit => 'users', min => 0, label_extra_instance => 1, instance_use => 'display' }
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
        'filter-ssid:s'   => { name => 'filter_ssid' },
        'filter-ap:s'     => { name => 'filter_ap' },
        'filter-group:s'  => { name => 'filter_group' },
        'ignore-ap-users' => { name => 'ignore_ap_users' }
    });

    return $self;
}

my $map_station_status = {
    0 => 'idle',
    1 => 'aaapending',
    2 => 'authenticated',
    3 => 'associated',
    4 => 'powersave',
    5 => 'disassociated',
    6 => 'tobedeleted',
    7 => 'probing',
    8 => 'blacklisted'
};
my $mapping = {
    ssid   => { oid => '.1.3.6.1.4.1.14179.2.1.4.1.7' }, # bsnMobileStationSsid
    status => { oid => '.1.3.6.1.4.1.14179.2.1.4.1.9', map => $map_station_status } # bsnMobileStationStatus
};
my $mapping2 = {
    ap_name    => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.3' }, # bsnAPName
    group_name => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.30' } # bsnAPGroupVlanName
};

my $oid_agentInventoryMachineModel = '.1.3.6.1.4.1.14179.1.1.1.3';
my $oid_bsnDot11EssSsid = '.1.3.6.1.4.1.14179.2.1.1.1.2';
my $oid_bsnAPIfLoadNumOfClients = '.1.3.6.1.4.1.14179.2.2.13.1.4';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_agentInventoryMachineModel },
            { oid => $mapping->{status}->{oid} },
            { oid => $mapping->{ssid}->{oid} },
            { oid => $oid_bsnDot11EssSsid }
        ],
        return_type => 1,
        nothing_quit => 1
    );
    $self->{output}->output_add(
        long_msg => "Model: " . 
            (defined($self->{results}->{$oid_agentInventoryMachineModel}->{$oid_agentInventoryMachineModel . '.0'}) ? $self->{results}->{$oid_agentInventoryMachineModel}->{$oid_agentInventoryMachineModel . '.0'} : 'unknown')
    );

    $self->{global} = {
        total => 0, total_idle => 0, total_aaapending => 0, total_authenticated => 0,
        total_associated => 0, total_powersave => 0, total_disassociated => 0,
        total_tobedeleted => 0, total_probing => 0, total_blacklisted => 0
    };
    $self->{ssid} = {};
    foreach my $oid (keys %$snmp_result) {
        if ($oid =~ /^$oid_bsnDot11EssSsid/ && !defined($self->{ssid}->{ $snmp_result->{$oid} })) {
            if (defined($self->{option_results}->{filter_ssid}) && $self->{option_results}->{filter_ssid} ne '' &&
                $snmp_result->{$oid} !~ /$self->{option_results}->{filter_ssid}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $snmp_result->{$oid} . "': no matching filter.", debug => 1);
                next;
            }
            $self->{ssid}->{ $snmp_result->{$oid} } = { display => $snmp_result->{$oid}, total => 0 };
            next;
        }
        next if ($oid !~ /^$mapping->{ssid}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if (defined($self->{option_results}->{filter_ssid}) && $self->{option_results}->{filter_ssid} ne '' &&
            $result->{ssid} !~ /$self->{option_results}->{filter_ssid}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{ssid} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{ssid}->{ $result->{ssid} } = { display => $result->{ssid}, total => 0 } if (!defined($self->{ssid}->{ $result->{ssid} }));
        $self->{ssid}->{ $result->{ssid} }->{total}++;
        $self->{global}->{total}++;
        $self->{global}->{'total_' . $result->{status}}++;
    }

    return if (defined($self->{option_results}->{ignore_ap_users}));

    my $request = [ { oid => $mapping2->{ap_name}->{oid} }, { oid => $oid_bsnAPIfLoadNumOfClients } ];
    push @$request, { oid => $mapping2->{group_name}->{oid} }
        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '');
    $snmp_result = $options{snmp}->get_multiple_table(
        oids => $request,
        return_type => 1
    );

    # check by ap
    $self->{ap} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping2->{ap_name}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $instance);
        if (defined($self->{option_results}->{filter_ap}) && $self->{option_results}->{filter_ap} ne '' &&
            $result->{ap_name} !~ /$self->{option_results}->{filter_ap}/) {
            $self->{output}->output_add(long_msg => "skipping access point '" . $result->{ap_name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '' &&
            $result->{group_name} !~ /$self->{option_results}->{filter_group}/) {
            $self->{output}->output_add(long_msg => "skipping access point '" . $result->{ap_name} . "': no matching filter.", debug => 1);
            next;
        }

        foreach my $oid2 (keys %$snmp_result) {
            next if ($oid2 !~ /^$oid_bsnAPIfLoadNumOfClients\.$instance\./);
            $self->{ap}->{$instance} = { display => $result->{ap_name}, total => 0 } if (!defined($self->{ap}->{$instance}));
            $self->{ap}->{$instance}->{total} += $snmp_result->{$oid2};
        }
    }
}

1;

__END__

=head1 MODE

Check users connected (total, by SSID, by AP).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total|total-idle$'

=item B<--filter-ssid>

Filter by SSID (can be a regexp).

=item B<--filter-ap>

Filter by access point name (can be a regexp).

=item B<--filter-group>

Filter by access point group (can be a regexp).

=item B<--ignore-ap-users>

Unmonitor users by access points.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total', 'total-idle', 'total-aaapending', 'total-authenticated',
'total-associated', 'total-powersave', 'total-disassociated', 'total-tobedeleted',
'total-probing', 'total-blacklisted', 'ssid', 'ap'.

=back

=cut
