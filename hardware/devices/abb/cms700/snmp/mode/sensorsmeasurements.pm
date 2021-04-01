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

package hardware::devices::abb::cms700::snmp::mode::sensorsmeasurements;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_output {
    my ($self, %options) = @_;

    my $output = sprintf("Sensor '%s' [Group: %s] [Phase: %s] ",
        $options{instance_value}->{display},
        $options{instance_value}->{Groupsens},
        $options{instance_value}->{Phasesens}
    );

    return $output;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'sensors', type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All sensors are ok', skipped_code => { -10 => 1 } },
    ];
        
    $self->{maps_counters}->{sensors} = [
        { label => 'current-mixte', nlabel => 'sensor.current.mixte.ampere', set => {
                key_values => [ { name => 'TRMSsens' }, { name => 'display' } ],
                output_template => 'Mixte Current: %.2f A',
                perfdatas => [
                    { value => 'TRMSsens', template => '%.2f', unit => 'A', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'current-alternative', nlabel => 'sensor.current.alternative.ampere', set => {
                key_values => [ { name => 'ACsens' }, { name => 'display' } ],
                output_template => 'Alternative Current: %.2f A',
                perfdatas => [
                    { value => 'ACsens', template => '%.2f', unit => 'A', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'current-direct', nlabel => 'sensor.current.direct.ampere', set => {
                key_values => [ { name => 'DCsens' }, { name => 'display' } ],
                output_template => 'Direct Current: %.2f A',
                perfdatas => [
                    { value => 'DCsens', template => '%.2f', unit => 'A', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'power-active', nlabel => 'sensor.power.active.watt', set => {
                key_values => [ { name => 'Psens' }, { name => 'display' } ],
                output_template => 'Active Power: %.2f W',
                perfdatas => [
                    { value => 'Psens', template => '%.2f', unit => 'W', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'energy-active', nlabel => 'sensor.energy.active.watthours', set => {
                key_values => [ { name => 'Whsens' }, { name => 'display' } ],
                output_template => 'Active Energy: %.2f Wh',
                perfdatas => [
                    { value => 'Whsens', template => '%.2f', unit => 'Wh', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'power-factor', nlabel => 'sensor.power.factor.ratio', set => {
                key_values => [ { name => 'PowerFactorsens' }, { name => 'display' } ],
                output_template => 'Power Factor: %.2f',
                perfdatas => [
                    { value => 'PowerFactorsens', template => '%.2f', min => 0, max => 1,
                      label_extra_instance => 1, instance_use => 'display' },
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
        "filter-name:s"     => { name => 'filter_name' },
        "filter-group:s"    => { name => 'filter_group' },
        "filter-phase:s"    => { name => 'filter_phase' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

my $oid_GroupName = '.1.3.6.1.4.1.51055.1.20';
my $oid_BranchNamesens = '.1.3.6.1.4.1.51055.1.19';

my $mapping = {
    TRMSsens        => { oid => '.1.3.6.1.4.1.51055.1.1' },
    ACsens          => { oid => '.1.3.6.1.4.1.51055.1.2' },
    DCsens          => { oid => '.1.3.6.1.4.1.51055.1.3' },
    POLsens         => { oid => '.1.3.6.1.4.1.51055.1.14' },
    Psens           => { oid => '.1.3.6.1.4.1.51055.1.15' },
    Whsens          => { oid => '.1.3.6.1.4.1.51055.1.16' },
    Phasesens       => { oid => '.1.3.6.1.4.1.51055.1.21' },
    Groupsens       => { oid => '.1.3.6.1.4.1.51055.1.22' },
    PowerFactorsens => { oid => '.1.3.6.1.4.1.51055.1.23' },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my %groups;
    my $snmp_result = $options{snmp}->get_table(oid => $oid_GroupName);
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$oid_GroupName\.(.*)/);
        next if ($snmp_result->{$oid} eq '');
        $groups{$1} = $snmp_result->{$oid};
    }

    my %sensors;
    $snmp_result = $options{snmp}->get_table(oid => $oid_BranchNamesens);
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$oid_BranchNamesens\.(.*)/);
        next if ($snmp_result->{$oid} eq '');
        my $instance = $1;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping sensor '" . $snmp_result->{$oid} . "'.", debug => 1);
            next;
        }

        $sensors{$instance} = $snmp_result->{$oid};
    }

    $options{snmp}->load(
        oids => [
            $mapping->{TRMSsens}->{oid},
            $mapping->{ACsens}->{oid},
            $mapping->{DCsens}->{oid},
            $mapping->{POLsens}->{oid},
            $mapping->{Psens}->{oid},
            $mapping->{Whsens}->{oid},
            $mapping->{Phasesens}->{oid},
            $mapping->{Groupsens}->{oid},
            $mapping->{PowerFactorsens}->{oid},
        ],
        instances => [ keys %sensors ],
        instance_regexp => '^(.*)$'
    );
    my $snmp_result_data = $options{snmp}->get_leef(nothing_quit => 1);
    
    $self->{sensors} = {};
    foreach my $oid (keys %$snmp_result_data) {
        next if ($oid !~ /^$mapping->{TRMSsens}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result_data,
            instance => $instance
        );

        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '' &&
            (!defined($groups{$result->{Groupsens}}) ||
            ($groups{$result->{Groupsens}} !~ /$self->{option_results}->{filter_group}/))) {
            $self->{output}->output_add(long_msg => "skipping sensor '" . $sensors{$instance} . "'.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_phase}) && $self->{option_results}->{filter_phase} ne '' &&
            $result->{Phasesens} !~ /$self->{option_results}->{filter_phase}/) {
            $self->{output}->output_add(long_msg => "skipping sensor '" . $sensors{$instance} . "'.", debug => 1);
            next;
        }

        $self->{sensors}->{$instance}->{display} = $sensors{$instance};
        $self->{sensors}->{$instance}->{TRMSsens} = $result->{TRMSsens} / 100;
        $self->{sensors}->{$instance}->{ACsens} = $result->{ACsens} / 100;
        $self->{sensors}->{$instance}->{DCsens} = $result->{DCsens} / 100;
        $self->{sensors}->{$instance}->{POLsens} = $result->{POLsens};
        $self->{sensors}->{$instance}->{Psens} = $result->{Psens};
        $self->{sensors}->{$instance}->{Whsens} = $result->{Whsens} / 10;
        $self->{sensors}->{$instance}->{PowerFactorsens} = $result->{PowerFactorsens} / 100;

        $self->{sensors}->{$instance}->{Phasesens} = $result->{Phasesens};
        $self->{sensors}->{$instance}->{Groupsens} =
            (defined($groups{$result->{Groupsens}})) ? $groups{$result->{Groupsens}} : '-';
    }
    
    if (scalar(keys %{$self->{sensors}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No sensors found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check sensors measurements.

=over 8

=item B<--filter-name>

Filter by sensor name (can be a regexp).

=item B<--filter-group>

Filter by sensor group name (can be a regexp).

=item B<--filter-phase>

Filter by sensor phase (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^current$'

=item B<--warning-*> B<--critical-*>

Threshold warning.
Can be: 'current-mixte', 'current-alternative', 'current-direct',
'power-active', 'energy-active', 'power-factor'.

=back

=cut
