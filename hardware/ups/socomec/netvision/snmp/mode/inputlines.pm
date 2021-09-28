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

package hardware::ups::socomec::netvision::snmp::mode::inputlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_iline_output {
    my ($self, %options) = @_;

    return "Input line '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'iline', type => 1, cb_prefix_output => 'prefix_iline_output', message_multiple => 'All input lines are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'frequence', nlabel => 'lines.input.frequence.hertz', set => {
                key_values => [ { name => 'frequency', no_value => 0 } ],
                output_template => 'frequence: %.2f Hz',
                perfdatas => [
                    { template => '%.2f', unit => 'Hz' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{iline} = [
        { label => 'current', nlabel => 'line.input.current.ampere', set => {
                key_values => [ { name => 'current', no_value => 0 } ],
                output_template => 'current: %.2f A',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'A', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'voltage', nlabel => 'line.input.voltage.volt', set => {
                key_values => [ { name => 'voltage', no_value => 0 } ],
                output_template => 'voltage: %.2f V',
                perfdatas => [
                    { template => '%.2f', unit => 'V', label_extra_instance => 1 }
                ]
            }
        }
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

my $mapping = {
    voltage   => { oid => '.1.3.6.1.4.1.4555.1.1.7.1.3.3.1.2' }, # upsInputVoltage (dV)
    current   => { oid => '.1.3.6.1.4.1.4555.1.1.7.1.3.3.1.3' }  # upsInputCurrent (dA)
};
my $mapping2 = {
    frequency => { oid => '.1.3.6.1.4.1.4555.1.1.7.1.3.2' } # upsInputFrequency (dHZ)
};

my $oid_upsInput = '.1.3.6.1.4.1.4555.1.1.7.1.3';
my $oid_upsInputEntry = '.1.3.6.1.4.1.4555.1.1.7.1.3.3.1';

sub manage_selection {
    my ($self, %options) = @_;
 
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_upsInput,
        start => $mapping2->{frequency}->{oid},
        end => $mapping->{current}->{oid},
        nothing_quit => 1
    );

    $self->{iline} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$oid_upsInputEntry\.\d+\.(.*)$/);
        my $instance = $1;
        next if (defined($self->{iline}->{$instance}));

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        foreach (('current', 'voltage')) {
            $result->{$_} = 0 if (defined($result->{$_}) && (
                $result->{$_} eq '' || $result->{$_} == -1 || $result->{$_} == 65535 || $result->{$_} == 655350));
            $result->{$_} *= 0.1;
        }

        $self->{iline}->{$instance} = {
            display => $instance,
            %$result
        };
    }
    
    if (scalar(keys %{$self->{iline}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No input lines found.");
        $self->{output}->option_exit();
    }

    $self->{global} = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => 0);
    $self->{global}->{frequency} = defined($self->{global}->{frequency}) && $self->{global}->{frequency} != -1 && $self->{global}->{frequency} != 65535
        ? ($self->{global}->{frequency} * 0.1) : 0;
}

1;

__END__

=head1 MODE

Check Input lines metrics (frequence, voltage, current).

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'frequence', 'voltage', 'current'.

=back

=cut
