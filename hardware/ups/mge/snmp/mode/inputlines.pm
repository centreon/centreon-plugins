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

package hardware::ups::mge::snmp::mode::inputlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = "Input Line(s) bad status is '" . $self->{result_values}->{badstatus} . "' [failcause = " . $self->{result_values}->{failcause} . "]";
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{badstatus} = $options{new_datas}->{$self->{instance} . '_badstatus'};
    $self->{result_values}->{failcause} = $options{new_datas}->{$self->{instance} . '_failcause'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'iline', type => 1, cb_prefix_output => 'prefix_iline_output', message_multiple => 'All input lines are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', set => {
                key_values => [ { name => 'badstatus' }, { name => 'failcause' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];

    $self->{maps_counters}->{iline} = [
        { label => 'current', set => {
                key_values => [ { name => 'mginputCurrent', no_value => 0 } ],
                output_template => 'Current : %.2f A',
                perfdatas => [
                    { label => 'current', value => 'mginputCurrent', template => '%.2f', 
                      min => 0, unit => 'A', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'voltage', set => {
                key_values => [ { name => 'mginputVoltage', no_value => 0 } ],
                output_template => 'Voltage : %.2f V',
                perfdatas => [
                    { label => 'voltage', value => 'mginputVoltage', template => '%.2f', 
                      unit => 'V', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'frequence', set => {
                key_values => [ { name => 'mginputFrequency', no_value => 0 } ],
                output_template => 'Frequence : %.2f Hz',
                perfdatas => [
                    { label => 'frequence', value => 'mginputFrequency', template => '%.2f', 
                      unit => 'Hz', label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "warning-status:s"    => { name => 'warning_status' },
        "critical-status:s"   => { name => 'critical_status', default => '%{badstatus} =~ /yes/' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_iline_output {
    my ($self, %options) = @_;

    return "Input Line '" . $options{instance_value}->{display} . "' ";
}

my %map_input_failcause = (
    1 => 'no',
    2 => 'outoftolvolt',
    3 => 'outoftolfreq',
    4 => 'utilityoff',
);
my %map_bad_status = (
    1 => 'yes',
    2 => 'no',
);

my $mapping = {
    mginputVoltage      => { oid => '.1.3.6.1.4.1.705.1.6.2.1.2' }, # in dV
    mginputFrequency    => { oid => '.1.3.6.1.4.1.705.1.6.2.1.3' }, # in dHz
    mginputCurrent      => { oid => '.1.3.6.1.4.1.705.1.6.2.1.6' }, # in dA
};
my $oid_upsmgInput = '.1.3.6.1.4.1.705.1.6';
my $oid_upsmgInputPhaseEntry = '.1.3.6.1.4.1.705.1.6.2.1';
my $oid_upsmgInputPhaseNum = '.1.3.6.1.4.1.705.1.6.1.0';
my $oid_upsmgInputBadStatus = '.1.3.6.1.4.1.705.1.6.3.0';
my $oid_upsmgInputLineFailCause = '.1.3.6.1.4.1.705.1.6.4.0';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{iline} = {};
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_upsmgInput,
        nothing_quit => 1
    );
    
    if (!defined($snmp_result->{$oid_upsmgInputPhaseNum}) || 
        $snmp_result->{$oid_upsmgInputPhaseNum} == 0) {
        $self->{output}->add_option_msg(short_msg => "No input lines found.");
        $self->{output}->option_exit();
    }
    
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$oid_upsmgInputPhaseEntry\.\d+\.(.*)$/);
        my $instance = $1;
        next if (defined($self->{iline}->{$instance}));
        
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        $result->{mginputVoltage} *= 0.1 if (defined($result->{mginputVoltage}));
        $result->{mginputFrequency} *= 0.1 if (defined($result->{mginputFrequency}));
        $result->{mginputCurrent} *= 0.1 if (defined($result->{mginputCurrent}));
        next if ((!defined($result->{mginputVoltage}) || $result->{mginputVoltage} == 0) &&
                (!defined($result->{mginputFrequency}) || $result->{mginputFrequency} == 0) &&
                (!defined($result->{mginputCurrent}) || $result->{mginputCurrent} == 0));
        $self->{iline}->{$instance} = { display => $instance, %$result };
    }
    
    $self->{global} = {
        badstatus => $map_bad_status{$snmp_result->{$oid_upsmgInputBadStatus}},
        failcause => $map_input_failcause{$snmp_result->{$oid_upsmgInputLineFailCause}},
    };
}

1;

__END__

=head1 MODE

Check Input lines metrics (frequence, voltage, current).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'frequence', 'voltage', 'current'.

=item B<--critical-*>

Threshold critical.
Can be: 'frequence', 'voltage', 'current'.

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{badstatus}, %{failcause}

=item B<--critical-status>

Set critical threshold for status (Default: '%{badstatus} =~ /yes/').
Can used special variables like: %{badstatus}, %{failcause}

=back

=cut
