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

package hardware::ups::apc::snmp::mode::inputlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Last input line fail cause is '%s'", $self->{result_values}->{last_cause});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{last_cause} = $options{new_datas}->{$self->{instance} . '_upsAdvInputLineFailCause'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
        
    $self->{maps_counters}->{global} = [
        { label => 'voltage', set => {
                key_values => [ { name => 'upsAdvInputLineVoltage' } ],
                output_template => 'Voltage : %s V',
                perfdatas => [
                    { label => 'voltage', value => 'upsAdvInputLineVoltage_absolute', template => '%s', 
                      unit => 'V' },
                ],
            }
        },
        { label => 'frequence', set => {
                key_values => [ { name => 'upsAdvInputFrequency' } ],
                output_template => 'Frequence : %s Hz',
                perfdatas => [
                    { label => 'frequence', value => 'upsAdvInputFrequency_absolute', template => '%s', 
                      unit => 'Hz' },
                ],
            }
        },
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'upsAdvInputLineFailCause' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        "warning-status:s"  => { name => 'warning_status', default => '' },
        "critical-status:s" => { name => 'critical_status', default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_status = (
    1 => 'noTransfer', 2 => 'highLineVoltage', 3 => 'brownout', 4 => 'blackout',
    5 => 'smallMomentarySag', 6 => 'deepMomentarySag', 7 => 'smallMomentarySpike',
    8 => 'largeMomentarySpike', 9 => 'selfTest', 10 => 'rateOfVoltageChange',
);

my $mapping = {
    upsAdvInputLineVoltage      => { oid => '.1.3.6.1.4.1.318.1.1.1.3.2.1' },
    upsAdvInputFrequency        => { oid => '.1.3.6.1.4.1.318.1.1.1.3.2.4' },
    upsAdvInputLineFailCause    => { oid => '.1.3.6.1.4.1.318.1.1.1.3.2.5', map => \%map_status },
};
my $oid_upsAdvInput = '.1.3.6.1.4.1.318.1.1.1.3.2';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_upsAdvInput,
                                                nothing_quit => 1);
                                                         
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');
    
    foreach my $name (keys %{$mapping}) {
        $self->{global}->{$name} = $result->{$name};
    }
}

1;

__END__

=head1 MODE

Check input lines.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^frequence|voltage$'

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{last_cause}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{last_cause}

=item B<--warning-*>

Threshold warning.
Can be: 'voltage', 'frequence'.

=item B<--critical-*>

Threshold critical.
Can be: 'voltage', 'frequence'.

=back

=cut
