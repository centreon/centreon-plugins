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
# Authors : Simon BOMM <sbomm@centreon.com>
#
####################################################################################

package centreon::common::jvm::mode::classcount;

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
                                  "warning-loaded:s"    => { name => 'warning_loaded' },
                                  "critical-loaded:s"   => { name => 'critical_loaded' },
                                  "warning-total:s"     => { name => 'warning_total' },
                                  "critical-total:s"    => { name => 'critical_total' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning-loaded', value => $self->{option_results}->{warning_loaded})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-loaded threshold '" . $self->{option_results}->{warning_loaded} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-loaded', value => $self->{option_results}->{critical_loaded})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-loaded threshold '" . $self->{option_results}->{critical_loaded} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-total', value => $self->{option_results}->{warning_total})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-total threshold '" . $self->{option_results}->{warning_total} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-total', value => $self->{option_results}->{critical_total})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-total threshold '" . $self->{option_results}->{critical_total} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{connector} = $options{custom};

    $self->{request} = [
         { mbean => "java.lang:type=ClassLoading", attributes => [ { name => 'UnloadedClassCount' }, { name => 'LoadedClassCount' }, { name => 'TotalLoadedClassCount' } ] },
    ];

    my $result = $self->{connector}->get_attributes(request => $self->{request}, nothing_quit => 1);
    my $exit1 = $self->{perfdata}->threshold_check(value => $result->{"java.lang:type=ClassLoading"}->{TotalLoadedClassCount},
                                                   threshold => [ { label => 'critical-total', exit_litteral => 'critical' }, { label => 'warning-total', exit_litteral => 'warning'} ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $result->{"java.lang:type=ClassLoading"}->{LoadedClassCount},
                                                   threshold => [ { label => 'critical-loaded', exit_litteral => 'critical' }, { label => 'warning-loaded', exit_litteral => 'warning'} ]);

    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Loaded Class Count : %i, Total Loaded Class : %i, Unloaded Class Count : %i",
                                                      $result->{"java.lang:type=ClassLoading"}->{LoadedClassCount}, $result->{"java.lang:type=ClassLoading"}->{TotalLoadedClassCount},
                                                      $result->{"java.lang:type=ClassLoading"}->{UnloadedClassCount}));

    $self->{output}->perfdata_add(label => 'TotalLoadedClassCount',
                                  value => $result->{"java.lang:type=ClassLoading"}->{TotalLoadedClassCount},
                                  warning => $self->{option_results}->{warning_total},
                                  critical => $self->{option_results}->{critical_total},
                                  min => 0);

    $self->{output}->perfdata_add(label => 'LoadedClassCount',
                                  value => $result->{"java.lang:type=ClassLoading"}->{LoadedClassCount},
                                  warning => $self->{option_results}->{warning_loaded},
                                  critical => $self->{option_results}->{critical_loaded},
                                  min => 0);

    $self->{output}->perfdata_add(label => 'UnloadedClassCount',
                                  value => $result->{"java.lang:type=ClassLoading"}->{UnloadedClassCount},
                                  min => 0);


    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Java Class Loading Mbean (Mbean java.lang:type=ClassLoading).

Example:
perl centreon_plugins.pl --plugin=apps::tomcat::jmx::plugin --custommode=jolokia --url=http://10.30.2.22:8080/jolokia-war --mode=classcount --warning-loaded 60 --critical-loaded 75 --warning-total 65 --critical-total 75

=over 8

=item B<--warning-loaded>

Current number of loaded class triggering a warning

=item B<--critical-loaded>

Current number of loaded class triggering a critical

=item B<--warning-total>

Total number of loaded class triggering a warning

=item B<--critical-total>

Total number total of loaded class triggering a critical

=back

=cut

