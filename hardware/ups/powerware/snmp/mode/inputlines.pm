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

package hardware::ups::powerware::snmp::mode::inputlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'iline', type => 1, cb_prefix_output => 'prefix_iline_output', message_multiple => 'All input lines are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'frequence', nlabel => 'lines.input.frequence.hertz', set => {
                key_values => [ { name => 'xupsInputFrequency', no_value => 0 } ],
                output_template => 'frequence: %.2f Hz',
                perfdatas => [
                    { template => '%.2f', unit => 'Hz' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{iline} = [
        { label => 'current', nlabel => 'line.input.current.ampere', set => {
                key_values => [ { name => 'xupsInputCurrent', no_value => 0 } ],
                output_template => 'current: %.2f A',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'A', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'voltage', nlabel => 'line.input.voltage.volt', set => {
                key_values => [ { name => 'xupsInputVoltage', no_value => 0 } ],
                output_template => 'voltage: %.2f V',
                perfdatas => [
                    { template => '%.2f', unit => 'V', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'power', nlabel => 'line.input.power.watt', set => {
                key_values => [ { name => 'xupsInputWatts', no_value => 0 } ],
                output_template => 'power: %.2f W',
                perfdatas => [
                    { template => '%.2f', unit => 'W', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-iline:s' => { name => 'filter_iline' }
    });

    return $self;
}

sub prefix_iline_output {
    my ($self, %options) = @_;

    return "Input Line '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    xupsInputVoltage   => { oid => '.1.3.6.1.4.1.534.1.3.4.1.2' }, # in V
    xupsInputCurrent   => { oid => '.1.3.6.1.4.1.534.1.3.4.1.3' }, # in A
    xupsInputWatts     => { oid => '.1.3.6.1.4.1.534.1.3.4.1.4' }  # in W
};
my $mapping2 = {
    xupsInputFrequency => { oid => '.1.3.6.1.4.1.534.1.3.1' } # in dHZ
};
my $mapping3 = {
    upsConfigLowVoltageTransferPoint  => { oid => '.1.3.6.1.2.1.33.1.9.9' },
    upsConfigHighVoltageTransferPoint => { oid => '.1.3.6.1.2.1.33.1.9.10' }
};

my $oid_xupsInputEntry = '.1.3.6.1.4.1.534.1.3.4.1';
my $oid_upsConfig = '.1.3.6.1.2.1.33.1.9';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping2->{xupsInputFrequency}->{oid} },
            { oid => $oid_xupsInputEntry },
            { oid => $oid_upsConfig, start => $mapping3->{upsConfigLowVoltageTransferPoint}->{oid}, end => $mapping3->{upsConfigHighVoltageTransferPoint}->{oid} },
        ],
        return_type => 1,
        nothing_quit => 1
    );

    $self->{iline} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$oid_xupsInputEntry\.\d+\.(.*)$/);
        my $instance = $1;

        if (defined($self->{option_results}->{filter_iline}) && $self->{option_results}->{filter_iline} ne '' &&
            $instance !~ /$self->{option_results}->{filter_iline}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $instance . "': no matching 'iline' filter.", debug => 1);
            next;
        }

        next if (defined($self->{iline}->{$instance}));

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        $result->{xupsInputCurrent} = 0 if (defined($result->{xupsInputCurrent}) && $result->{xupsInputCurrent} eq '');
        $self->{iline}->{$instance} = { display => $instance, %$result };
    }
    
    if (scalar(keys %{$self->{iline}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No input lines found.");
        $self->{output}->option_exit();
    }

    my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => '0');

    $result->{xupsInputFrequency} = defined($result->{xupsInputFrequency}) ? ($result->{xupsInputFrequency} * 0.1) : 0;
    $self->{global} = { %$result };

    $result = $options{snmp}->map_instance(mapping => $mapping3, results => $snmp_result, instance => '0');
    if ((!defined($self->{option_results}->{'warning-voltage'}) || $self->{option_results}->{'warning-voltage'} eq '') &&
        (!defined($self->{option_results}->{'critical-voltage'}) || $self->{option_results}->{'critical-voltage'} eq '')
    ) {
        my $th = '';
        $th .= $result->{upsConfigHighVoltageTransferPoint} if (defined($result->{upsConfigHighVoltageTransferPoint}) && $result->{upsConfigHighVoltageTransferPoint} =~ /\d+/);
        $th = $result->{upsConfigLowVoltageTransferPoint} . ':' . $th if (defined($result->{upsConfigLowVoltageTransferPoint}) && $result->{upsConfigLowVoltageTransferPoint} =~ /\d+/);
        $self->{perfdata}->threshold_validate(label => 'critical-voltage', value => $th) if ($th ne '');
    }
}

1;

__END__

=head1 MODE

Check input lines metrics (frequence, voltage, current and true power) (XUPS-MIB).

=over 8

=item B<--filter-iline>

Filter input lines that match the regexp

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'frequence', 'voltage', 'current', 'power'.

=back

=cut
