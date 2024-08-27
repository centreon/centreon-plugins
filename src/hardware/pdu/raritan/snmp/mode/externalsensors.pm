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

package hardware::pdu::raritan::snmp::mode::externalsensors;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use hardware::pdu::raritan::snmp::mode::components::resources qw($thresholds %raritan_type);

sub set_system {
    my ($self, %options) = @_;
    
    $self->{cb_threshold_numeric_check_section_option} = 'check_numeric_section_option';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = $thresholds;
    
    $self->{components_path} = 'hardware::pdu::raritan::snmp::mode::components';
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request}, return_type => 1);

    my $oid_pduName = '.1.3.6.1.4.1.13742.6.3.2.2.1.13';
    my $snmp_result = $self->{snmp}->get_table(oid => $oid_pduName, return_type => 1);
    $self->{pduNames} = {};
    foreach (keys %$snmp_result) {
        /\.(\d+)$/;
        $self->{pduNames}->{$1} = $snmp_result->{$_};
    }

    my $oid_externalSensorType = '.1.3.6.1.4.1.13742.6.3.6.3.1.2';
    $snmp_result = $self->{snmp}->get_table(oid => $oid_externalSensorType, return_type => 1);
    $self->{externalSensorType} = {};
    foreach (keys %$snmp_result) {
        /\.(\d+\.\d+)$/;
        $self->{externalSensorType}->{$1} = $snmp_result->{$_};
    }
}

sub check_numeric_section_option {
    my ($self, %options) = @_;
    
    if (!defined($raritan_type{$options{section}})) {
        $self->{output}->add_option_msg(short_msg => "Wrong $options{option_name} option '" . $options{option_value} . "'.");
        $self->{output}->option_exit();
    }
}

sub load_components {
    my ($self, %options) = @_;
    
    my $mod_name = $self->{components_path} . "::sensor";
    centreon::plugins::misc::mymodule_load(
        output => $self->{output}, module => $mod_name,
        error_msg => "Cannot load module '$mod_name'."
    );
    my $func = $mod_name->can('load');
    $func->($self, type => 'external');
    
    $self->{loaded} = 1;
}

sub exec_components {
    my ($self, %options) = @_;
    
    my $mod_name = $self->{components_path} . "::sensor";
    my $func = $mod_name->can('check');
    $func->($self, component => $self->{option_results}->{component}, type => 'external'); 
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});
    
    return $self;
}

1;

__END__

=head1 MODE

Check external sensors.

=over 8

=item B<--component>

Which component to check (default: '.*').

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=airPressure --filter=rmsVoltage).
You can also exclude items from specific instances: --filter=rmsVoltage,I1

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='powerQuality,CRITICAL,^(?!(normal)$)'

=item B<--warning>

Set warning threshold for temperatures (syntax: type,instance,threshold)
Example: --warning='powerQuality,.*,30'

=item B<--critical>

Set critical threshold for temperatures (syntax: type,instance,threshold)
Example: --critical='powerQuality,.*,40'

=back

=cut
