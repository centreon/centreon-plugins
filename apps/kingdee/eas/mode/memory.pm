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
# Author : CHEN JUN , aladdin.china@gmail.com

package apps::kingdee::eas::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'heap', cb_prefix_output => 'prefix_memory_output', type => 0 },
        { name => 'nonheap', cb_prefix_output => 'prefix_memory_output', type => 0 },
    ];

    foreach (('heap', 'nonheap')) {
        $self->{maps_counters}->{$_} = [];
        foreach my $def ((['init', 0], ['max', 0], ['used', 1], ['commited', 1])) {
            push @{$self->{maps_counters}->{$_}},
            { label => 'memory-' . $_ . '-' . $def->[0], nlabel => 'java.memory.' . $_ . '.' . $def->[0] . '.count', display_ok => $def->[1], set => {
                    key_values => [ { name => $def->[0] } ],
                    output_template => $def->[0] . ': %s',
                    perfdatas => [
                        { value => $def->[0] , template => '%s', min => 0 },
                    ],
                }
            };
        }
    }
}

sub prefix_memory_output {
    my ($self, %options) = @_;

    return "Memory '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ( $class, %options ) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options( arguments => {
        'urlpath:s' => { name => 'url_path', default => "/easportal/tools/nagios/checkmemory.jsp" },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path});
    if ($webcontent !~ /^(Type=HeapMemoryUsage|Type=NonHeapMemoryUsage)/mi) {
        $self->{output}->add_option_msg(short_msg => 'Cannot find heap or nonheap memory usage status.');
        $self->{output}->option_exit();
    }

    if ($webcontent =~ /^Type=HeapMemoryUsage\sinit=(\d+)\smax=(\d+)\sused=(\d+)\scommitted=(\d+)/mi) {
        $self->{heap} = {
            init => $1,
            max => $2,
            used => $3,
            commited => $4
        };
    }
    if ($webcontent =~ /^Type=NonHeapMemoryUsage\sinit=(\d+)\smax=(-{0,1}\d+)\sused=(\d+)\scommitted=(\d+)/mi) {
        $self->{nonheap} = {
            init => $1,
            max => $2,
            used => $3,
            commited => $4
        };
    }
}

1;

__END__

=head1 MODE

Check EAS instance heap & nonheap memory usage.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkmemory.jsp')

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'memory-heap-init', 'memory-heap-max', 'memory-heap-used', 'memory-heap-commited',
'memory-nonheap-init', 'memory-nonheap-max', 'memory-nonheap-used', 'memory-nonheap-commited'.

=back

=cut
