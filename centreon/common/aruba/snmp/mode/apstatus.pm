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

package centreon::common::aruba::snmp::mode::apstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Status is '%s' [Ip: %s][Group: %s][Location: %s]",
        $self->{result_values}->{status},
        $self->{result_values}->{ip},
        $self->{result_values}->{group},
        $self->{result_values}->{location}
    );
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_wlanAPName'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_wlanAPStatus'};
    $self->{result_values}->{ip} = $options{new_datas}->{$self->{instance} . '_wlanAPIpAddress'};
    $self->{result_values}->{group} = $options{new_datas}->{$self->{instance} . '_wlanAPGroupName'};
    $self->{result_values}->{location} = $options{new_datas}->{$self->{instance} . '_wlanAPLocation'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_init => 'skip_global' },
        { name => 'ap', type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All AP status are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'connected-current', nlabel => 'accesspoints.connected.current.count', set => {
                key_values => [ { name => 'connected' } ],
                output_template => 'Total connected AP: %d',
                perfdatas => [
                    { value => 'connected', template => '%d', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{ap} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'wlanAPName' }, { name => 'wlanAPIpAddress' }, { name => 'wlanAPGroupName' },
                    { name => 'wlanAPLocation' }, { name => 'wlanAPStatus' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'uptime', nlabel => 'accesspoint.uptime.seconds', set => {
                key_values => [ { name => 'wlanAPUpTime' }, { name => 'wlanAPName' } ],
                output_template => 'Uptime: %ss',
                perfdatas => [
                    { value => 'wlanAPUpTime', template => '%s',
                      unit => 's', label_extra_instance => 1, instance_use => 'wlanAPName' },
                ],
            }
        },
        { label => 'controller-bootstrap', nlabel => 'accesspoint.controller.bootstrap.count', set => {
                key_values => [ { name => 'wlanAPNumBootstraps' }, { name => 'wlanAPName' } ],
                output_template => 'Controller Bootstrap Count: %d',
                perfdatas => [
                    { value => 'wlanAPNumBootstraps', template => '%d',
                      label_extra_instance => 1, instance_use => 'wlanAPName' },
                ],
            }
        },
        { label => 'reboot', nlabel => 'accesspoint.reboot.count', set => {
                key_values => [ { name => 'wlanAPNumReboots' }, { name => 'wlanAPName' } ],
                output_template => 'Reboot Count: %d',
                perfdatas => [
                    { value => 'wlanAPNumReboots', template => '%d',
                      label_extra_instance => 1, instance_use => 'wlanAPName' },
                ],
            }
        },
    ];
}

sub skip_global {
    my ($self, %options) = @_;

    scalar(keys %{$self->{ap}}) > 1 ? return(0) : return(1);
}

sub prefix_output {
    my ($self, %options) = @_;

    return "AP '" . $options{instance_value}->{wlanAPName} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-ip:s'       => { name => 'filter_ip' },
        'filter-name:s'     => { name => 'filter_name' },
        'filter-group:s'    => { name => 'filter_group' },
        'warning-status:s'  => { name => 'warning_status' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} !~ /up/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my $map_status = { 1 => 'up', 2 => 'down' };

my $oid_wlsxWlanAPTable = '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1';

my $mapping_info = {
    wlanAPIpAddress => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.2' },
    wlanAPName      => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.3' },
    wlanAPGroupName => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.4' },
};
my $mapping_stat = {
    wlanAPUpTime        => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.12' },
    wlanAPLocation      => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.14' },
    wlanAPStatus        => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.19', map => $map_status },
    wlanAPNumBootstraps => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.20' },
    wlanAPNumReboots    => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.21' },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global}->{connected} = 0;
    $self->{ap} = {};

    my $snmp_info = $options{snmp}->get_table(
        oid => $oid_wlsxWlanAPTable,
        start => $mapping_info->{wlanAPIpAddress}->{oid},
        end => $mapping_info->{wlanAPGroupName}->{oid},
        nothing_quit => 1
    );

    foreach my $oid (keys %{$snmp_info}) {
        next if ($oid !~ /^$mapping_info->{wlanAPIpAddress}->{oid}\.(.*)/);
        my $instance = $1;
        
        my $result = $options{snmp}->map_instance(
            mapping => $mapping_info,
            results => $snmp_info,
            instance => $instance
        );
        
        if (defined($self->{option_results}->{filter_ip}) && $self->{option_results}->{filter_ip} ne '' &&
            $result->{wlanAPIpAddress} !~ /$self->{option_results}->{filter_ip}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{wlanAPIpAddress} . "': no matching filter ip.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{wlanAPName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{wlanAPName} . "': no matching filter name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '' &&
            $result->{wlanAPGroupName} !~ /$self->{option_results}->{filter_group}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{wlanAPGroupName} . "': no matching filter group.", debug => 1);
            next;
        }
        
        $self->{ap}->{$instance} = { %{$result} };
    }

    if (scalar(keys %{$self->{ap}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No AP found.");
        $self->{output}->option_exit();
    }

    $options{snmp}->load(
        oids => [
            $mapping_stat->{wlanAPUpTime}->{oid},
            $mapping_stat->{wlanAPLocation}->{oid},
            $mapping_stat->{wlanAPStatus}->{oid},
            $mapping_stat->{wlanAPNumBootstraps}->{oid},
            $mapping_stat->{wlanAPNumReboots}->{oid},
        ],
        instances => [ keys %{$self->{ap}} ],
        instance_regexp => '^(.*)$'
    );

    my $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping_stat->{wlanAPUpTime}->{oid}\.(.*)/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(
            mapping => $mapping_stat,
            results => $snmp_result,
            instance => $instance
        );

        $self->{ap}->{$instance} = { %{$self->{ap}->{$instance}}, %{$result}, wlanAPUpTime => $result->{wlanAPUpTime} / 100 };
        $self->{global}->{connected}++;
    }
}

1;

__END__

=head1 MODE

Check AP status (WLSX-WLAN-MIB).

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'connected-current' (global), 'uptime',
'controller-bootstrap', 'reboot', 'status' (per AP).

'status' can use special variables like: %{name},
%{status}, %{ip}, %{group}, %{location} (Default: '')

=item B<--filter-*>

Filter by 'ip', 'name', 'group' (regexp can be used).

=back

=cut
