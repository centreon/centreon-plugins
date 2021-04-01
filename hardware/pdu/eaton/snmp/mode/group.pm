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

package hardware::pdu::eaton::snmp::mode::group;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'group', type => 1, cb_prefix_output => 'prefix_group_output', message_multiple => 'All groups are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{group} = [
        { label => 'current', nlabel => 'group.current.ampere', set => {
                key_values => [ { name => 'groupCurrent', no_value => 0 }, { name => 'display' } ],
                output_template => 'Current : %.2f A',
                perfdatas => [
                    { value => 'groupCurrent', template => '%.2f', 
                      min => 0, unit => 'A', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'voltage', nlabel => 'group.voltage.volt', set => {
                key_values => [ { name => 'groupVoltage', no_value => 0 }, { name => 'display' } ],
                output_template => 'Voltage : %.2f V',
                perfdatas => [
                    { value => 'groupVoltage', template => '%.2f', 
                      unit => 'V', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'power', nlabel => 'group.power.watt', set => {
                key_values => [ { name => 'groupWatts', no_value => 0 }, { name => 'display' } ],
                output_template => 'Power : %.2f W',
                perfdatas => [
                    { value => 'groupWatts', template => '%.2f', 
                      unit => 'W', label_extra_instance => 1, instance_use => 'display' }
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
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub prefix_group_output {
    my ($self, %options) = @_;

    return "Group '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    groupName       => { oid => '.1.3.6.1.4.1.534.6.6.7.5.1.1.3' },
    groupVoltage    => { oid => '.1.3.6.1.4.1.534.6.6.7.5.3.1.3' }, # in mVolt 
    groupCurrent    => { oid => '.1.3.6.1.4.1.534.6.6.7.5.4.1.3' },  # in mA
    groupWatts      => { oid => '.1.3.6.1.4.1.534.6.6.7.5.5.1.3' }, # in Watt 
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping->{groupName}->{oid} },
            { oid => $mapping->{groupVoltage}->{oid} },
            { oid => $mapping->{groupCurrent}->{oid} },
            { oid => $mapping->{groupWatts}->{oid} },
        ],
        return_type => 1, nothing_quit => 1
    );

    $self->{group} = {};
    foreach my $oid (keys %{$snmp_result}) {
        $oid =~ /\.(\d+)\.(\d+)$/;
        my ($strapping_index, $group_index) = ($1, $2);
        next if (defined($self->{group}->{$strapping_index . '.' . $group_index}));

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $strapping_index . '.' . $group_index);
        $result->{groupVoltage} *= 0.001 if (defined($result->{groupVoltage}));
        $result->{groupCurrent} *= 0.001 if (defined($result->{groupCurrent}));
        my $display = $strapping_index . '.' . $group_index;
        if (defined($result->{groupName}) && $result->{groupName} ne '') {
            $display = $result->{groupName} . ' strapping ' . $strapping_index;
        }

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $display !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $display . "': no matching filter.", debug => 1);
            next;
        }

        $self->{group}->{$strapping_index . '.' . $group_index} = { display => $display, %$result };
    }

    if (scalar(keys %{$self->{group}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No group found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check group metrics (voltage, current and power).

=over 8

=item B<--filter-name>

Filter group name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'voltage', 'current', 'power'.

=item B<--critical-*>

Threshold critical.
Can be: 'voltage', 'current', 'power'.

=back

=cut
