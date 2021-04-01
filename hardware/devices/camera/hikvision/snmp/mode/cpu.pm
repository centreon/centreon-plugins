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

package hardware::devices::camera::hikvision::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cpu', type => 0 }
    ];
    
    $self->{maps_counters}->{cpu} = [
        { label => 'usage', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'used' } ],
                output_template => 'CPU Usage: %.2f %%',
                perfdatas => [
                    { value => 'used', template => '%.2f', min => 0, max => 100, unit => '%' },
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
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_cpuPercent = '.1.3.6.1.4.1.39165.1.7.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [$oid_cpuPercent],
        nothing_quit => 1
    );

    if ($snmp_result->{$oid_cpuPercent} !~ /(\d+)/) {
        $self->{output}->add_option_msg(short_msg => 'cannot parse cpu usage: ' . $snmp_result->{$oid_cpuPercent});
        $self->{output}->option_exit();
    }
    my $prct_used = $1;

    $self->{cpu} = {
        used => $prct_used
    };
}

1;

__END__

=head1 MODE

Check cpu usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (%).

=back

=cut
