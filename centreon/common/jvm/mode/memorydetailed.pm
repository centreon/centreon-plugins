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
# Authors :  Simon Bomm <sbomm@centreon.com>
# 
####################################################################################

package centreon::common::jvm::mode::memorydetailed;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %mapping_memory = (
    'Eden Space' => 'eden',
    'Par Eden Space' => 'eden',
    'PS Eden Space' => 'eden',
    'Survivor Space' => 'survivor',
    'Par Survivor Space' => 'survivor',
    'PS Survivor Space' => 'survivor',
    'CMS Perm Gen' => 'permanent',
    'PS Perm Gen' => 'permanent',
    'Perm Gen' => 'permanent',
    'Code Cache' => 'code',
    'CMS Old Gen' => 'tenured',
    'PS Old Gen' => 'tenured',
    'Tenured Gen' => 'tenured',
);


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning-eden:s"              => { name => 'warning_eden' },
                                  "critical-eden:s"             => { name => 'critical_eden' },
                                  "warning-survivor:s"          => { name => 'warning_survivor' },
                                  "critical-survivor:s"         => { name => 'critical_survivor' },
                                  "warning-tenured:s"           => { name => 'warning_tenured' },
                                  "critical-tenured:s"          => { name => 'critical_tenured' },
                                  "warning-permanent:s"         => { name => 'warning_permanent' },
                                  "critical-permanent:s"        => { name => 'critical_permanent' },
                                  "warning-code:s"              => { name => 'warning_code' },
                                  "critical-code:s"             => { name => 'critical_code' }
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    foreach my $label ('warning_eden', 'critical_eden', 'warning_survivor', 'critical_survivor', 'warning_tenured', 'critical_tenured', 'warning_permanent', 'critical_permanent', 'warning_code', 'critical_code') {
        if (($self->{perfdata}->threshold_validate(label => $label, value => $self->{option_results}->{$label})) == 0) {
            my ($label_opt) = $label;
		    $label_opt =~ tr/_/-/;
		    $self->{output}->add_option_msg(short_msg => "Wrong " . $label_opt . " threshold '" . $self->{option_results}->{$label} . "'.");
		    $self->{output}->option_exit();
        }
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{connector} = $options{custom};

    $self->{request} = [
         { mbean => "java.lang:type=MemoryPool,name=*", attributes => [ { name => 'Usage' } ] }
    ];
    
    my $result = $self->{connector}->get_attributes(request => $self->{request}, nothing_quit => 1);

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All memories within bounds');

    foreach my $key (keys %$result) { 
        $key =~ /name=(.*?),type/;
        my $memtype = $1;
        my $prct = $result->{"java.lang:name=".$memtype.",type=MemoryPool"}->{Usage}->{used} / $result->{"java.lang:name=".$memtype.",type=MemoryPool"}->{Usage}->{max} * 100;

        $self->{output}->perfdata_add(label => $mapping_memory{$memtype}, unit => 'B',
                                      value => $result->{"java.lang:name=" . $memtype . ",type=MemoryPool"}->{Usage}->{used},
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $mapping_memory{$memtype}, total => $result->{"java.lang:name=" . $memtype . ",type=MemoryPool"}->{Usage}->{used}, cast_int => 1),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $mapping_memory{$memtype}, total => $result->{"java.lang:name=" . $memtype . ",type=MemoryPool"}->{Usage}->{used}, cast_int => 1),
                                      min => 0, max => $result->{"java.lang:name=".$memtype.",type=MemoryPool"}->{Usage}->{max});

        my $exit = $self->{perfdata}->threshold_check(value => $prct,
                                                      threshold => [ { label => 'critical_' . $mapping_memory{$memtype}, exit_litteral => 'critical' },
                                                                     { label => 'warning_' . $mapping_memory{$memtype}, exit_litteral => 'warning' }  ]);

        $self->{output}->output_add(long_msg => sprintf("%s usage %.2f%%", $memtype, $prct));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("%s usage %.2f%% ", $memtype, $prct));
        }

    }

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check JVM Memory Pools :

Eden Space           (heap)     (-eden)      : The pool from which memory is initially allocated for most objects.
Survivor Space       (heap)     (-survivor)  : The pool containing objects that have survived the garbage collection of the Eden space.
Tenured Generation   (heap)     (-tenured)   : The pool containing objects that have existed for some time in the survivor space.
Permanent Generation (non-heap) (-permanent) : The pool containing all the reflective data of the virtual machine itself, such as class and method objects. 
Code Cache           (non-heap) (-code)      : The HotSpot Java VM also includes a code cache, containing memory that is used for compilation and storage of native code.

Example:
perl centreon_plugins.pl --plugin=apps::tomcat::jmx::plugin --custommode=jolokia --url=http://10.30.2.22:00/jolokia-war --mode=memory-detailed --warning-eden 60 --critical-eden 75 --warning-survivor 65 --critical-survivor 75

=over 8

=item B<--warning-eden>

Threshold warning of Heap 'Eden Space' memory usage

=item B<--critical-eden>

Threshold critical of Heap 'Survivor Space' memory usage

=item B<--warning-tenured>

Threshold warning of Heap 'Tenured Generation'  memory usage

=item B<--critical-tenured>

Threshold critical of Heap 'Tenured Generation'  memory usage

=item B<--warning-survivor>

Threshold warning of Heap 'Survivor Space' memory usage

=item B<--critical-survivor>

Threshold critical of Heap 'Survivor Space' memory usage

=item B<--warning-permanent>

Threshold warning of NonHeap 'Permanent Generation' memory usage

=item B<--critical-permanent>

Threshold critical of NonHeap 'Permanent Generation' memory usage

=item B<--warning-code>

Threshold warning of NonHeap 'Code Cache' memory usage

=item B<--critical-code>

Threshold critical of NonHeap 'Code Cache' memory usage

=back

=cut
