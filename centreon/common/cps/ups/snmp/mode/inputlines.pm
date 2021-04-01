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

package centreon::common::cps::ups::snmp::mode::inputlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("status is '%s'", $self->{result_values}->{status});
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'ilines', type => 0, cb_prefix_output => 'prefix_ilines_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{ilines} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'voltage', nlabel => 'lines.input.voltage.volt', set => {
                key_values => [ { name => 'voltage' } ],
                output_template => 'Voltage : %.2f V',
                perfdatas => [
                    { value => 'voltage', template => '%.2f', unit => 'V' },
                ],
            }
        },
        { label => 'frequence', nlabel => 'lines.input.frequence.hertz', set => {
                key_values => [ { name => 'frequence' } ],
                output_template => 'Frequence : %.2f Hz',
                perfdatas => [
                    { value => 'frequence', template => '%.2f', min => 0, unit => 'Hz' },
                ],
            }
        },
    ];
}

sub prefix_ilines_output {
    my ($self, %options) = @_;

    return 'Input ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'unknown-status:s'      => { name => 'unknown_status', default => '' },
        'warning-status:s'      => { name => 'warning_status', default => '' },
        'critical-status:s'     => { name => 'critical_status', default => '%{status} !~ /normal/' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

my $map_status = { 
    1 => 'normal', 2 => 'overVoltage',
    3 => 'underVoltage', 4 => 'frequencyFailure', 5 => 'blackout',
};

my $mapping = {
    upsAdvanceInputLineVoltage => { oid => '.1.3.6.1.4.1.3808.1.1.1.3.2.1' }, # in dV
    upsAdvanceInputFrequency   => { oid => '.1.3.6.1.4.1.3808.1.1.1.3.2.4' }, # in dHz
    upsAdvanceInputStatus      => { oid => '.1.3.6.1.4.1.3808.1.1.1.3.2.6', map => $map_status },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_upsAdvanceInput = '.1.3.6.1.4.1.3808.1.1.1.3.2';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_upsAdvanceInput, nothing_quit => 1);
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');

    $self->{ilines} = {
        frequence => (defined($result->{upsAdvanceInputFrequency}) && $result->{upsAdvanceInputFrequency} =~ /\d/) ? $result->{upsAdvanceInputFrequency} * 0.1 : undef,
        voltage => (defined($result->{upsAdvanceInputLineVoltage}) && $result->{upsAdvanceInputLineVoltage} =~ /\d/) ? $result->{upsAdvanceInputLineVoltage} * 0.1 : undef,
        status => $result->{upsAdvanceInputStatus},
    };
}

1;

__END__

=head1 MODE

Check INPUT lines metrics.

=over 8

=item B<--unknown-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /normal/').
Can used special variables like: %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'voltage', 'frequence'.

=back

=cut
