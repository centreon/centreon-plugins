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

package hardware::ups::hp::snmp::mode::inputlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'iline', type => 1, cb_prefix_output => 'prefix_iline_output', message_multiple => 'All input lines are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'frequence', nlabel => 'lines.input.frequence.hertz', set => {
                key_values => [ { name => 'upsInputFrequency', no_value => 0 } ],
                output_template => 'frequence: %.2f Hz',
                perfdatas => [
                    { value => 'upsInputFrequency', template => '%.2f', 
                      unit => 'Hz' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{iline} = [
        { label => 'current', nlabel => 'line.input.current.ampere', set => {
                key_values => [ { name => 'upsInputCurrent', no_value => 0 } ],
                output_template => 'current: %.2f A',
                perfdatas => [
                    { value => 'upsInputCurrent', template => '%.2f', 
                      min => 0, unit => 'A', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'voltage', nlabel => 'line.input.voltage.volt', set => {
                key_values => [ { name => 'upsInputVoltage', no_value => 0 } ],
                output_template => 'voltage: %s V',
                perfdatas => [
                    { value => 'upsInputVoltage', template => '%s', 
                      unit => 'V', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'power', nlabel => 'line.input.power.watt', set => {
                key_values => [ { name => 'upsInputWatts', no_value => 0 } ],
                output_template => 'power: %s W',
                perfdatas => [
                    { value => 'upsInputWatts', template => '%s', 
                      unit => 'W', label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub prefix_iline_output {
    my ($self, %options) = @_;

    return "Input Line '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    upsInputVoltage   => { oid => '.1.3.6.1.4.1.232.165.3.3.4.1.2' }, # in V
    upsInputCurrent   => { oid => '.1.3.6.1.4.1.232.165.3.3.4.1.3' }, # in A
    upsInputWatts     => { oid => '.1.3.6.1.4.1.232.165.3.3.4.1.4' }, # in W
};
my $mapping2 = {
    upsInputFrequency => { oid => '.1.3.6.1.4.1.232.165.3.3.1' }, # in dHZ
};
my $mapping3 = {
    upsConfigLowOutputVoltageLimit  => { oid => '.1.3.6.1.4.1.232.165.3.9.6' },
    upsConfigHighOutputVoltageLimit => { oid => '.1.3.6.1.4.1.232.165.3.9.7' },
};

my $oid_upsInputEntry = '.1.3.6.1.4.1.232.165.3.3.4.1';
my $oid_upsConfig = '.1.3.6.1.4.1.232.165.3.9';

sub manage_selection {
    my ($self, %options) = @_;
 
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping2->{upsInputFrequency}->{oid} },
            { oid => $oid_upsInputEntry },
            { oid => $oid_upsConfig, start => $mapping3->{upsConfigLowOutputVoltageLimit}->{oid}, end => $mapping3->{upsConfigHighOutputVoltageLimit}->{oid} },
        ],
        return_type => 1,
        nothing_quit => 1
    );

    $self->{iline} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$oid_upsInputEntry\.\d+\.(.*)$/);
        my $instance = $1;
        next if (defined($self->{iline}->{$instance}));

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        $result->{upsInputCurrent} = 0 if (defined($result->{upsInputCurrent}) && $result->{upsInputCurrent} eq '');
        $self->{iline}->{$instance} = { display => $instance, %$result };
    }
    
    if (scalar(keys %{$self->{iline}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No input lines found.");
        $self->{output}->option_exit();
    }

    my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => '0');
    $result->{upsInputFrequency} = defined($result->{upsInputFrequency}) ? ($result->{upsInputFrequency} * 0.1) : 0;
    $self->{global} = { %$result };

    $result = $options{snmp}->map_instance(mapping => $mapping3, results => $snmp_result, instance => '0');
    if ((!defined($self->{option_results}->{'warning-instance-line-input-voltage-volt'}) || $self->{option_results}->{'warning-instance-line-input-voltage-volt'} eq '') &&
        (!defined($self->{option_results}->{'critical-instance-line-input-voltage-volt'}) || $self->{option_results}->{'critical-instance-line-input-voltage-volt'} eq '')
    ) {
        my $th = '';
        $th .= $result->{upsConfigHighOutputVoltageLimit} if (defined($result->{upsConfigHighOutputVoltageLimit}) && $result->{upsConfigHighOutputVoltageLimit} =~ /\d+/);
        $th = $result->{upsConfigLowOutputVoltageLimit} . ':' . $th if (defined($result->{upsConfigLowOutputVoltageLimit}) && $result->{upsConfigLowOutputVoltageLimit} =~ /\d+/);
        $self->{perfdata}->threshold_validate(label => 'critical-instance-line-input-voltage-volt', value => $th) if ($th ne '');
    }
}

1;

__END__

=head1 MODE

Check input lines metrics.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'frequence', 'voltage', 'current', 'power'.

=back

=cut
