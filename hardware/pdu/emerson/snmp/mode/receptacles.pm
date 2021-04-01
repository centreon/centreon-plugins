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

package hardware::pdu::emerson::snmp::mode::receptacles;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);
use Digest::MD5 qw(md5_hex);

sub custom_rcp_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        "operational state '%s' [power state: %s]",
        $self->{result_values}->{oper_state},
        $self->{result_values}->{power_state}
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
         { name => 'rb', type => 3, cb_prefix_output => 'prefix_rb_output', cb_long_output => 'rb_long_output', indent_long_output => '    ', message_multiple => 'All receptacle branches are ok', 
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'rcp', display_long => 1, cb_prefix_output => 'prefix_rcp_output',  message_multiple => 'All receptacles are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-accumulated-energy', nlabel => 'receptaclebranch.total.accumulated.energy.kilowatthour', set => {
                key_values => [ { name => 'lgpPduRbEntryEnergyAccum', diff => 1 } ],
                output_template => 'total input power : %s kWh',
                perfdatas => [
                    { template => '%s', value => 'lgpPduRbEntryEnergyAccum',
                      unit => 'kWh', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'line2neutral-real-power', nlabel => 'receptaclebranch.line2neutral.real.power.watt', set => {
                key_values => [ { name => 'lgpPduRbEntryPwr' } ],
                output_template => 'line-to-neutral real power : %s W',
                perfdatas => [
                    { template => '%s', value => 'lgpPduRbEntryPwr',
                      unit => 'W', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'line2neutral-apparent-power', nlabel => 'receptaclebranch.line2neutral.apparent.power.voltampere', set => {
                key_values => [ { name => 'lgpPduRbEntryAp' } ],
                output_template => 'line-to-neutral apparent power : %s VA',
                perfdatas => [
                    { template => '%s', value => 'lgpPduRbEntryAp',
                      unit => 'VA', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'current-neutral', nlabel => 'receptaclebranch.line2neutral.current.ampacrms', set => {
                key_values => [ { name => 'lgpPduRbEntryEcHundredths' } ],
                output_template => 'line-to-neutral current : %s Amp AC RMS',
                perfdatas => [
                    { value => 'lgpPduRbEntryEcHundredths', template => '%s',
                      unit => 'AmpAcRMS', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'potential-neutral', nlabel => 'receptaclebranch.line2neutral.potential.voltrms', set => {
                key_values => [ { name => 'lgpPduRbEntryEpLNTenths' } ],
                output_template => 'line-to-neutral potential : %s VoltRMS',
                perfdatas => [
                    { value => 'lgpPduRbEntryEpLNTenths', template => '%s',
                      unit => 'VoltRMS', min => 0, label_extra_instance => 1 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{rcp} = [
        { label => 'rcp-status',  threshold => 0, set => {
                key_values => [ { name => 'oper_state' }, { name => 'power_state' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_rcp_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_rb_output {
    my ($self, %options) = @_;

    return "Receptacle branch '" . $options{instance_value}->{display} . "' : ";
}

sub rb_long_output {
    my ($self, %options) = @_;

    return "checking receptacle branch '" . $options{instance_value}->{display} . "'";
}

sub prefix_rcp_output {
    my ($self, %options) = @_;

    return "receptacle '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-rb:s'           => { name => 'filter_rb' },
        'unknown-rcp-status:s'  => { name => 'unknown_rcp_status', default => '' },
        'warning-rcp-status:s'  => { name => 'warning_rcp_status', default => '%{oper_state} =~ /warning|alarm/' },
        'critical-rcp-status:s' => { name => 'critical_rcp_status', default => '%{oper_state} =~ /abnormal/' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['unknown_rcp_status', 'warning_rcp_status', 'critical_rcp_status']);
}

my $rcp_power_state = { 0 => 'unknown', 1 => 'off', 2 => 'on', 3 => 'off-pending-on-delay' };
my $rcp_oper = { 1 => 'normal', 2 => 'warning', 3 => 'alarm', 4 => 'abnormal' };

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        lgpPduEntryUsrLabel       =>  { oid => '.1.3.6.1.4.1.476.1.42.3.8.20.1.10' },
        lgpPduEntrySysAssignLabel =>  { oid => '.1.3.6.1.4.1.476.1.42.3.8.20.1.15' },
    };
    my $mapping2 = {
        lgpPduRbEntryUsrLabel       => { oid => '.1.3.6.1.4.1.476.1.42.3.8.40.20.1.8' },
        lgpPduRbEntrySysAssignLabel => { oid => '.1.3.6.1.4.1.476.1.42.3.8.40.20.1.20' },
        lgpPduRbEntryEnergyAccum    => { oid => '.1.3.6.1.4.1.476.1.42.3.8.40.20.1.85' }, # 0.1 Kilowatt-Hour
        lgpPduRbEntryEpLNTenths     => { oid => '.1.3.6.1.4.1.476.1.42.3.8.40.20.1.100' },
        lgpPduRbEntryPwr            => { oid => '.1.3.6.1.4.1.476.1.42.3.8.40.20.1.115' }, # Watt
        lgpPduRbEntryAp             => { oid => '.1.3.6.1.4.1.476.1.42.3.8.40.20.1.120' }, # VA
        lgpPduRbEntryEcHundredths   => { oid => '.1.3.6.1.4.1.476.1.42.3.8.40.20.1.130' },
    };
    my $mapping3 = {
        lgpPduRcpEntryUsrLabel           => { oid => '.1.3.6.1.4.1.476.1.42.3.8.50.20.1.10' },
        lgpPduRcpEntrySysAssignLabel     => { oid => '.1.3.6.1.4.1.476.1.42.3.8.50.20.1.25' },
        lgpPduRcpEntryPwrState           => { oid => '.1.3.6.1.4.1.476.1.42.3.8.50.20.1.95', map => $rcp_power_state },
        lgpPduRcpEntryOperationCondition => { oid => '.1.3.6.1.4.1.476.1.42.3.8.50.20.1.210', map => $rcp_oper },
    };

    my $oid_lgpPduEntry = '.1.3.6.1.4.1.476.1.42.3.8.20.1';
    my $oid_lgpPduRbEntry = '.1.3.6.1.4.1.476.1.42.3.8.40.20.1';
    my $oid_lgpPduRcpEntry = '.1.3.6.1.4.1.476.1.42.3.8.50.20.1';
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_lgpPduEntry, start => $mapping->{lgpPduEntryUsrLabel}->{oid}, end => $mapping->{lgpPduEntrySysAssignLabel}->{oid} },
            { oid => $oid_lgpPduRbEntry, start => $mapping2->{lgpPduRbEntryUsrLabel}->{oid}, end => $mapping2->{lgpPduRbEntryEcHundredths}->{oid} },
            { oid => $oid_lgpPduRcpEntry, start => $mapping3->{lgpPduRcpEntryUsrLabel}->{oid}, end => $mapping3->{lgpPduRcpEntryOperationCondition}->{oid} },
        ],
        nothing_quit => 1,
    );

    $self->{rb} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_lgpPduRbEntry}}) {
        next if ($oid !~ /^$mapping2->{lgpPduRbEntrySysAssignLabel}->{oid}\.(.*?)\.(.*)$/);
        my ($pdu_index, $rb_index) = ($1, $2);

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_lgpPduEntry}, instance => $pdu_index);
        my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_lgpPduRbEntry}, instance => $pdu_index . '.' . $rb_index);

        my $name = (defined($result->{lgpPduEntryUsrLabel}) && $result->{lgpPduEntryUsrLabel} ne '' ? $result->{lgpPduEntryUsrLabel} : $result->{lgpPduEntrySysAssignLabel});
        $name .= '~' . (defined($result2->{lgpPduRbEntryUsrLabel}) && $result2->{lgpPduRbEntryUsrLabel} ne '' ? $result2->{lgpPduRbEntryUsrLabel} : $result2->{lgpPduRbEntrySysAssignLabel});

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping receptacle branch '" . $name . "'.", debug => 1);
            next;
        }

        $result2->{lgpPduRbEntryEnergyAccum} /= 10;
        $result2->{lgpPduRbEntryEcHundredths} *= 0.01 if (defined($result2->{lgpPduRbEntryEcHundredths}));
        $result2->{lgpPduRbEntryEpLNTenths} *= 0.1 if (defined($result2->{lgpPduRbEntryEpLNTenths}));
        $self->{rb}->{$name} = {
            display => $name,
            global => { %$result2 },
            rcp => {},
        };

        foreach (keys %{$snmp_result->{$oid_lgpPduRcpEntry}}) {
            next if (!/^$mapping3->{lgpPduRcpEntrySysAssignLabel}->{oid}\.$pdu_index\.$rb_index\.(.*)$/);
            my $rcp_index = $1;
            my $result3 = $options{snmp}->map_instance(mapping => $mapping3, results => $snmp_result->{$oid_lgpPduRcpEntry}, instance => $pdu_index . '.' . $rb_index . '.' . $rcp_index);
            
            my $rcp_name = (defined($result3->{lgpPduRcpEntryUsrLabel}) && $result3->{lgpPduRcpEntryUsrLabel} ne '' ? $result3->{lgpPduRcpEntryUsrLabel} : $result3->{lgpPduRcpEntrySysAssignLabel});
            $self->{rb}->{$name}->{rcp}->{$rcp_name} = {
                display => $rcp_name,
                power_state => $result3->{lgpPduRcpEntryPwrState},
                oper_state => $result3->{lgpPduRcpEntryOperationCondition},
            };
        }
    }

    if (scalar(keys %{$self->{rb}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No receptacle branch found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = "pdu_liebert_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_rb}) ? md5_hex($self->{option_results}->{filter_rb}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check receptacles.

=over 8

=item B<--filter-rb>

Filter receptable branch name (can be a regexp).

=item B<--unknown-rcp-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{oper_state}, %{power_state}, %{display}

=item B<--warning-rcp-status>

Set warning threshold for status (Default: '%{oper_state} =~ /warning|alarm/').
Can used special variables like: %{oper_state}, %{power_state}, %{display}

=item B<--critical-rcp-status>

Set critical threshold for status (Default: '%{oper_state} =~ /abnormal/').
Can used special variables like: %{oper_state}, %{power_state}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-accumulated-energy', 'line2neutral-real-power', 'line2neutral-apparent-power'.

=back

=cut
