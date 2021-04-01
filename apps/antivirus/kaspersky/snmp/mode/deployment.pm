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

package apps::antivirus::kaspersky::snmp::mode::deployment;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("Deployment status is '%s'", $self->{result_values}->{status});
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_deploymentStatus'};
    return 0;
}

sub custom_progress_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(
        label => 'progress',
        nlabel => $self->{nlabel},
        value => $self->{result_values}->{installed},
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_progress_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = defined($self->{instance_mode}->{option_results}->{percent}) ? $self->{result_values}->{prct_installed} : $self->{result_values}->{installed} ;
    $exit = $self->{perfdata}->threshold_check(
        value => $threshold_value,
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_progress_output {
    my ($self, %options) = @_;

    return sprintf(
        "Deployment progress: %d/%d (%.2f%%)", 
        $self->{result_values}->{installed}, 
        $self->{result_values}->{total}, 
        $self->{result_values}->{prct_installed}
    );
}

sub custom_progress_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_hostsInGroups'};
    $self->{result_values}->{installed} = $options{new_datas}->{$self->{instance} . '_hostsWithAntivirus'};
    $self->{result_values}->{prct_installed} = ($self->{result_values}->{total} != 0) ? $self->{result_values}->{installed} * 100 / $self->{result_values}->{total} : 0;

    return 0;
}

sub custom_expiring_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(
        label => 'expiring',
        nlabel => $self->{nlabel},
        value => $self->{result_values}->{expiring},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_expiring_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{expiring},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_expiring_output {
    my ($self, %options) = @_;

    my $msg = sprintf("%d host(s) with expiring licence", $self->{result_values}->{expiring});
    $msg .= sprintf(" [serial: %s] [days: %d]", $self->{result_values}->{serial}, $self->{result_values}->{days}) if ($self->{result_values}->{serial} ne '');
    return $msg;
}

sub custom_expiring_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{serial} = $options{new_datas}->{$self->{instance} . '_licenceExpiringSerial'};
    $self->{result_values}->{days} = $options{new_datas}->{$self->{instance} . '_licenceExpiringDays'};
    $self->{result_values}->{expiring} = $options{new_datas}->{$self->{instance} . '_hostsLicenceExpiring'};

    return 0;
}

sub custom_expired_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(
        label => 'expired',
        nlabel => $self->{nlabel},
        value => $self->{result_values}->{expired},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_expired_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{expired},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_expired_output {
    my ($self, %options) = @_;

    my $msg = sprintf("%d host(s) with expired licence", $self->{result_values}->{expired});
    $msg .= sprintf(" [serial: %s]", $self->{result_values}->{serial}) if ($self->{result_values}->{serial} ne '');
    return $msg;
}

sub custom_expired_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{serial} = $options{new_datas}->{$self->{instance} . '_licenceExpiredSerial'};
    $self->{result_values}->{expired} = $options{new_datas}->{$self->{instance} . '_hostsLicenceExpired'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];

    $self->{maps_counters}->{global} = [
        { 
            label => 'status', 
            type => 2, 
            warning_default => '%{status} =~ /Warning/i', 
            critical_default => '%{status} =~ /Critical/i', 
            set => {
                key_values => [ { name => 'deploymentStatus' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },
        { label => 'progress', nlabel => 'hosts.antivirus.installed.count', set => {
                key_values => [ { name => 'hostsInGroups' }, { name => 'hostsWithAntivirus' } ],
                closure_custom_calc => $self->can('custom_progress_calc'),
                closure_custom_output => $self->can('custom_progress_output'),
                closure_custom_threshold_check => $self->can('custom_progress_threshold'),
                closure_custom_perfdata => $self->can('custom_progress_perfdata'),
            }
        },
        { label => 'failed', nlabel => 'hosts.antivirus.install.failed.count', set => {
                key_values => [ { name => 'hostsRemoteInstallFailed' } ],
                output_template => '%d failed remote installation(s)',
                perfdatas => [
                    { label => 'failed', template => '%d', min => 0 },
                ]
            }
        },
        { label => 'expiring', nlabel => 'hosts.expiring.licence.count', set => {
                key_values => [ { name => 'licenceExpiringSerial' }, { name => 'licenceExpiringDays' }, { name => 'hostsLicenceExpiring' } ],
                closure_custom_calc => $self->can('custom_expiring_calc'),
                closure_custom_output => $self->can('custom_expiring_output'),
                closure_custom_threshold_check => $self->can('custom_expiring_threshold'),
                closure_custom_perfdata => $self->can('custom_expiring_perfdata'),
            }
        },
        { label => 'expired', nlabel => 'hosts.expired.licence.count', set => {
                key_values => [ { name => 'licenceExpiredSerial' }, { name => 'hostsLicenceExpired' } ],
                closure_custom_calc => $self->can('custom_expired_calc'),
                closure_custom_output => $self->can('custom_expired_output'),
                closure_custom_threshold_check => $self->can('custom_expired_threshold'),
                closure_custom_perfdata => $self->can('custom_expired_perfdata'),
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'percent' => { name => 'percent' }
    });

    return $self;
}

my %map_status = (
    0 => 'OK',
    1 => 'Info',
    2 => 'Warning',
    3 => 'Critical'
);

my $oid_deploymentStatus = '.1.3.6.1.4.1.23668.1093.1.1.1';
my $oid_hostsInGroups = '.1.3.6.1.4.1.23668.1093.1.1.3';
my $oid_hostsWithAntivirus = '.1.3.6.1.4.1.23668.1093.1.1.4';
my $oid_hostsRemoteInstallFailed = '.1.3.6.1.4.1.23668.1093.1.1.5';
my $oid_licenceExpiringSerial = '.1.3.6.1.4.1.23668.1093.1.1.6';
my $oid_licenceExpiredSerial = '.1.3.6.1.4.1.23668.1093.1.1.7';
my $oid_licenceExpiringDays = '.1.3.6.1.4.1.23668.1093.1.1.8';
my $oid_hostsLicenceExpiring = '.1.3.6.1.4.1.23668.1093.1.1.9';
my $oid_hostsLicenceExpired = '.1.3.6.1.4.1.23668.1093.1.1.10';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            $oid_deploymentStatus, $oid_hostsInGroups,
            $oid_hostsWithAntivirus, $oid_hostsRemoteInstallFailed,
            $oid_licenceExpiringSerial, $oid_licenceExpiredSerial,
            $oid_licenceExpiringDays, $oid_hostsLicenceExpiring, 
            $oid_hostsLicenceExpired
        ],
        nothing_quit => 1
    );

    $self->{global} = { 
        deploymentStatus => $map_status{$snmp_result->{$oid_deploymentStatus}},
        hostsInGroups => $snmp_result->{$oid_hostsInGroups},
        hostsWithAntivirus => $snmp_result->{$oid_hostsWithAntivirus},
        hostsRemoteInstallFailed => $snmp_result->{$oid_hostsRemoteInstallFailed},
        licenceExpiringSerial => $snmp_result->{$oid_licenceExpiringSerial},
        licenceExpiredSerial => $snmp_result->{$oid_licenceExpiredSerial},
        licenceExpiringDays => $snmp_result->{$oid_licenceExpiringDays},
        hostsLicenceExpiring => $snmp_result->{$oid_hostsLicenceExpiring},
        hostsLicenceExpired => $snmp_result->{$oid_hostsLicenceExpired},
    };
}

1;

__END__

=head1 MODE

Check antivirus software deployment status.

=over 8

=item B<--warning-status>

Set warning threshold for status. (Default: '%{status} =~ /Warning/i').
Can use special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status. (Default: '%{status} =~ /Critical/i').
Can use special variables like: %{status}

=item B<--warning-*>

Threshold warning.
Can be: 'progress' (counter or %), 'failed', 'expiring', 'expired'.

=item B<--critical-*>

Threshold critical.
Can be: 'progress' (counter or %), 'failed', 'expiring', 'expired'.

=item B<--percent>

Set this option if you want to use percent on progress thresholds.

=back

=cut
