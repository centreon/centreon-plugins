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

package hardware::server::hp::proliant::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use centreon::plugins::misc;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature)$';

    $self->{cb_hook1} = 'get_system_information';
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        cpu => [
            ['unknown', 'UNKNOWN'],
            ['ok', 'OK'],
            ['degraded', 'WARNING'],
            ['failed', 'CRITICAL'],
            ['disabled', 'OK']
        ],
        ideldrive => [
            ['other', 'UNKNOWN'],
            ['ok', 'OK'],
            ['rebuilding', 'WARNING'],
            ['degraded', 'WARNING'],
            ['failed', 'CRITICAL']
        ],
        sasldrive => [
            ['other', 'UNKNOWN'],
            ['ok', 'OK'],
            ['degraded', 'WARNING'],
            ['rebuilding', 'WARNING'],
            ['failed', 'CRITICAL'],
            ['offline', 'CRITICAL']
        ],
        scsildrive => [
            ['other', 'UNKNOWN'],
            ['ok', 'OK'],
            ['degraded', 'WARNING'],
            ['failed', 'CRITICAL'],
            ['unconfigured', 'OK'],
            ['recovering', 'WARNING'],
            ['readyForRebuild', 'WARNING'],
            ['rebuilding', 'WARNING'],
            ['wrongDrive', 'CRITICAL'],
            ['badConnect', 'CRITICAL'],
            ['disabled', 'OK']
        ],
        fcaexternalaccbattery => [
            ['other', 'UNKNOWN'],
            ['ok', 'OK'],
            ['degraded', 'WARNING'],
            ['failed', 'CRITICAL'],
            ['recharging', 'WARNING'],
            ['not present', 'OK']
        ],
        fcaldrive => [
            ['other', 'UNKNOWN'],
            ['ok', 'OK'],
            ['failed', 'CRITICAL'],
            ['rebuilding', 'WARNING'],
            ['expanding', 'WARNING'],
            ['recovering', 'WARNING'],
            ['unconfigured', 'OK'],
            ['readyForRebuild', 'WARNING'],
            ['wrongDrive', 'CRITICAL'],
            ['badConnect', 'CRITICAL'],
            ['overheating', 'CRITICAL'],
            ['notAvailable', 'WARNING'],
            ['hardError', 'CRITICAL'],
            ['queuedForExpansion', 'WARNING'],
            ['shutdown', 'WARNING']
        ],
        daaccbattery => [
            ['other', 'UNKNOWN'],
            ['ok', 'OK'],
            ['degraded', 'WARNING'],
            ['failed', 'CRITICAL'],
            ['recharging', 'WARNING'],
            ['not present', 'OK']
        ],
        daldrive => [
            ['other', 'UNKNOWN'],
            ['ok', 'OK'],
            ['failed', 'CRITICAL'],
            ['rebuilding', 'WARNING'],
            ['expanding', 'WARNING'],
            ['recovering', 'WARNING'],
            ['unconfigured', 'OK'],
            ['readyForRebuild', 'WARNING'],
            ['wrongDrive', 'CRITICAL'],
            ['badConnect', 'CRITICAL'],
            ['overheating', 'CRITICAL'],
            ['notAvailable', 'WARNING'],
            ['hardError', 'CRITICAL'],
            ['queuedForExpansion', 'WARNING'],
            ['shutdown', 'WARNING']
        ],
        lnic => [
            ['other', 'OK'],
            ['ok', 'OK'],
            ['degraded', 'WARNING'],
            ['failed', 'CRITICAL']
        ],
        temperature => [
            ['other', 'OK'],
            ['ok', 'OK'],
            ['degraded', 'WARNING'],
            ['failed', 'CRITICAL']
        ],
        # ilo, pnic, fan, dapdrive, daacc, dactl, fcapdrive, fcaexternalacc, fcaexternalctl, fcahostctl, scsipdrive, scsictl, saspdrive, sasctl, psu, pc, idepdrive, idectl
        default => [
            ['other', 'UNKNOWN'],
            ['ok', 'OK'],
            ['degraded', 'WARNING'],
            ['failed', 'CRITICAL']
        ]
    };
    
    $self->{components_path} = 'hardware::server::hp::proliant::snmp::mode::components';
    $self->{components_module} = [
        'cpu', 'idectl', 'ideldrive', 'idepdrive', 'pc', 'psu',
        'sasctl', 'sasldrive', 'saspdrive', 'scsictl', 'scsildrive', 'scsipdrive',
        'fcahostctl', 'fcaexternalctl', 'fcaexternalacc', 'fcaldrive', 'fcapdrive',
        'dactl', 'daacc', 'daldrive', 'dapdrive', 'fan', 'pnic', 'lnic', 'temperature', 'ilo'
    ];
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
 
    if ($self->{option_results}->{component} =~ /storage/i) {
        $self->{option_results}->{component} = '^(sas|ide|fca|da|scsi).*';
    }
    if ($self->{option_results}->{component} =~ /network/i) {
        $self->{option_results}->{component} = '^(pnic|lnic)$';
    }
}

sub get_system_information {
    my ($self, %options) = @_;
    
    # In 'CPQSINFO-MIB'
    my $oid_cpqSiSysSerialNum = ".1.3.6.1.4.1.232.2.2.2.1.0";
    my $oid_cpqSiProductName = ".1.3.6.1.4.1.232.2.2.4.2.0";
    my $oid_cpqSeSysRomVer = ".1.3.6.1.4.1.232.1.2.6.1.0";
    
    my $result = $options{snmp}->get_leef(oids => [$oid_cpqSiSysSerialNum, $oid_cpqSiProductName, $oid_cpqSeSysRomVer]);
    
    my $product_name = defined($result->{$oid_cpqSiProductName}) ? centreon::plugins::misc::trim($result->{$oid_cpqSiProductName}) : 'unknown';
    my $serial = defined($result->{$oid_cpqSiSysSerialNum}) ? centreon::plugins::misc::trim($result->{$oid_cpqSiSysSerialNum}) : 'unknown';
    my $romversion = defined($result->{$oid_cpqSeSysRomVer}) ? centreon::plugins::misc::trim($result->{$oid_cpqSeSysRomVer}) : 'unknown';
    $self->{output}->output_add(long_msg => sprintf("Product Name: %s, Serial: %s, Rom Version: %s", 
                                                    $product_name, $serial, $romversion)
                                 );
}

1;

__END__

=head1 MODE

Check Hardware (CPUs, Power Supplies, Power converters, Fans).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'cpu', 'psu', 'pc', 'fan', 'temperature', 'lnic', 'pnic',...
There are some magic words like: 'network', 'storage'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fan --filter=temperature)
Can also exclude specific instance: --filter=fan,1.2 --filter=lnic,1

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping
Can be specific or global: --absent-problem=fan,1.2

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='temperature,CRITICAL,^(?!(ok)$)'

=item B<--warning>

Set warning threshold for temperatures (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for temperatures (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,40'

=back

=cut
