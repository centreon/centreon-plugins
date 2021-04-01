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

package network::sophos::es::snmp::mode::components::system;

use strict;
use warnings;

my %map_status = (0 => 'unknown', 1 => 'disabled', 2 => 'ok', 3 => 'warn', 4 => 'error');

my $mapping = {
    seaClusterStatus                        => { oid => '.1.3.6.1.4.1.2604.2.1.1.1', map => \%map_status, type => 'Cluster' },
    seaNodeStatus                           => { oid => '.1.3.6.1.4.1.2604.2.1.1.2', map => \%map_status, type => 'Node' },
    seaRebootStatus                         => { oid => '.1.3.6.1.4.1.2604.2.1.1.3', map => \%map_status, type => 'Reboot' },
    seaStatusMailConnections                => { oid => '.1.3.6.1.4.1.2604.2.1.1.4', map => \%map_status, type => 'MailConnections' },
    seaStatusMailDiskUsage                  => { oid => '.1.3.6.1.4.1.2604.2.1.1.5', map => \%map_status, type => 'MailDiskUsage' },
    seaStatusMailDiskUsageQuarantine        => { oid => '.1.3.6.1.4.1.2604.2.1.1.6', map => \%map_status, type => 'MailDiskUsageQuarantine' },
    seaStatusMailLdapSync                   => { oid => '.1.3.6.1.4.1.2604.2.1.1.7', map => \%map_status, type => 'MailLdapSync' },
    seaStatusDeliveryQueue                  => { oid => '.1.3.6.1.4.1.2604.2.1.1.8', map => \%map_status, type => 'DeliveryQueue' },
    seaStatusIncomingQueue                  => { oid => '.1.3.6.1.4.1.2604.2.1.1.9', map => \%map_status, type => 'IncomingQueue' },
    seaStatusMailTLSError                   => { oid => '.1.3.6.1.4.1.2604.2.1.1.10', map => \%map_status, type => 'MailTLSError' },
    seaStatusSoftwareConfigBackup           => { oid => '.1.3.6.1.4.1.2604.2.1.1.11', map => \%map_status, type => 'ConfigBackup' },
    seaStatusSoftwareLogfileBackup          => { oid => '.1.3.6.1.4.1.2604.2.1.1.12', map => \%map_status, type => 'LogfileBackup' },
    seaStatusSoftwareQuarantineBackup       => { oid => '.1.3.6.1.4.1.2604.2.1.1.13', map => \%map_status, type => 'QuarantineBackup' },
    seaStatusSoftwareClusterConnect         => { oid => '.1.3.6.1.4.1.2604.2.1.1.14', map => \%map_status, type => 'ClusterConnect' },
    seaStatusSoftwareClusterSync            => { oid => '.1.3.6.1.4.1.2604.2.1.1.15', map => \%map_status, type => 'ClusterSync' },
    seaStatusSoftwareProcessHealth          => { oid => '.1.3.6.1.4.1.2604.2.1.1.16', map => \%map_status, type => 'ProcessHealth' },
    seaStatusSoftwareQuarantineSummary      => { oid => '.1.3.6.1.4.1.2604.2.1.1.17', map => \%map_status, type => 'QuarantineSummary' },
    seaStatusSoftwareSystemLoad             => { oid => '.1.3.6.1.4.1.2604.2.1.1.18', map => \%map_status, type => 'SystemLoad' },
    seaStatusSoftwareUpdateConnection       => { oid => '.1.3.6.1.4.1.2604.2.1.1.19', map => \%map_status, type => 'UpdateConnection' },
    seaStatusSoftwareUpdateDataInstall      => { oid => '.1.3.6.1.4.1.2604.2.1.1.20', map => \%map_status, type => 'UpdateDataInstall' },
    seaStatusSoftwareUpdatePendingreboot    => { oid => '.1.3.6.1.4.1.2604.2.1.1.21', map => \%map_status, type => 'UpdatePendingreboot' },
    seaStatusSoftwareUpgradeAvailable       => { oid => '.1.3.6.1.4.1.2604.2.1.1.22', map => \%map_status, type => 'UpgradeAvailable' },
    seaStatusSoftwareUpgradeConnection      => { oid => '.1.3.6.1.4.1.2604.2.1.1.23', map => \%map_status, type => 'UpgradeConnection' },
    seaStatusSoftwareUpgradeDownload        => { oid => '.1.3.6.1.4.1.2604.2.1.1.24', map => \%map_status, type => 'UpgradeDownload' },
    seaStatusSoftwareUpgradeInstall         => { oid => '.1.3.6.1.4.1.2604.2.1.1.25', map => \%map_status, type => 'UpgradeInstall' },
    seaStatusSystemCertificate              => { oid => '.1.3.6.1.4.1.2604.2.1.1.26', map => \%map_status, type => 'Certificate' },
    seaStatusSystemLicense                  => { oid => '.1.3.6.1.4.1.2604.2.1.1.27', map => \%map_status, type => 'License' },
    seaStatusSystemCrossWired               => { oid => '.1.3.6.1.4.1.2604.2.1.1.28', map => \%map_status, type => 'CrossWired' },
    seaStatusSystemSpxTrialLicense          => { oid => '.1.3.6.1.4.1.2604.2.1.1.29', map => \%map_status, type => 'SpxTrialLicense' },
    seaStatusSpxQueue                       => { oid => '.1.3.6.1.4.1.2604.2.1.1.30', map => \%map_status, type => 'SpxQueue' },
    seaStatusSpxFailureQueue                => { oid => '.1.3.6.1.4.1.2604.2.1.1.31', map => \%map_status, type => 'SpxFailureQueue' },
    seaStatusSpxEncryption                  => { oid => '.1.3.6.1.4.1.2604.2.1.1.32', map => \%map_status, type => 'SpxEncryption' },
    seaStatusSystemSandboxLicense           => { oid => '.1.3.6.1.4.1.2604.2.1.1.33', map => \%map_status, type => 'SandboxLicense' },
    seaStatusSoftwareSyslogProcess          => { oid => '.1.3.6.1.4.1.2604.2.1.1.34', map => \%map_status, type => 'SyslogProcess' },
    seaStatusSoftwareSyslogConnection       => { oid => '.1.3.6.1.4.1.2604.2.1.1.35', map => \%map_status, type => 'SyslogConnection' },
    seaStatusSoftwareCloned                 => { oid => '.1.3.6.1.4.1.2604.2.1.1.36', map => \%map_status, type => 'Cloned' },
    seaStatusMailException                  => { oid => '.1.3.6.1.4.1.2604.2.1.1.37', map => \%map_status, type => 'MailException' },
    seaStatusMailShostError                 => { oid => '.1.3.6.1.4.1.2604.2.1.1.38', map => \%map_status, type => 'MailShostError' },
    seaStatusSystemTrialLicense             => { oid => '.1.3.6.1.4.1.2604.2.1.1.39', map => \%map_status, type => 'TrialLicense' },
};
my $oid_sophosSysEmail = '.1.3.6.1.4.1.2604.2.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_sophosSysEmail };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking system");
    $self->{components}->{system} = {name => 'system', total => 0, skip => 0};
    return if ($self->check_filter(section => 'system'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_sophosSysEmail});
    if (scalar(keys %$result) == 0) {
        $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_sophosSysEmail}, instance => '0');
        return  (scalar(keys %$result) == 0);
    }
    
    foreach (keys %{$mapping}) {
        next if ($self->check_filter(section => 'system', instance => $mapping->{$_}->{type}));
        
        $self->{components}->{system}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("system '%s' status is '%s' [instance: %s].",
                                    $mapping->{$_}->{type}, $result->{$_},
                                    $mapping->{$_}->{type}
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'system', instance => $mapping->{$_}->{type}, value => $result->{$_});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("system '%s' status is '%s'",
                                                             $mapping->{$_}->{type}, $result->{$_}));
        }
    }
}

1;