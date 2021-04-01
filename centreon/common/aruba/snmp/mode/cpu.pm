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

package centreon::common::aruba::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All CPUs utilization are ok' },
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'utilization', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'sysExtProcessorLoad' }, { name => 'sysExtProcessorDescr' } ],
                output_template => 'Utilization %.2f%%',
                perfdatas => [
                    { label => 'utilization', value => 'sysExtProcessorLoad', template => '%.2f',  min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'sysExtProcessorDescr' },
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{sysExtProcessorDescr} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

my $oid_wlsxSysExtProcessorEntry = '.1.3.6.1.4.1.14823.2.2.1.2.1.13.1';

my $mapping = {
    sysExtProcessorDescr => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.13.1.2' },
    sysExtProcessorLoad => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.13.1.3' },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_wlsxSysExtProcessorEntry,
        start => $mapping->{sysExtProcessorDescr}->{oid},
        end => $mapping->{sysExtProcessorLoad}->{oid},
        nothing_quit => 1
    );
    
    $self->{cpu} = {};
    
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{sysExtProcessorDescr}->{oid}\.(.*)/);
        my $instance = $1;
        
        my $result = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result,
            instance => $instance
        );

        $self->{cpu}->{$instance} = { %{$result} };
    }

    if (scalar(keys %{$self->{cpu}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot find CPU informations");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check CPU usage (over the last minute) (WLSX-SYSTEMEXT-MIB).

=over 8

=item B<--warning-utilization>

Threshold warning in percent.

=item B<--critical-utilization>

Threshold critical in percent.

=back

=cut
    