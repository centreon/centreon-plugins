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

package network::colubris::snmp::mode::apusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'operational state: ' . $self->{result_values}->{state};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'ap', type => 1, cb_prefix_output => 'prefix_ap_output', message_multiple => 'All access points are OK' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total-ap', set => {
                key_values => [ { name => 'total_ap' } ],
                output_template => 'total AP: %s',
                perfdatas => [
                    { label => 'total_ap', value => 'total_ap', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'total-users', set => {
                key_values => [ { name => 'total_users' } ],
                output_template => 'total users: %s',
                perfdatas => [
                    { label => 'total_users', value => 'total_users', template => '%s', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{ap} = [
        { label => 'ap-status', threshold => 0,  set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'ap-users', set => {
                key_values => [ { name => 'users' }, { name => 'display' } ],
                output_template => 'current users: %s',
                perfdatas => [
                    { label => 'ap_users', value => 'users', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_ap_output {
    my ($self, %options) = @_;

    return "AP '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'             => { name => 'filter_name' },
        'check-device-without-ctrl' => { name => 'check_device_without_ctrl' },
        'warning-ap-status:s'       => { name => 'warning_ap_status', default => '' },
        'critical-ap-status:s'      => { name => 'critical_ap_status', default => '%{state} eq "disconnected"' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_ap_status', 'critical_ap_status']);
}

my %map_device_state = (
    1 => 'disconnected', 2 => 'authorized', 3 => 'join', 4 => 'firmware',
    5 => 'security', 6 => 'configuration', 7 => 'running'
);

my $mapping = {
    coDevDisState            => { oid => '.1.3.6.1.4.1.8744.5.23.1.2.1.1.5', map => \%map_device_state },
    coDevDisSystemName       => { oid => '.1.3.6.1.4.1.8744.5.23.1.2.1.1.6' },
    coDevDisControllerIndex  => { oid => '.1.3.6.1.4.1.8744.5.23.1.2.1.1.11' },
};

my $mapping2 = {
    coDevWirCliStaMACAddress    => { oid => '.1.3.6.1.4.1.8744.5.25.1.7.1.1.2' },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "colubris_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));

    my $oid_coDeviceDiscoveryEntry = '.1.3.6.1.4.1.8744.5.23.1.2.1.1';
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_coDeviceDiscoveryEntry, start => $mapping->{coDevDisState}->{oid}, end => $mapping->{coDevDisSystemName}->{oid} },
            { oid => $mapping->{coDevDisControllerIndex}->{oid} },
            { oid => $mapping2->{coDevWirCliStaMACAddress}->{oid} },
        ], 
        nothing_quit => 1,
        return_type => 1
    );

    $self->{global} = { total_ap => 0, total_users => 0 };
    $self->{ap} = {};
    my @oids = $options{snmp}->oid_lex_sort(keys %$snmp_result);
    my $checked = {};
    foreach my $oid (reverse @oids) {
        next if ($oid !~ /^$mapping->{coDevDisSystemName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{coDevDisSystemName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{coDevDisSystemName} . "': no matching filter.", debug => 1);
            next;
        }
        if (!defined($self->{option_results}->{check_device_without_ctrl})) {
            if ($result->{coDevDisControllerIndex} == 0) {
                $self->{output}->output_add(long_msg => "skipping '" . $result->{coDevDisSystemName} . "': no controller associated.", debug => 1);
                next;
            }
        }
        if (defined($checked->{$result->{coDevDisSystemName}})) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{coDevDisSystemName} . "': duplicated name.", debug => 1);
            next;
        }

        $checked->{$result->{coDevDisSystemName}} = 1;
        $self->{global}->{total_ap}++;
        $self->{ap}->{$instance} = {
            display => $result->{coDevDisSystemName},
            state => $result->{coDevDisState},
            users => 0,
        };
    }

    foreach my $oid (sort keys %$snmp_result) {
        next if ($oid !~ /^$mapping2->{coDevWirCliStaMACAddress}->{oid}\.(.*?)\./);
        my $instance = $1;

        next if (!defined($self->{ap}->{$instance}));

        $self->{global}->{total_users}++;
        $self->{ap}->{$instance}->{users}++;
    }

    if (scalar(keys %{$self->{ap}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No access point found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check AP status and users connected.

=over 8

=item B<--filter-name>

Filter ap name with regexp.

=item B<--check-device-without-ctrl>

Check device even if it doesn't belongs to an controller team.

=item B<--warning-*>

Threshold warning.
Can be: 'total-ap', 'total-users', 'ap-users'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-ap', 'total-users', 'ap-users'.

=item B<--warning-ap-status>

Set warning threshold for status.
Can used special variables like: %{state}, %{display}

=item B<--critical-ap-status>

Set critical threshold for status (Default: '%{state} eq "disconnected"').
Can used special variables like: %{state}, %{display}

=back

=cut
