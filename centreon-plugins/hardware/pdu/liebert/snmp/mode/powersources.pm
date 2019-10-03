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

package hardware::pdu::liebert::snmp::mode::powersources;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'ps', type => 1, cb_prefix_output => 'prefix_ps_output', message_multiple => 'All power sources are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{ps} = [
        { label => 'total-accumulated-energy', nlabel => 'powersource.total.accumulated.energy.kilowatthour', set => {
                key_values => [ { name => 'lgpPduPsEntryEnergyAccum', diff => 1 }, { name => 'display' } ],
                output_template => 'total input power : %s kWh',
                perfdatas => [
                    { template => '%s', value => 'lgpPduPsEntryEnergyAccum_absolute',
                      unit => 'kWh', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'total-input-power', nlabel => 'powersource.total.input.power.watt', set => {
                key_values => [ { name => 'lgpPduPsEntryPwrTotal' }, { name => 'display' } ],
                output_template => 'total input power : %s W',
                perfdatas => [
                    { template => '%s', value => 'lgpPduPsEntryPwrTotal_absolute',
                      unit => 'W', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'total-apparent-power', nlabel => 'powersource.total.apparent.power.voltampere', set => {
                key_values => [ { name => 'lgpPduPsEntryApTotal' }, { name => 'display' } ],
                output_template => 'total apparent power : %s VA',
                perfdatas => [
                    { template => '%s', value => 'lgpPduPsEntryApTotal_absolute',
                      unit => 'VA', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        lgpPduEntryUsrLabel       =>  { oid => '.1.3.6.1.4.1.476.1.42.3.8.20.1.10' },
        lgpPduEntrySysAssignLabel =>  { oid => '.1.3.6.1.4.1.476.1.42.3.8.20.1.15' },
    };
    my $mapping2 = {
        lgpPduPsEntrySysAssignLabel => { oid => '.1.3.6.1.4.1.476.1.42.3.8.30.20.1.15' },
        lgpPduPsEntryEnergyAccum    => { oid => '.1.3.6.1.4.1.476.1.42.3.8.30.20.1.50' }, # 0.1 Kilowatt-Hour
        lgpPduPsEntryPwrTotal       => { oid => '.1.3.6.1.4.1.476.1.42.3.8.30.20.1.65' }, # Watt
        lgpPduPsEntryApTotal        => { oid => '.1.3.6.1.4.1.476.1.42.3.8.30.20.1.90' }, # VoltAmp
    };

    my $oid_lgpPduEntry = '.1.3.6.1.4.1.476.1.42.3.8.20.1';
    my $oid_lgpPduPsEntry = '.1.3.6.1.4.1.476.1.42.3.8.30.20.1';
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_lgpPduEntry, start => $mapping->{lgpPduEntryUsrLabel}->{oid}, end => $mapping->{lgpPduEntrySysAssignLabel}->{oid} },
            { oid => $oid_lgpPduPsEntry, start => $mapping2->{lgpPduPsEntrySysAssignLabel}->{oid}, end => $mapping2->{lgpPduPsEntryApTotal}->{oid} },
        ],
        nothing_quit => 1,
    );

    $self->{ps} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_lgpPduPsEntry}}) {
        next if ($oid !~ /^$mapping2->{lgpPduPsEntrySysAssignLabel}->{oid}\.(.*?)\.(.*)$/);
        my ($pdu_index, $ps_index) = ($1, $2);

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_lgpPduEntry}, instance => $pdu_index);
        my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_lgpPduPsEntry}, instance => $pdu_index . '.' . $ps_index);

        my $name = (defined($result->{lgpPduEntryUsrLabel}) && $result->{lgpPduEntryUsrLabel} ne '' ? $result->{lgpPduEntryUsrLabel} : $result->{lgpPduEntrySysAssignLabel});
        $name .= '~' . $result2->{lgpPduPsEntrySysAssignLabel};

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping power source '" . $name . "'.", debug => 1);
            next;
        }

        $result2->{lgpPduPsEntryEnergyAccum} /= 10;
        $self->{ps}->{$name} = {
            display => $name,
            %$result2
        };
    }
    
    if (scalar(keys %{$self->{ps}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No power source found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = "pdu_liebert_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check power sources

=over 8

=item B<--filter-name>

Filter power source name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-accumulated-energy', 'total-input-power', 'total-apparent-power'.

=back

=cut
