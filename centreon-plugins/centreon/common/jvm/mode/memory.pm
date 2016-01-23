#
# Copyright 2016 Centreon (http://www.centreon.com/)
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
                                  "warning-heap:s"      => { name => 'warning_heap' },
                                  "critical-heap:s"     => { name => 'critical_heap' },
                                  "warning-nonheap:s"   => { name => 'warning_nonheap' },
                                  "critical-nonheap:s"  => { name => 'critical_nonheap' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning-heap', value => $self->{option_results}->{warning_heap})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-heap threshold '" . $self->{option_results}->{warning_heap} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-heap', value => $self->{option_results}->{critical_heap})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-heap threshold '" . $self->{option_results}->{critical_heap} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-nonheap', value => $self->{option_results}->{warning_nonheap})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-nonheap threshold '" . $self->{option_results}->{warning_nonheap} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-nonheap', value => $self->{option_results}->{critical_nonheap})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-nonheap threshold '" . $self->{option_results}->{critical_nonheap} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{connector} = $options{custom};

    $self->{request} = [
         { mbean => "java.lang:type=Memory" }
    ];

    my $result = $self->{connector}->get_attributes(request => $self->{request}, nothing_quit => 1);
    
    my $prct_heap = $result->{"java.lang:type=Memory"}->{HeapMemoryUsage}->{used} / $result->{"java.lang:type=Memory"}->{HeapMemoryUsage}->{max} * 100;
    my $prct_nonheap = $result->{"java.lang:type=Memory"}->{NonHeapMemoryUsage}->{used} / $result->{"java.lang:type=Memory"}->{NonHeapMemoryUsage}->{max} * 100;

    my $exit1 = $self->{perfdata}->threshold_check(value => $prct_heap,
                                                   threshold => [ { label => 'critical-heap', exit_litteral => 'critical' }, { label => 'warning-heap', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $prct_nonheap,
                                                   threshold => [ { label => 'critical-nonheap', exit_litteral => 'critical' }, { label => 'warning-nonheap', exit_litteral => 'warning'} ]);
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("HeapMemory Usage: %.2f%% - NonHeapMemoryUsage : %.2f%%",
                                                      $prct_heap, $prct_nonheap));

    $self->{output}->perfdata_add(label => 'HeapMemoryUsage', unit => 'B',
                                  value => $result->{"java.lang:type=Memory"}->{HeapMemoryUsage}->{used},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-heap', total => $result->{"java.lang:type=Memory"}->{HeapMemoryUsage}->{used}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-heap', total => $result->{"java.lang:type=Memory"}->{HeapMemoryUsage}->{used}, cast_int => 1),
                                  min => 0, max => $result->{"java.lang:type=Memory"}->{HeapMemoryUsage}->{max});

    $self->{output}->perfdata_add(label => 'NonHeapMemoryUsage', unit => 'B',
                                  value => $result->{"java.lang:type=Memory"}->{NonHeapMemoryUsage}->{used},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-nonheap', total => $result->{"java.lang:type=Memory"}->{NonHeapMemoryUsage}->{used}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-nonheap', total => $result->{"java.lang:type=Memory"}->{NonHeapMemoryUsage}->{used}, cast_int => 1),
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

