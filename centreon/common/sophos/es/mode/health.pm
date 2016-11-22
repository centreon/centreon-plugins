#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package centreon::common::sophos::es::mode::health;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %maps_state = (
    0 => 'Unknow',
    1 => 'Disabled',
    2 => 'Ok',
    3 => 'Warn',
    4 => 'Error',
);


my %maps_oid = (
    '.1.3.6.1.4.1.2604.2.1.1.1' => 'ClusterStatus',
    '.1.3.6.1.4.1.2604.2.1.1.2' => 'NodeStatus',
    '.1.3.6.1.4.1.2604.2.1.1.3' => 'RebootStatus',
    '.1.3.6.1.4.1.2604.2.1.1.4' => 'StatusMailConnections',
    '.1.3.6.1.4.1.2604.2.1.1.5' => 'StatusMailDiskUsage',
    '.1.3.6.1.4.1.2604.2.1.1.6' => 'StatusMailDiskUsageQuarantine',
    '.1.3.6.1.4.1.2604.2.1.1.7' => 'StatusMailLdapSync',
    '.1.3.6.1.4.1.2604.2.1.1.8' => 'StatusDeliveryQueue',
    '.1.3.6.1.4.1.2604.2.1.1.9' => 'StatusIncomingQueue',
    '.1.3.6.1.4.1.2604.2.1.1.10' => 'StatusMailTLSError',
    '.1.3.6.1.4.1.2604.2.1.1.11' => 'StatusSoftwareConfigBackup',
    '.1.3.6.1.4.1.2604.2.1.1.12' => 'StatusSoftwareLogfileBackup',
    '.1.3.6.1.4.1.2604.2.1.1.13' => 'StatusSoftwareQuarantineBackup',
    '.1.3.6.1.4.1.2604.2.1.1.14' => 'StatusSoftwareClusterConnect',
    '.1.3.6.1.4.1.2604.2.1.1.15' => 'StatusSoftwareClusterSync',
    '.1.3.6.1.4.1.2604.2.1.1.16' => 'StatusSoftwareProcessHealth',
    '.1.3.6.1.4.1.2604.2.1.1.17' => 'StatusSoftwareQuarantineSummary',
    '.1.3.6.1.4.1.2604.2.1.1.18' => 'StatusSoftwareSystemLoad',
    '.1.3.6.1.4.1.2604.2.1.1.19' => 'StatusSoftwareUpdateConnection',
    '.1.3.6.1.4.1.2604.2.1.1.20' => 'StatusSoftwareDataInstall',
    '.1.3.6.1.4.1.2604.2.1.1.21' => 'StatusSoftwareUpdatePendingReboot',
    '.1.3.6.1.4.1.2604.2.1.1.22' => 'StatusSoftwareUpgradeAvailable',
    '.1.3.6.1.4.1.2604.2.1.1.23' => 'StatusSoftwareUpgradeConnection',
    '.1.3.6.1.4.1.2604.2.1.1.24' => 'StatusSoftwareUpgradeDownload',
    '.1.3.6.1.4.1.2604.2.1.1.25' => 'StatusSoftwareUpgradeInstall',
    '.1.3.6.1.4.1.2604.2.1.1.26' => 'StatusSystemCertificate',
    '.1.3.6.1.4.1.2604.2.1.1.27' => 'StatusSystemLicence',
    '.1.3.6.1.4.1.2604.2.1.1.28' => 'StatusSystemCrossWired',
    '.1.3.6.1.4.1.2604.2.1.1.29' => 'StatusSystemSpxTrialLicense',
    '.1.3.6.1.4.1.2604.2.1.1.30' => 'StatusSystemSpxQueue',
    '.1.3.6.1.4.1.2604.2.1.1.31' => 'StatusSystemSpxFailureQueue',
    '.1.3.6.1.4.1.2604.2.1.1.32' => 'StatusSystemEncryption',
    '.1.3.6.1.4.1.2604.2.1.1.33' => 'StatusSystemSandboxingLicense',
    '.1.3.6.1.4.1.2604.2.1.1.34' => 'StatusSystemSyslogProcess',
    '.1.3.6.1.4.1.2604.2.1.1.35' => 'StatusSystemSyslogConnection',
    '.1.3.6.1.4.1.2604.2.1.1.36' => 'StatusSystemSoftwareCloned',
    '.1.3.6.1.4.1.2604.2.1.1.37' => 'StatusMailException',
    '.1.3.6.1.4.1.2604.2.1.1.38' => 'StatusMailShostError',
    '.1.3.6.1.4.1.2604.2.1.1.39' => 'StatusSystemTrialLicense',
);


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{perfdata}->threshold_validate(label => 'ok', value => 1);
    $self->{perfdata}->threshold_validate(label => 'warning', value => 2);
    $self->{perfdata}->threshold_validate(label => 'critical', value => 3);
}


sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oids = '.1.3.6.1.4.1.2604.2.1.1';


    $self->{result_names} = $self->{snmp}->get_table(oid => $oids,nothing_quit => 1);
    my $output = "";
    my $value = 0;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{result_names}})) {
       if(exists $maps_oid{$oid}) {
           my $val = $self->{result_names}->{$oid};
           $output =  $output . $maps_oid{$oid} . " : " . $maps_state{$val};
           $output = $output ."\n";
           if($val > $value) {
              $value = $val;
           }
       }
    }

#use Data::Dumper;
#print Dumper($results);

     my $exit_code = $self->{perfdata}->threshold_check(value => $value,
                                                     threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);


    $self->{output}->output_add(severity => $exit_code,
                                short_msg => "");

    $self->{output}->output_add(long_msg => $output);

    $self->{output}->perfdata_add(label => 'output', unit => '',
                                  value => sprintf("%d", $value),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);



    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Sophos ES health

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.


=back

=cut
