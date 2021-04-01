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

package apps::vmware::wsman::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use apps::vmware::wsman::mode::components::resources qw($mapping_HealthState $mapping_OperationalStatus);

sub set_system {
    my ($self, %options) = @_;
    
    $self->{regexp_threshold_numeric_check_section_option} = '^(cim_numericsensor)$';
    
    $self->{cb_hook1} = 'get_type';
    
    $self->{thresholds} = {
        default => [    
            ['Unknown', 'OK'],
            ['OK', 'OK'],
            ['Degraded', 'WARNING'],
            ['Minor failure', 'WARNING'],
            ['Major failure', 'CRITICAL'],
            ['Critical failure', 'CRITICAL'],
            ['Non-recoverable error', 'CRITICAL'],
            
            ['Other', 'UNKNOWN'],
            ['Stressed', 'WARNING'],
            ['Predictive Failure', 'WARNING'],
            ['Error', 'CRITICAL'],
            ['Starting', 'OK'],
            ['Stopping', 'WARNING'],
            ['In Service', 'OK'],
            ['No Contact', 'CRITICAL'],
            ['Lost Communication', 'CRITICAL'],
            ['Aborted', 'CRITICAL'],
            ['Dormant', 'OK'],
            ['Supporting Entity in Error', 'CRITICAL'],
            ['Completed', 'OK'],
            ['Power Mode', 'OK'],
            ['Relocating', 'WARNING'],
        ],
    };
    
    $self->{components_path} = 'apps::vmware::wsman::mode::components';
    $self->{components_module} = ['omc_discretesensor', 'omc_fan', 'omc_psu', 'vmware_storageextent', 'vmware_controller',
        'vmware_storagevolume', 'vmware_battery', 'vmware_sassataport', 'cim_card',
        'cim_computersystem', 'cim_numericsensor', 'cim_memory', 'cim_processor', 'cim_recordlog'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                });
    
    return $self;
}

sub get_type {
    my ($self, %options) = @_;
    
    my $result = $options{wsman}->request(uri => 'http://schema.omc-project.org/wbem/wscim/1/cim-schema/2/OMC_SMASHFirmwareIdentity', dont_quit => 1);
    $result = pop(@$result) if (defined($result));
    $self->{manufacturer} = 'unknown';
    if (defined($result->{Manufacturer}) && $result->{Manufacturer} ne '') {
        $self->{manufacturer} = $result->{Manufacturer};
    }
    
    $result = $options{wsman}->request(uri => 'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_Chassis');
    $result = pop(@$result);
    my $model = defined($result->{Model}) && $result->{Model} ne '' ? $result->{Model} : 'unknown';
    
    $self->{output}->output_add(long_msg => sprintf("Manufacturer : %s, Model : %s", $self->{manufacturer}, $model));
    
    $self->{wsman} = $options{wsman};
}

sub get_status {
    my ($self, %options) = @_;
    
    my $status;
    if ($self->{manufacturer} =~ /HP/i) {
        $status = $mapping_HealthState->{$options{entry}->{HealthState}} if (defined($options{entry}->{HealthState}) &&
            defined($mapping_HealthState->{$options{entry}->{HealthState}}));
    } else {
        $status = $mapping_OperationalStatus->{$options{entry}->{OperationalStatus}} if (defined($options{entry}->{OperationalStatus}) && 
            defined($mapping_OperationalStatus->{$options{entry}->{OperationalStatus}}));
    }
    return $status;
}

1;

__END__

=head1 MODE

Check ESXi Hardware.
Example: centreon_plugins.pl --plugin=apps::vmware::wsman::plugin --mode=hardware --hostname='XXX.XXX.XXX.XXX' 
--wsman-username='XXXX' --wsman-password='XXXX'  --wsman-scheme=https --wsman-port=443 --verbose

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'omc_discretesensor', 'omc_fan', 'omc_psu', 'vmware_storageextent', 'vmware_controller',
'vmware_storagevolume', 'vmware_battery', 'vmware_sassataport', 'cim_card',
'cim_computersystem', 'cim_numericsensor', 'cim_memory', 'cim_processor', 'cim_recordlog'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=cim_card --filter=cim_recordlog)
Can also exclude specific instance: --filter='omc_psu,Power Supply 1'

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='cim_card,CRITICAL,^(?!(OK)$)'

=item B<--warning>

Set warning threshold for temperatures (syntax: type,instance,threshold)
Example: --warning='cim_numericsensor,.*,30'

=item B<--critical>

Set critical threshold for temperatures (syntax: type,instance,threshold)
Example: --critical='cim_numericsensor,.*,40'

=back

=cut
