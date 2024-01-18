#
# Copyright 2024 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and alarm monitoring for
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

package hardware::devices::hikvision::nvr::isapi::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'cpu-utilization', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_util' } ],
                output_template => 'Cpu utilization: %.2f%%',
                perfdatas => [
                    { template => '%s', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(endpoint => '/ISAPI/System/status');
    if (!defined($result->{CPUList}->{CPU}->{cpuUtilization})) {
        $self->{output}->add_option_msg(short_msg => "Cannot find cpu informations");
        $self->{output}->option_exit();
    }

    $self->{global} = { cpu_util => $result->{CPUList}->{CPU}->{cpuUtilization} };
};

1;

__END__

=head1 MODE

Check cpu.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization' (%).

=back
