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

package hardware::devices::abb::cms700::snmp::mode::mainsmeasurements;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_output {
    my ($self, %options) = @_;

    return "Phase '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_init => 'skip_global' },
        { name => 'phases', type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All mains phases are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'power-active-total', nlabel => 'power.active.watt', set => {
                key_values => [ { name => 'p3' } ],
                output_template => 'Active Power: %.2f W',
                perfdatas => [
                    { value => 'p3', template => '%.2f', unit => 'W', min => 0 },
                ],
            }
        },
        { label => 'power-reactive-total', nlabel => 'power.reactive.voltamperereactive', set => {
                key_values => [ { name => 'q3' } ],
                output_template => 'Reactive Power: %.2f VAR',
                perfdatas => [
                    { value => 'q3', template => '%.2f', unit => 'VAR', min => 0 },
                ],
            }
        },
        { label => 'power-apparent-total', nlabel => 'power.apparent.voltampere', set => {
                key_values => [ { name => 's3' } ],
                output_template => 'Apparent Power: %.2f VA',
                perfdatas => [
                    { value => 's3', template => '%.2f', unit => 'VA', min => 0 },
                ],
            }
        },
    ];
        
    $self->{maps_counters}->{phases} = [
        { label => 'voltage', nlabel => 'phase.voltage.volt', set => {
                key_values => [ { name => 'uL' }, { name => 'display' } ],
                output_template => 'Voltage: %.2f V',
                perfdatas => [
                    { value => 'uL', template => '%.2f', unit => 'V', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'current', nlabel => 'phase.current.ampere', set => {
                key_values => [ { name => 'iL' }, { name => 'display' } ],
                output_template => 'Current: %.2f A',
                perfdatas => [
                    { value => 'iL', template => '%.2f', unit => 'A', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'power-factor', nlabel => 'phase.power.factor.ratio', set => {
                key_values => [ { name => 'pfL' }, { name => 'display' } ],
                output_template => 'Power Factor: %.2f',
                perfdatas => [
                    { value => 'pfL', template => '%.2f', min => 0, max => 1,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'cosphi', nlabel => 'phase.cosphi.ratio', set => {
                key_values => [ { name => 'cosP' }, { name => 'display' } ],
                output_template => 'Cos Phi: %.2f',
                perfdatas => [
                    { value => 'cosP', template => '%.2f', min => 0, max => 1,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'power-active', nlabel => 'phase.power.active.watt', set => {
                key_values => [ { name => 'pL' }, { name => 'display' } ],
                output_template => 'Active Power: %.2f W',
                perfdatas => [
                    { value => 'pL', template => '%.2f', unit => 'W', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'power-reactive', nlabel => 'phase.power.reactive.voltamperereactive', set => {
                key_values => [ { name => 'qL' }, { name => 'display' } ],
                output_template => 'Reactive Power: %.2f VAR',
                perfdatas => [
                    { value => 'qL', template => '%.2f', unit => 'VAR', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'power-apparent', nlabel => 'phase.power.apparent.voltampere', set => {
                key_values => [ { name => 'sL' }, { name => 'display' } ],
                output_template => 'Apparent Power: %.2f VA',
                perfdatas => [
                    { value => 'sL', template => '%.2f', unit => 'VA', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'energy-active', nlabel => 'phase.energy.active.watthours', set => {
                key_values => [ { name => 'whL' }, { name => 'display' } ],
                output_template => 'Active Energy: %.2f Wh',
                perfdatas => [
                    { value => 'whL', template => '%.2f', unit => 'Wh', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'energy-reactive', nlabel => 'phase.energy.reactive.voltamperereactivehours', set => {
                key_values => [ { name => 'qhL' }, { name => 'display' } ],
                output_template => 'Reactive Energy: %.2f VARh',
                perfdatas => [
                    { value => 'qhL', template => '%.2f', unit => 'VARh', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'energy-apparent', nlabel => 'phase.energy.apparent.voltamperehours', set => {
                key_values => [ { name => 'shL' }, { name => 'display' } ],
                output_template => 'Apparent Energy: %.2f VAh',
                perfdatas => [
                    { value => 'shL', template => '%.2f', unit => 'VAh', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'voltage-thd', nlabel => 'phase.voltage.thd.percentage', set => {
                key_values => [ { name => 'thdUL' }, { name => 'display' } ],
                output_template => 'Voltage THD: %.2f %%',
                perfdatas => [
                    { value => 'thdUL', template => '%.2f', unit => '%', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'current-thd', nlabel => 'phase.current.thd.percentage', set => {
                key_values => [ { name => 'thdIL' }, { name => 'display' } ],
                output_template => 'Current THD: %.2f %%',
                perfdatas => [
                    { value => 'thdIL', template => '%.2f', unit => '%', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub skip_global {
    my ($self, %options) = @_;

    scalar(keys %{$self->{phases}}) > 1 ? return(0) : return(1);
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-phase:s" => { name => 'filter_phase' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

my $mapping = {
    uL      => { oid => '.1.3.6.1.4.1.51055.1.24' }, # PHASE VOLTAGE (0.01V)
    iL      => { oid => '.1.3.6.1.4.1.51055.1.25' }, # LINE CURRENT (0.01A)
    pfL     => { oid => '.1.3.6.1.4.1.51055.1.26' }, # POWER FACTOR (0.01)
    cosP    => { oid => '.1.3.6.1.4.1.51055.1.27' }, # COSPHI
    sL      => { oid => '.1.3.6.1.4.1.51055.1.29' }, # APPARENT POWER (VA)
    pL      => { oid => '.1.3.6.1.4.1.51055.1.31' }, # ACTIVE POWER (W)
    qL      => { oid => '.1.3.6.1.4.1.51055.1.33' }, # REACTIVE POWER (VAr)
    whL     => { oid => '.1.3.6.1.4.1.51055.1.36' }, # ACTIVE ENERGY (0.01Wh)
    qhL     => { oid => '.1.3.6.1.4.1.51055.1.37' }, # REACTIVE ENERGY (0.01Varh)
    thdUL   => { oid => '.1.3.6.1.4.1.51055.1.38' }, # VOLTAGE THD (%)
    thdIL   => { oid => '.1.3.6.1.4.1.51055.1.39' }, # CURRENT THD (%)
    shL     => { oid => '.1.3.6.1.4.1.51055.1.41' }, # APPARENT ENERGY (0.01Vah)
};
my $oid_main = '.1.3.6.1.4.1.51055.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_main, start => $mapping->{uL}->{oid}, end => $mapping->{shL}->{oid},
    );

    $self->{global} = { s3 => 0, p3 => 0, q3 => 0 };
    $self->{phases} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{uL}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_phase}) && $self->{option_results}->{filter_phase} ne '' &&
            $instance !~ /$self->{option_results}->{filter_phase}/) {
            $self->{output}->output_add(long_msg => "skipping sensor '" . $snmp_result->{$oid} . "'.", debug => 1);
            next;
        }

        $self->{phases}->{$instance}->{display} = 'L' . $instance;
        $self->{phases}->{$instance}->{uL} = $result->{uL} / 100;
        $self->{phases}->{$instance}->{iL} = $result->{iL} / 100;
        $self->{phases}->{$instance}->{pfL} = $result->{pfL} / 100;
        $self->{phases}->{$instance}->{cosP} = $result->{cosP};
        $self->{phases}->{$instance}->{sL} = $result->{sL};
        $self->{phases}->{$instance}->{pL} = $result->{pL};
        $self->{phases}->{$instance}->{qL} = $result->{qL};
        $self->{phases}->{$instance}->{shL} = $result->{shL} / 100;
        $self->{phases}->{$instance}->{whL} = $result->{whL} / 100;
        $self->{phases}->{$instance}->{qhL} = $result->{qhL} / 100;
        $self->{phases}->{$instance}->{thdUL} = $result->{thdUL} / 100;
        $self->{phases}->{$instance}->{thdIL} = $result->{thdIL} / 100;

        $self->{global}->{s3} += $result->{sL};
        $self->{global}->{p3} += $result->{pL};
        $self->{global}->{q3} += $result->{qL};
    }

    if (scalar(keys %{$self->{phases}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No phases found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check mains phases measurements.

=over 8

=item B<--filter-phase>

Filter by phase (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^power|energy$'

=item B<--warning-*> B<--critical-*>

Threshold warning.
Can be: 'power-apparent-total', 'power-active-total', 'power-reactive-total',
'voltage', 'current', 'power-factor', 'cosphi', 'power-apparent',
'power-active', 'power-reactive', 'energy-apparent', 'energy-active',
'energy-reactive', 'voltage-thd', 'current-thd'.

=back

=cut
