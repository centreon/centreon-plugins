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

package hardware::pdu::emerson::snmp::mode::rbusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'rb', type => 1, cb_prefix_output => 'prefix_rb_output', message_multiple => 'All receptacle branches are ok' },
    ];

    $self->{maps_counters}->{rb} = [
        { label => 'energy', set => {
                key_values => [ { name => 'EnergyAccum', diff => 1 }, { name => 'display' } ],
                output_template => 'total energy : %.3f kWh', output_error_template => "total energy : %s",
                perfdatas => [
                    { label => 'energy', value => 'EnergyAccum_absolute', template => '%.3f',
                      unit => 'kWh', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'power-real-neutral', set => {
                key_values => [ { name => 'Pwr' }, { name => 'display' } ],
                output_template => 'line-to-neutral real power : %s W', output_error_template => "line-to-neutral real power : %s",
                perfdatas => [
                    { label => 'power_real_neutral', value => 'Pwr_absolute', template => '%s',
                      unit => 'W', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'power-apparent-neutral', set => {
                key_values => [ { name => 'Ap' }, { name => 'display' } ],
                output_template => 'line-to-neutral apparent power : %s VA', output_error_template => "line-to-neutral apparent power : %s",
                perfdatas => [
                    { label => 'power_apparent_neutral', value => 'Ap_absolute', template => '%s',
                      unit => 'VA', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'current-neutral', set => {
                key_values => [ { name => 'EcHundredths' }, { name => 'display' } ],
                output_template => 'line-to-neutral current : %s Amp AC RMS', output_error_template => "line-to-neutral current : %s",
                perfdatas => [
                    { label => 'current_neutral', value => 'EcHundredths_absolute', template => '%s',
                      unit => 'AmpAcRMS', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'potential-neutral', set => {
                key_values => [ { name => 'EpLNTenths' }, { name => 'display' } ],
                output_template => 'line-to-neutral potential : %s VoltRMS', output_error_template => "line-to-neutral potential : %s",
                perfdatas => [
                    { label => 'potential_neutral', value => 'EpLNTenths_absolute', template => '%s',
                      unit => 'VoltRMS', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub prefix_rb_output {
    my ($self, %options) = @_;
    
    return "Receptacle branch '" . $options{instance_value}->{display} . "' ";
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
    lgpPduRbEntryUsrLabel       => { oid => '.1.3.6.1.4.1.476.1.42.3.8.40.20.1.8' },
    lgpPduRbEntryEnergyAccum    => { oid => '.1.3.6.1.4.1.476.1.42.3.8.40.20.1.85' },  # 0.1 Kilowatt-Hour
    lgpPduRbEntryEpLNTenths     => { oid => '.1.3.6.1.4.1.476.1.42.3.8.40.20.1.100' }, # 0.1 VoltRMS
    lgpPduRbEntryPwr            => { oid => '.1.3.6.1.4.1.476.1.42.3.8.40.20.1.115' }, # Watt
    lgpPduRbEntryAp             => { oid => '.1.3.6.1.4.1.476.1.42.3.8.40.20.1.120' }, # VoltAmp
    lgpPduRbEntryEcHundredths   => { oid => '.1.3.6.1.4.1.476.1.42.3.8.40.20.1.130' }, # 0.01 Amp-AC-RMS
};
my $oid_lgpPduEntryUsrLabel = '.1.3.6.1.4.1.476.1.42.3.8.20.1.10';
my $oid_lgpPduRbEntry = '.1.3.6.1.4.1.476.1.42.3.8.40.20.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{cache_name} = "pdu_emerson_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    
    $self->{rb} = {};
    $self->{results} = $options{snmp}->get_multiple_table(oids => [ { oid => $oid_lgpPduEntryUsrLabel },
                                                                    { oid => $oid_lgpPduRbEntry },
                                                                  ],
                                                          nothing_quit => 1);
    foreach my $oid (keys %{$self->{results}->{$oid_lgpPduRbEntry}}) {
        next if ($oid !~ /^$mapping->{lgpPduRbEntryPwr}->{oid}\.(\d+)\.(\d+)/);
        my ($pdu_index, $rb_index) = ($1, $2);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_lgpPduRbEntry}, instance => $pdu_index . '.' . $rb_index);
        my $pdu_name = defined($self->{results}->{$oid_lgpPduEntryUsrLabel}->{$oid_lgpPduEntryUsrLabel . '.' . $pdu_index}) && $self->{results}->{$oid_lgpPduEntryUsrLabel}->{$oid_lgpPduEntryUsrLabel . '.' . $pdu_index} ne '' ? 
            $self->{results}->{$oid_lgpPduEntryUsrLabel}->{$oid_lgpPduEntryUsrLabel . '.' . $pdu_index} : $pdu_index;
        my $rb_name = defined($result->{lgpPduRbEntryUsrLabel}) && $result->{lgpPduRbEntryUsrLabel} ne '' ?
            $result->{lgpPduRbEntryUsrLabel} : $rb_index;
        my $name = $pdu_name . '/' . $rb_name;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{rb}->{$pdu_index . '.' . $rb_index} = { display => $name, 
                                                        EnergyAccum => $result->{lgpPduRbEntryEnergyAccum} * 0.1,
                                                        EpLNTenths => $result->{lgpPduRbEntryEpLNTenths} * 0.1,
                                                        Pwr => $result->{lgpPduRbEntryPwr},
                                                        Ap => $result->{lgpPduRbEntryAp},
                                                        EcHundredths =>  $result->{lgpPduRbEntryEcHundredths} * 0.01};
    }
    
    if (scalar(keys %{$self->{rb}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot found receptacle branches.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check receptacle branch usage.

=over 8

=item B<--filter-name>

Filter receptacle branch name (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(energy)$'

=item B<--warning-*>

Threshold warning.
Can be: 'energy', 'power-real-neutral', 'power-apparent-neutral',
'current-neutral', 'potential-neutral'.

=item B<--critical-*>

Threshold critical.
Can be: 'energy', 'power-real-neutral', 'power-apparent-neutral',
'current-neutral', 'potential-neutral'.

=back

=cut
