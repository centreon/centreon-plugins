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

package hardware::pdu::emerson::snmp::mode::psusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'ps', type => 1, cb_prefix_output => 'prefix_ps_output', message_multiple => 'All power sources are ok' },
    ];

    $self->{maps_counters}->{ps} = [
        { label => 'power', set => {
                key_values => [ { name => 'PwrTotal' }, { name => 'display' } ],
                output_template => 'total input power : %s W', output_error_template => "total input power : %s",
                perfdatas => [
                    { label => 'power', value => 'PwrTotal_absolute', template => '%s',
                      unit => 'W', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'energy', set => {
                key_values => [ { name => 'EnergyAccum', diff => 1 }, { name => 'display' } ],
                output_template => 'Total energy : %.3f kWh', output_error_template => "Total energy : %s",
                perfdatas => [
                    { label => 'energy', value => 'EnergyAccum_absolute', template => '%.3f',
                      unit => 'kWh', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'current-neutral', set => {
                key_values => [ { name => 'EcNeutral' }, { name => 'display' } ],
                output_template => 'Current neutral : %s Amp AC RMS', output_error_template => "Current neutral : %s",
                perfdatas => [
                    { label => 'current_neutral', value => 'EcNeutral_absolute', template => '%s',
                      unit => 'AmpAcRMS', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub prefix_ps_output {
    my ($self, %options) = @_;
    
    return "Power source '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "filter-name:s"           => { name => 'filter_name' },
                                });
    
    return $self;
}

my $mapping = {
    lgpPduPsEntrySysAssignLabel     => { oid => '.1.3.6.1.4.1.476.1.42.3.8.30.20.1.15' },
    lgpPduPsEntryEnergyAccum        => { oid => '.1.3.6.1.4.1.476.1.42.3.8.30.20.1.50' }, # 0.1 Kilowatt-Hour
    lgpPduPsEntryPwrTotal           => { oid => '.1.3.6.1.4.1.476.1.42.3.8.30.20.1.65' }, # Watt
    lgpPduPsEntryEcNeutral          => { oid => '.1.3.6.1.4.1.476.1.42.3.8.30.20.1.70' }, # 0.1 Amp-AC-RMS
};
my $oid_lgpPduEntryUsrLabel = '.1.3.6.1.4.1.476.1.42.3.8.20.1.10';
my $oid_lgpPduPsEntry = '.1.3.6.1.4.1.476.1.42.3.8.30.20.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{cache_name} = "pdu_emerson_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    
    $self->{ps} = {};
    $self->{results} = $options{snmp}->get_multiple_table(oids => [ { oid => $oid_lgpPduEntryUsrLabel },
                                                                    { oid => $oid_lgpPduPsEntry },
                                                                  ],
                                                          nothing_quit => 1);
    foreach my $oid (keys %{$self->{results}->{$oid_lgpPduPsEntry}}) {
        next if ($oid !~ /^$mapping->{lgpPduPsEntryPwrTotal}->{oid}\.(\d+)\.(\d+)/);
        my ($pdu_index, $ps_index) = ($1, $2);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_lgpPduPsEntry}, instance => $pdu_index . '.' . $ps_index);
        my $pdu_name = defined($self->{results}->{$oid_lgpPduEntryUsrLabel}->{$oid_lgpPduEntryUsrLabel . '.' . $pdu_index}) && $self->{results}->{$oid_lgpPduEntryUsrLabel}->{$oid_lgpPduEntryUsrLabel . '.' . $pdu_index} ne '' ? 
            $self->{results}->{$oid_lgpPduEntryUsrLabel}->{$oid_lgpPduEntryUsrLabel . '.' . $pdu_index} : $pdu_index;
        my $ps_name = defined($result->{lgpPduPsEntrySysAssignLabel}) && $result->{lgpPduPsEntrySysAssignLabel} ne '' ?
            $result->{lgpPduPsEntrySysAssignLabel} : $ps_index;
        my $name = $pdu_name . '/' . $ps_name;
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{ps}->{$pdu_index . '.' . $ps_index} = { display => $name, 
                                                        EnergyAccum => $result->{lgpPduPsEntryEnergyAccum} * 0.1, 
                                                        PwrTotal => $result->{lgpPduPsEntryPwrTotal},
                                                        EcNeutral =>  $result->{lgpPduPsEntryEcNeutral} * 0.1};
    }
    
    if (scalar(keys %{$self->{ps}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot found power sources.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check power source usage.

=over 8

=item B<--filter-name>

Filter power source name (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(power|energy)$'

=item B<--warning-*>

Threshold warning.
Can be: 'power', 'energy', 'current-neutral'.

=item B<--critical-*>

Threshold critical.
Can be: 'power', 'energy', 'current-neutral'.

=back

=cut
