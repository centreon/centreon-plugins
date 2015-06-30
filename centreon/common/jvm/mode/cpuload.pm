################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Simon Bomm <sbomm@centreon.com>
#
####################################################################################

package centreon::common::jvm::mode::cpuload;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
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
    # $options{snmp} = snmp object
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
                                  value => $result->{"java.lang:type=OperatingSystem"}->{SystemCpuLoad} * 100,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-system'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-system'),
                                  min => 0, max => 100);

    $self->{output}->perfdata_add(label => 'ProcessCpuLoad', unit => '%',
                                  value => $result->{"java.lang:type=OperatingSystem"}->{ProcessCpuLoad} * 100,
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

