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

package hardware::ups::hp::snmp::mode::outputlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_source_output {
    my ($self, %options) = @_;
    
    return sprintf("output source is '%s'", $self->{result_values}->{source});
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'oline', type => 1, cb_prefix_output => 'prefix_oline_output', message_multiple => 'All output lines are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'source', threshold => 0, set => {
                key_values => [ { name => 'source' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_source_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'load', nlabel => 'lines.output.load.percentage', set => {
                key_values => [ { name => 'upsOutputLoad', no_value => -1 } ],
                output_template => 'load: %.2f %%',
                perfdatas => [
                    { value => 'upsOutputLoad', template => '%.2f', min => 0, max => 100 },
                ],
            }
        },
        { label => 'frequence', nlabel => 'lines.output.frequence.hertz', set => {
                key_values => [ { name => 'upsOutputFrequency', no_value => 0 } ],
                output_template => 'frequence: %.2f Hz',
                perfdatas => [
                    { value => 'upsOutputFrequency', template => '%.2f', unit => 'Hz' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{oline} = [
        { label => 'current', nlabel => 'line.output.current.ampere', set => {
                key_values => [ { name => 'upsOutputCurrent', no_value => 0 } ],
                output_template => 'current: %.2f A',
                perfdatas => [
                    { value => 'upsOutputCurrent', template => '%.2f', 
                      min => 0, unit => 'A', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'voltage', nlabel => 'line.output.voltage.volt', set => {
                key_values => [ { name => 'upsOutputVoltage', no_value => 0 } ],
                output_template => 'voltage: %s V',
                perfdatas => [
                    { value => 'upsOutputVoltage', template => '%s', 
                      unit => 'V', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'power', nlabel => 'line.output.power.watt', set => {
                key_values => [ { name => 'upsOutputWatts', no_value => 0 } ],
                output_template => 'power: %s W',
                perfdatas => [
                    { value => 'upsOutputWatts', template => '%s', 
                      unit => 'W', label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub prefix_oline_output {
    my ($self, %options) = @_;

    return "Output line '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'unknown-source:s'  => { name => 'unknown_source', default => '' },
        'warning-source:s'  => { name => 'warning_source', default => '' },
        'critical-source:s' => { name => 'critical_source', default => '%{source} !~ /normal/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_source', 'critical_source', 'unknown_source']);
}

my $map_source = {
    1 => 'other', 2 => 'none', 3 => 'normal',
    4 => 'bypass', 5 => 'battery', 6 => 'booster',
    7 => 'reducer', 8 => 'parallelCapacity', 
    9 => 'parallelRedundant', 10 => 'highEfficiencyMode', 
};

my $mapping = {
    upsOutputVoltage   => { oid => '.1.3.6.1.4.1.232.165.3.4.4.1.2' }, # in V
    upsOutputCurrent   => { oid => '.1.3.6.1.4.1.232.165.3.4.4.1.3' }, # in A
    upsOutputWatts     => { oid => '.1.3.6.1.4.1.232.165.3.4.4.1.4' }, # in W
};
my $mapping2 = {
    upsOutputLoad      => { oid => '.1.3.6.1.4.1.232.165.3.4.1' }, # in %
    upsOutputFrequency => { oid => '.1.3.6.1.4.1.232.165.3.4.2' }, # in dHZ
    upsOutputSource    => { oid => '.1.3.6.1.4.1.232.165.3.4.5', map => $map_source },
};

my $oid_upsOutput = '.1.3.6.1.4.1.232.165.3.4';
my $oid_upsOutputEntry = '.1.3.6.1.4.1.232.165.3.4.4.1';

sub manage_selection {
    my ($self, %options) = @_;
 
    $self->{oline} = {};
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_upsOutput,
        nothing_quit => 1
    );
    
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$oid_upsOutputEntry\.\d+\.(.*)$/);
        my $instance = $1;
        next if (defined($self->{oline}->{$instance}));
        
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        $self->{oline}->{$instance} = { display => $instance, %$result };
    }
    
    if (scalar(keys %{$self->{oline}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No output lines found.");
        $self->{output}->option_exit();
    }

    my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => '0');
    
    $result->{upsOutputFrequency} = defined($result->{upsOutputFrequency}) ? ($result->{upsOutputFrequency} * 0.1) : 0;
    $result->{upsOutputLoad} = defined($result->{upsOutputLoad}) ? $result->{upsOutputLoad} : -1;
    $result->{source} = $result->{upsOutputSource};

    $self->{global} = $result;
}

1;

__END__

=head1 MODE

Check output lines metrics.

=over 8

=item B<--unknown-source>

Set unknown threshold for status (Default: '').
Can used special variables like: %{source}.

=item B<--warning-source>

Set warning threshold for status (Default: '').
Can used special variables like: %{source}.

=item B<--critical-source>

Set critical threshold for status (Default: '%{source} !~ /normal/i').
Can used special variables like: %{source}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'load', 'voltage', 'current', 'power'.

=back

=cut
