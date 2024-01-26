#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::java::jvm::actuator::mode::cpuload;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'system', nlabel => 'system.cpu.load.percentage', set => {
                key_values => [ { name => 'system_load' } ],
                output_template => 'system cpu load: %.2f%%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'process', nlabel => 'process.cpu.load.percentage', set => {
                key_values => [ { name => 'process_load' } ],
                output_template => 'process cpu load: %.2f%%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
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

    my $result = $options{custom}->request_api(endpoint => '/metrics/system.cpu.usage');
    $self->{global} = { system_load => $result->{measurements}->[0]->{value} };

    $result = $options{custom}->request_api(endpoint => '/metrics/process.cpu.usage');
    $self->{global}->{process_load} = $result->{measurements}->[0]->{value};
}

1;

__END__

=head1 MODE

Check JVM SystemCpuLoad and ProcessCpuLoad (From 0 to 1 where 1 means 100% of CPU ressources are in use, here we * by 100 for convenience).
WARN : Probably not work for java -version < 7.

=over 8

=item B<--warning-system>

Warning threshold of System cpuload

=item B<--critical-system>

Critical threshold of System cpuload

=item B<--warning-process>

Warning threshold of Process cpuload

=item B<--critical-process>

Critical threshold of Process cpuload

=back

=cut
