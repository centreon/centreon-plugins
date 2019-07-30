#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package centreon::common::aruba::snmp::mode::license;

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
        $self->{result_values}->{location});
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
        { name => 'license', type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All licenses status are ok' },
    ];

    $self->{maps_counters}->{license} = [
        { label => 'status', set => {
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
                    { value => 'wlanAPUpTime_absolute', template => '%s',
                      unit => 's', label_extra_instance => 1, instance_use => 'wlanAPName_absolute' },
                ],
            }
        },
        { label => 'controller-bootstrap', nlabel => 'accesspoint.controller.bootstrap.count', set => {
                key_values => [ { name => 'wlanAPNumBootstraps' }, { name => 'wlanAPName' } ],
                output_template => 'Controller Bootstrap Count: %d',
                perfdatas => [
                    { value => 'wlanAPNumBootstraps_absolute', template => '%d',
                      label_extra_instance => 1, instance_use => 'wlanAPName_absolute' },
                ],
            }
        },
        { label => 'reboot', nlabel => 'accesspoint.reboot.count', set => {
                key_values => [ { name => 'wlanAPNumReboots' }, { name => 'wlanAPName' } ],
                output_template => 'Reboot Count: %d',
                perfdatas => [
                    { value => 'wlanAPNumReboots_absolute', template => '%d',
                      label_extra_instance => 1, instance_use => 'wlanAPName_absolute' },
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "License '" . $options{instance_value}->{sysExtLicenseKey} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "warning-status:s"  => { name => 'warning_status' },
        "critical-status:s" => { name => 'critical_status', default => '%{status} !~ /up/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_status = (
    1 => 'up', 2 => 'down'
);

my $oid_wlsxSysExtSwitchLicenseTable = '.1.3.6.1.4.1.14823.2.2.1.2.1.20.1';

my $mapping = {
    sysExtLicenseKey => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.20.1.2' },
    sysExtLicenseExpires => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.20.1.4' },
    sysExtLicenseService=> { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.20.1.6' },
    # wlanAPStatus => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.20', map => \%map_status },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_wlsxSysExtSwitchLicenseTable,
        start => $mapping->{sysExtLicenseKey}->{oid},
        end => $mapping->{sysExtLicenseService}->{oid},
        nothing_quit => 1
    );
    
    $self->{license} = {};
    
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{sysExtLicenseKey}->{oid}\.(.*)/);
        my $instance = $1;
        
        my $result = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result,
            instance => $instance
        );

        $self->{license}->{$result->{sysExtLicenseKey}} = { %{$result} };
    }
    use Data::Dumper;
    print Dumper $self->{license};
    
    if (scalar(keys %{$self->{license}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No license found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check license (WLSX-SYSTEMEXT-MIB).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'connected-current' (global), 'uptime',
'controller-bootstrap', 'reboot', 'status' (per AP).
'status' can use special variables like: %{name},
%{status}, %{ip}, %{group}, %{location} (Default: '')

=item B<--critical-*>

Threshold critical.
Can be: 'connected-current' (global), 'uptime',
'controller-bootstrap', 'reboot', 'status' (per AP).
'status' can use special variables like: %{name},
%{status}, %{ip}, %{group}, %{location} (Default: '%{status} !~ /up/i')

=back

=cut
