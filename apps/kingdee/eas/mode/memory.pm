#
# Copyright 2018 Centreon (http://www.centreon.com/)
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
# Author : CHEN JUN , aladdin.china@gmail.com

package apps::kingdee::eas::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ( $class, %options ) = @_;
    my $self = $class->SUPER::new( package => __PACKAGE__, %options );
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(
        arguments => {
            "urlpath:s"          => { name => 'url_path', default => "/easportal/tools/nagios/checkmemory.jsp" },
            "warning-heap:s"     => { name => 'warning-heap' , default => ",,,"},
            "warning-nonheap:s"  => { name => 'warning-nonheap' , default => ",,,"},
            "critical-heap:s"    => { name => 'critical-heap' , default => ",,,"},
            "critical-nonheap:s" => { name => 'critical-nonheap' , default => ",,,"},
        }
    );

    return $self;
}

sub check_options {
    my ( $self, %options ) = @_;
    $self->SUPER::init(%options);

    ($self->{warn_init_heap}, $self->{warn_max_heap}, $self->{warn_used_heap}, $self->{warn_committed_heap}) 
        = split /,/, $self->{option_results}->{"warning-heap"};
    ($self->{warn_init_nonheap}, $self->{warn_max_nonheap}, $self->{warn_used_nonheap}, $self->{warn_committed_nonheap})
        = split /,/, $self->{option_results}->{"warning-nonheap"};
    ($self->{crit_init_heap}, $self->{crit_max_heap}, $self->{crit_used_heap}, $self->{crit_committed_heap}) 
        = split /,/, $self->{option_results}->{"critical-heap"};
    ($self->{crit_init_nonheap}, $self->{crit_max_nonheap}, $self->{crit_used_nonheap}, $self->{crit_committed_nonheap})
        = split /,/, $self->{option_results}->{"critical-nonheap"};

    # warning-heap
    if (($self->{perfdata}->threshold_validate(label => 'warn_init_heap', value => $self->{warn_init_heap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-heap init threshold '" . $self->{warn_init_heap} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn_max_heap', value => $self->{warn_max_heap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-heap max threshold '" . $self->{warn_max_heap} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn_used_heap', value => $self->{warn_used_heap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-heap used threshold '" . $self->{warn_used_heap} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn_committed_heap', value => $self->{warn_committed_heap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-heap committed threshold '" . $self->{warn_committed_heap} . "'.");
       $self->{output}->option_exit();
    }

    # waring-nonheap
    if (($self->{perfdata}->threshold_validate(label => 'warn_init_nonheap', value => $self->{warn_init_nonheap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-nonheap init threshold '" . $self->{warn_init_nonheap} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn_max_nonheap', value => $self->{warn_max_nonheap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-nonheap max threshold '" . $self->{warn_max_nonheap} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn_used_nonheap', value => $self->{warn_used_nonheap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-nonheap used threshold '" . $self->{warn_used_nonheap} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn_committed_nonheap', value => $self->{warn_committed_nonheap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-nonheap committed threshold '" . $self->{warn_committed_nonheap} . "'.");
       $self->{output}->option_exit();
    }

    # critical-heap
    if (($self->{perfdata}->threshold_validate(label => 'crit_init_heap', value => $self->{crit_init_heap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-heap init threshold '" . $self->{crit_init_heap} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit_max_heap', value => $self->{crit_max_heap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-heap max threshold '" . $self->{crit_max_heap} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit_used_heap', value => $self->{crit_used_heap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-heap used threshold '" . $self->{crit_used_heap} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit_committed_heap', value => $self->{crit_committed_heap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-heap committed threshold '" . $self->{crit_committed_heap} . "'.");
       $self->{output}->option_exit();
    }

    # critical-nonheap
    if (($self->{perfdata}->threshold_validate(label => 'crit_init_nonheap', value => $self->{crit_init_nonheap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-nonheap init threshold '" . $self->{crit_init_nonheap} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit_max_nonheap', value => $self->{crit_max_nonheap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-nonheap max threshold '" . $self->{crit_max_nonheap} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit_used_nonheap', value => $self->{crit_used_nonheap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-nonheap used threshold '" . $self->{crit_used_nonheap} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit_committed_nonheap', value => $self->{crit_committed_nonheap})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-nonheap committed threshold '" . $self->{crit_committed_nonheap} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ( $self, %options ) = @_;

    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path});

    if ($webcontent !~ /(^Type=HeapMemoryUsage|^Type=NonHeapMemoryUsage)/mi) {
        $self->{output}->output_add(
            severity  => 'UNKNOWN',
            short_msg => "Cannot find heap or nonheap memory usage status."
        );
        $self->{output}->option_exit();
    }

    my ( $init_heap, $max_heap, $used_heap, $committed_heap ) = ( 0, 0, 0, 0 );
    my ( $init_nonheap, $max_nonheap, $used_nonheap, $committed_nonheap ) = ( 0, 0, 0, 0 );
    if ( $webcontent =~ /^Type=HeapMemoryUsage\sinit=(\d+)\smax=(\d+)\sused=(\d+)\scommitted=(\d+)/mi ){
        ( $init_heap, $max_heap, $used_heap, $committed_heap ) = ( $1, $2, $3, $4 );
        $self->{output}->output_add(
            severity  => 'ok',
            short_msg => sprintf(
                "Heap Memory: init %d , max %d ,used %d ,commited %d",
                $init_heap, $max_heap, $used_heap, $committed_heap
            )
        );
    }
    if ( $webcontent =~ /^Type=NonHeapMemoryUsage\sinit=(\d+)\smax=(-{0,1}\d+)\sused=(\d+)\scommitted=(\d+)/mi ){
        ( $init_nonheap, $max_nonheap, $used_nonheap, $committed_nonheap ) = ( $1, $2, $3, $4 );
        $self->{output}->output_add(
            severity  => 'ok',
            short_msg => sprintf(
                "NonHeap Memory: init %d , max %d ,used %d ,commited %d",
                $init_nonheap, $max_nonheap,
                $used_nonheap, $committed_nonheap
            )
        );
    }
    
    my $exit = $self->{perfdata}->threshold_check(value => $init_heap, 
        threshold => [ { label => 'crit_init_heap', 'exit_litteral' => 'critical' }, 
                       { label => 'warn_init_heap', 'exit_litteral' => 'warning' } ]);
    if ($exit ne "ok"){
        $self->{output}->output_add(
            severity  => $exit,
            short_msg => sprintf("Init Heap: %d", $init_heap)
        );
    }
    $exit = $self->{perfdata}->threshold_check(value => $max_heap, 
        threshold => [ { label => 'crit_max_heap', 'exit_litteral' => 'critical' }, 
                       { label => 'warn_max_heap', 'exit_litteral' => 'warning' } ]);
    if ($exit ne "ok"){
        $self->{output}->output_add(
            severity  => $exit,
            short_msg => sprintf("Max Heap: %d", $max_heap)
        );
    }
    $exit = $self->{perfdata}->threshold_check(value => $used_heap, 
        threshold => [ { label => 'crit_used_heap', 'exit_litteral' => 'critical' }, 
                       { label => 'warn_used_heap', 'exit_litteral' => 'warning' } ]);
    if ($exit ne "ok"){
        $self->{output}->output_add(
            severity  => $exit,
            short_msg => sprintf("Used Heap: %d", $used_heap)
        );
    }
    $exit = $self->{perfdata}->threshold_check(value => $committed_heap, 
        threshold => [ { label => 'crit_committed_heap', 'exit_litteral' => 'critical' }, 
                       { label => 'warn_committed_heap', 'exit_litteral' => 'warning' } ]);
    if ($exit ne "ok"){
        $self->{output}->output_add(
            severity  => $exit,
            short_msg => sprintf("Committed Heap: %d", $committed_heap)
        );
    }

    $exit = $self->{perfdata}->threshold_check(value => $init_nonheap, 
        threshold => [ { label => 'crit_init_nonheap', 'exit_litteral' => 'critical' }, 
                       { label => 'warn_init_nonheap', 'exit_litteral' => 'warning' } ]);
    if ($exit ne "ok"){
        $self->{output}->output_add(
            severity  => $exit,
            short_msg => sprintf("Init NonHeap: %d", $init_nonheap)
        );
    }
    $exit = $self->{perfdata}->threshold_check(value => $max_nonheap, 
        threshold => [ { label => 'crit_max_nonheap', 'exit_litteral' => 'critical' }, 
                       { label => 'warn_max_nonheap', 'exit_litteral' => 'warning' } ]);
    if ($exit ne "ok"){
        $self->{output}->output_add(
            severity  => $exit,
            short_msg => sprintf("Max NonHeap: %d", $max_nonheap)
        );
    }
    $exit = $self->{perfdata}->threshold_check(value => $used_nonheap, 
        threshold => [ { label => 'crit_used_nonheap', 'exit_litteral' => 'critical' }, 
                       { label => 'warn_used_nonheap', 'exit_litteral' => 'warning' } ]);
    if ($exit ne "ok"){
        $self->{output}->output_add(
            severity  => $exit,
            short_msg => sprintf("Used NonHeap: %d", $used_nonheap)
        );
    }
    $exit = $self->{perfdata}->threshold_check(value => $committed_nonheap, 
        threshold => [ { label => 'crit_committed_nonheap', 'exit_litteral' => 'critical' }, 
                       { label => 'warn_committed_nonheap', 'exit_litteral' => 'warning' } ]);
    if ($exit ne "ok"){
        $self->{output}->output_add(
            severity  => $exit,
            short_msg => sprintf("Committed NonHeap: %d", $committed_nonheap)
        );
    }

    $self->{output}->perfdata_add(
        label => "init_heap",
        value => $init_heap,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_init_heap'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_init_heap'),
    );
    $self->{output}->perfdata_add(
        label => "max_heap",
        value => $max_heap,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_max_heap'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_max_heap'),
    );
    $self->{output}->perfdata_add(
        label => "used_heap",
        value => $used_heap,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_used_heap'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_used_heap'),
    );
    $self->{output}->perfdata_add(
        label => "committed_heap",
        value => $committed_heap,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_committed_heap'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_committed_heap'),
    );
    $self->{output}->perfdata_add(
        label => "init_nonheap",
        value => $init_nonheap,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_init_nonheap'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_init_nonheap'),
    );
    $self->{output}->perfdata_add(
        label => "max_nonheap",
        value => $max_nonheap,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_max_nonheap'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_max_nonheap'),
    );
    $self->{output}->perfdata_add(
        label => "used_nonheap",
        value => $used_nonheap,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_used_nonheap'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_used_nonheap'),
    );
    $self->{output}->perfdata_add(
        label => "committed_nonheap",
        value => $committed_nonheap,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_committed_nonheap'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_committed_nonheap'),
    );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check EAS instance heap & nonheap memory usage.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkmemory.jsp')

=item B<--warning-*>

Warning Threshold (init,max,used,committed), '*' Can be: 'heap', 'nonheap'.

=item B<--critical-*>

Critical Threshold (init,max,used,committed), '*' Can be: 'heap', 'nonheap'.

=back

=cut
