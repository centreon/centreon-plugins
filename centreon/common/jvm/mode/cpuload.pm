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

package centreon::common::jvm::mode::cpuload;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "warning-system:s"  => { name => 'warning_system' },
                                  "critical-system:s" => { name => 'critical_system' },
                                  "warning-process:s" => { name => 'warning_process' },
                                  "critical-process:s" => { name => 'critical_process' }
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning-system', value => $self->{option_results}->{warning_system})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-system threshold '" . $self->{option_results}->{warning_system} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-system', value => $self->{option_results}->{critical_system})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-system threshold '" . $self->{option_results}->{critical_system} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-process', value => $self->{option_results}->{warning_process})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-process threshold '" . $self->{option_results}->{warning_process} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-process', value => $self->{option_results}->{critical_process})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-process threshold '" . $self->{option_results}->{critical_process} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{connector} = $options{custom};

    $self->{request} = [
         { mbean => "java.lang:type=OperatingSystem", attributes => [ { name => 'SystemCpuLoad' }, { name => 'ProcessCpuLoad' } ] }
    ];

    my $result = $self->{connector}->get_attributes(request => $self->{request}, nothing_quit => 1);
    my $exit = $self->{perfdata}->threshold_check(value => $result->{"java.lang:type=OperatingSystem"}->{SystemCpuLoad} * 100,
                                                  threshold => [ { label => 'critical-system', exit_litteral => 'critical' }, { label => 'warning-system', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("SystemCpuLoad: %.2f%%",
                                                      $result->{"java.lang:type=OperatingSystem"}->{SystemCpuLoad} * 100));

    $exit = $self->{perfdata}->threshold_check(value => $result->{"java.lang:type=OperatingSystem"}->{ProcessCpuLoad} * 100,
                                               threshold => [ { label => 'critical-process', exit_litteral => 'critical' }, { label => 'warning-process', exit_litteral => 'warning'} ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("ProcessCpuLoad: %.2f%%",
                                                      $result->{"java.lang:type=OperatingSystem"}->{ProcessCpuLoad} * 100));

    $self->{output}->perfdata_add(label => 'SystemCpuLoad', unit => '%',
                                  value => sprintf("%.2f", $result->{"java.lang:type=OperatingSystem"}->{SystemCpuLoad} * 100),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-system'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-system'),
                                  min => 0, max => 100);

    $self->{output}->perfdata_add(label => 'ProcessCpuLoad', unit => '%',
                                  value => sprintf("%.2f", $result->{"java.lang:type=OperatingSystem"}->{ProcessCpuLoad} * 100),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-process'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-process'),
                                  min => 0, max => 100);

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check JVM SystemCpuLoad and ProcessCpuLoad (From 0 to 1 where 1 means 100% of CPU ressources are in use, here we * by 100 for convenience).
WARN : Probably not work for java -version < 7.

Example:
perl centreon_plugins.pl --plugin=apps::tomcat::jmx::plugin --custommode=jolokia --url=http://10.30.2.22:8080/jolokia --mode=cpu-load --warning-system 50 --critical-system 75 --warning-process 60 --critical-process 80

=over 8

=item B<--warning-system>

Threshold warning of System cpuload

=item B<--critical-system>

Threshold critical of System cpuload

=item B<--warning-process>

Threshold warning of Process cpuload

=item B<--critical-process>

Threshold critical of Process cpuload

=back

=cut

