#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::lenovo::flexsystem::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_message_output', message_multiple => 'All CPU usages are ok' },
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'average', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'average' }, { name => 'display' } ],
                output_template => '%.2f %%',
                perfdatas => [
                    { label => 'total_cpu_avg', value => 'average_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub prefix_message_output {
    my ($self, %options) = @_;

    return "Switch '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter:s' => { name => 'filter', default => '.*' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_mpCpuSwitchNumberRev = '.1.3.6.1.4.1.20301.2.5.1.2.2.12.1.1.1';
    my $oid_mpCpuStatsUtil1MinuteSwRev = '.1.3.6.1.4.1.20301.2.5.1.2.2.12.1.1.5';

    my $result = $options{snmp}->get_table(oid => $oid_mpCpuSwitchNumberRev, nothing_quit => 1);
    my @instance_oids = ();
    foreach my $oid (keys %$result) {
        if ($result->{$oid} =~ /$self->{option_results}->{filter}/i) {
            push @instance_oids, $oid;
        }
    }

    if (scalar(@instance_oids) == 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot find switch number '$self->{option_results}->{filter}'.");
        $self->{output}->option_exit();
    }

    $options{snmp}->load(
        oids => [$oid_mpCpuStatsUtil1MinuteSwRev],
        instances => \@instance_oids,
        instance_regexp => "^" . $oid_mpCpuSwitchNumberRev . '\.(.+)'
    );
    my $result2 = $options{snmp}->get_leef();

    foreach my $instance (@instance_oids) {
        $instance =~ /^$oid_mpCpuSwitchNumberRev\.(.+)/;
        $instance = $1;
        
        $self->{cpu}->{$instance} = {
            display => $result->{$oid_mpCpuSwitchNumberRev . '.' . $instance},
            average => $result2->{$oid_mpCpuStatsUtil1MinuteSwRev . '.' . $instance},
        };
    }
}

1;

__END__

=head1 MODE

Check CPU usage (over the last minute).

=over 8

=item B<--filter>

Filter switch number (Default: '.*').

=item B<--warning-average>

Warning threshold average CPU utilization. 

=item B<--critical-average>

Critical  threshold average CPU utilization. 

=back

=cut
