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

package hardware::pdu::emerson::snmp::mode::psusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'ps', type => 3, cb_prefix_output => 'prefix_ps_output', cb_long_output => 'ps_long_output', indent_long_output => '    ', message_multiple => 'All power sources are ok', 
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'line', display_long => 1, cb_prefix_output => 'prefix_line_output',  message_multiple => 'All power source lines are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'power', nlabel => 'powersource.total.input.power.watt', set => {
                key_values => [ { name => 'PwrTotal' } ],
                output_template => 'Total input power : %s W', output_error_template => "total input power : %s",
                perfdatas => [
                    { label => 'power', value => 'PwrTotal', template => '%s',
                      unit => 'W', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'energy', nlabel => 'powersource.total.accumulated.energy.kilowatthour', set => {
                key_values => [ { name => 'EnergyAccum', diff => 1 } ],
                output_template => 'Total energy : %.3f kWh', output_error_template => "Total energy : %s",
                perfdatas => [
                    { label => 'energy', value => 'EnergyAccum', template => '%.3f',
                      unit => 'kWh', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'current-neutral', nlabel => 'powersource.neutral.current.ampacrms', set => {
                key_values => [ { name => 'EcNeutral' } ],
                output_template => 'Current neutral : %s Amp AC RMS', output_error_template => "Current neutral : %s",
                perfdatas => [
                    { label => 'current_neutral', value => 'EcNeutral', template => '%s',
                      unit => 'AmpAcRMS', min => 0, label_extra_instance => 1 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{line} = [
        { label => 'line-load', nlabel => 'line.load.percentage', set => {
                key_values => [ { name => 'load' } ],
                output_template => 'Load : %.2f %%', output_error_template => "Load : %s",
                perfdatas => [
                    { label => 'line_load', value => 'load', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'line-current', nlabel => 'line.neutral.current.ampere', set => {
                key_values => [ { name => 'current' }],
                output_template => 'Current : %.2f A', output_error_template => "Current : %s",
                perfdatas => [
                    { label => 'line_current', value => 'current', template => '%.2f',
                      unit => 'A', min => 0, label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub prefix_ps_output {
    my ($self, %options) = @_;
    
    return "Power source '" . $options{instance_value}->{display} . "' ";
}

sub ps_long_output {
    my ($self, %options) = @_;

    return "checking power source '" . $options{instance_value}->{display} . "'";
}

sub prefix_line_output {
    my ($self, %options) = @_;
    
    return "Power source line '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
    });
    
    return $self;
}

my %map_phase = (1 => 'phase1', 2 => 'phase2', 3 => 'phase3');

my $mapping = {
    lgpPduEntryUsrLabel       =>  { oid => '.1.3.6.1.4.1.476.1.42.3.8.20.1.10' },
    lgpPduEntrySysAssignLabel =>  { oid => '.1.3.6.1.4.1.476.1.42.3.8.20.1.15' },
};
my $mapping2 = {
    lgpPduPsEntrySysAssignLabel     => { oid => '.1.3.6.1.4.1.476.1.42.3.8.30.20.1.15' },
    lgpPduPsEntryEnergyAccum        => { oid => '.1.3.6.1.4.1.476.1.42.3.8.30.20.1.50' }, # 0.1 Kilowatt-Hour
    lgpPduPsEntryPwrTotal           => { oid => '.1.3.6.1.4.1.476.1.42.3.8.30.20.1.65' }, # Watt
    lgpPduPsEntryEcNeutral          => { oid => '.1.3.6.1.4.1.476.1.42.3.8.30.20.1.70' }, # 0.1 Amp-AC-RMS
};
my $mapping3 = {
    lgpPduPsLineEntryLine               => { oid => '.1.3.6.1.4.1.476.1.42.3.8.30.40.1.15', map => \%map_phase },
    lgpPduPsLineEntryEcHundredths       => { oid => '.1.3.6.1.4.1.476.1.42.3.8.30.40.1.22' }, # 0.01 A
    lgpPduPsLineEntryEcUsedBeforeAlarm  => { oid => '.1.3.6.1.4.1.476.1.42.3.8.30.40.1.39' }, # %
};
my $oid_lgpPduEntry = '.1.3.6.1.4.1.476.1.42.3.8.20.1';
my $oid_lgpPduPsEntry = '.1.3.6.1.4.1.476.1.42.3.8.30.20.1';
my $oid_lgpPduPsLineEntry = '.1.3.6.1.4.1.476.1.42.3.8.30.40.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{cache_name} = "pdu_emerson_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    
    $self->{ps} = {};
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_lgpPduEntry, start => $mapping->{lgpPduEntryUsrLabel}->{oid}, end => $mapping->{lgpPduEntrySysAssignLabel}->{oid} },
            { oid => $oid_lgpPduPsEntry, start => $mapping2->{lgpPduPsEntrySysAssignLabel}->{oid}, end => $mapping2->{lgpPduPsEntryEcNeutral}->{oid} },
            { oid => $oid_lgpPduPsLineEntry, start => $mapping3->{lgpPduPsLineEntryLine}->{oid}, end => $mapping3->{lgpPduPsLineEntryEcUsedBeforeAlarm}->{oid} },
        ],
        nothing_quit => 1
    );
    foreach my $oid (keys %{$snmp_result->{$oid_lgpPduPsEntry}}) {
        next if ($oid !~ /^$mapping2->{lgpPduPsEntrySysAssignLabel}->{oid}\.(\d+)\.(\d+)/);
        my ($pdu_index, $ps_index) = ($1, $2);

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_lgpPduEntry}, instance => $pdu_index);
        my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_lgpPduPsEntry}, instance => $pdu_index . '.' . $ps_index);

        my $name = (defined($result->{lgpPduEntryUsrLabel}) && $result->{lgpPduEntryUsrLabel} ne '' ? $result->{lgpPduEntryUsrLabel} : $result->{lgpPduEntrySysAssignLabel});
        $name .= '~' . $result2->{lgpPduPsEntrySysAssignLabel};

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{ps}->{$name} = {
            display => $name,
            global => {
                display => $name,
                EnergyAccum => $result2->{lgpPduPsEntryEnergyAccum} * 0.1, 
                PwrTotal => $result2->{lgpPduPsEntryPwrTotal},
                EcNeutral => defined($result2->{lgpPduPsEntryEcNeutral}) ? $result2->{lgpPduPsEntryEcNeutral} * 0.1 : undef,
            },
            line => {},
        };

         foreach my $oid (keys %{$snmp_result->{$oid_lgpPduPsLineEntry}}) {
            next if ($oid !~ /^$mapping3->{lgpPduPsLineEntryEcUsedBeforeAlarm}->{oid}\.$pdu_index\.$ps_index\.(\d+)/);
            my $line_index = $1;
            my $result3 = $options{snmp}->map_instance(mapping => $mapping3, results => $snmp_result->{$oid_lgpPduPsLineEntry}, instance => $pdu_index . '.' . $ps_index . '.' . $line_index);

            $self->{ps}->{$name}->{line}->{$result3->{lgpPduPsLineEntryLine}} = { 
                display => $result3->{lgpPduPsLineEntryLine}, 
                current => defined($result3->{lgpPduPsLineEntryEcHundredths}) ? $result3->{lgpPduPsLineEntryEcHundredths} * 0.01 : undef, 
                load => $result3->{lgpPduPsLineEntryEcUsedBeforeAlarm},
            };
        }
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
Can be: 'power', 'energy', 'current-neutral',
'line-load', 'line-current'.

=item B<--critical-*>

Threshold critical.
Can be: 'power', 'energy', 'current-neutral',
'line-load', 'line-current'.

=back

=cut
