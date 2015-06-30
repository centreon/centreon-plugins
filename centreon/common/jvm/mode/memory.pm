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
# Authors : Simon Bomm <sbomm@merethis.com>
#
####################################################################################

package centreon::common::jvm::mode::memory;

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
                                  "warning-heap:s"              => { name => 'warning_heap', default => '80' },
                                  "critical-heap:s"             => { name => 'critical_heap', default => '90' },
                                  "warning-nonheap:s"              => { name => 'warning_nonheap', default => '80' },
                                  "critical-nonheap:s"             => { name => 'critical_nonheap', default => '90' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning-heap', value => $self->{option_results}->{warning_heap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-heap threshold '" . $self->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-heap', value => $self->{option_results}->{critical_heap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-heap threshold '" . $self->{critical} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-nonheap', value => $self->{option_results}->{warning_nonheap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-nonheap threshold '" . $self->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-nonheap', value => $self->{option_results}->{critical_nonheap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-nonheap threshold '" . $self->{critical} . "'.");
       $self->{output}->option_exit();
    }

}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{connector} = $options{custom};

    $self->{request} = [
         { mbean => "java.lang:type=Memory" }
    ];

    my $result = $self->{connector}->get_attributes(request => $self->{request}, nothing_quit => 1);
    
    my $prct_heap = $result->{"java.lang:type=Memory"}->{HeapMemoryUsage}->{used} / $result->{"java.lang:type=Memory"}->{HeapMemoryUsage}->{max} * 100;
    my $prct_nonheap = $result->{"java.lang:type=Memory"}->{NonHeapMemoryUsage}->{used} / $result->{"java.lang:type=Memory"}->{NonHeapMemoryUsage}->{max} * 100;

    my $exit1 = $self->{perfdata}->threshold_check(value => $prct_heap,
                                                   threshold => [ { label => 'critical-heap', exit_litteral => 'critical' }, { label => 'warning-heap', 'exit_litteral' => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $prct_nonheap,
                                                   threshold => [ { label => 'critical-nonheap', exit_litteral => 'critical' }, { label => 'warning-nonheap', 'exit_litteral' => 'warning'} ]);

    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("HeapMemory Usage: %.2f%% - NonHeapMemoryUsage : %.2f%%",
                                                      $prct_heap, $prct_nonheap));

    $self->{output}->perfdata_add(label => 'HeapMemoryUsage', unit => 'B',
                                  value => $result->{"java.lang:type=Memory"}->{HeapMemoryUsage}->{used},
                                  warning => $self->{option_results}->{warning_heap} / 100 * $result->{"java.lang:type=Memory"}->{HeapMemoryUsage}->{used},
                                  critical => $self->{option_results}->{critical_heap} / 100 * $result->{"java.lang:type=Memory"}->{HeapMemoryUsage}->{used},
                                  min => 0, max => $result->{"java.lang:type=Memory"}->{HeapMemoryUsage}->{max});

    $self->{output}->perfdata_add(label => 'NonHeapMemoryUsage', unit => 'B',
                                  value => $result->{"java.lang:type=Memory"}->{NonHeapMemoryUsage}->{used},
                                  warning => $self->{option_results}->{warning_nonheap} / 100 * $result->{"java.lang:type=Memory"}->{NonHeapMemoryUsage}->{used},
                                  critical => $self->{option_results}->{critical_nonheap} / 100 * $result->{"java.lang:type=Memory"}->{NonHeapMemoryUsage}->{used},
                                  min => 0, max => $result->{"java.lang:type=Memory"}->{NonHeapMemoryUsage}->{max});

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Java Heap and NonHeap Memory usage (Mbean java.lang:type=Memory).

Example:
perl centreon_plugins.pl --plugin=apps::tomcat::jmx::plugin --custommode=jolokia --url=http://10.30.2.22:8080/jolokia-war --mode=memory --warning-heap 60 --critical-heap 75 --warning-nonheap 65 --critical-nonheap 75

=over 8

=item B<--warning-heap>

Threshold warning of Heap memory usage

=item B<--critical-heap>

Threshold critical of Heap memory usage

=item B<--warning-nonheap>

Threshold warning of NonHeap memory usage

=item B<--critical-nonheap>

Threshold critical of NonHeap memory usage

=back

=cut

