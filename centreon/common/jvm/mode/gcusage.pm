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

package centreon::common::jvm::mode::gcusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'gc', type => 1, cb_prefix_output => 'prefix_gc_output', message_multiple => 'All garbage collectors are ok' }
    ];
    
    $self->{maps_counters}->{gc} = [
        { label => 'time', set => {
                key_values => [ { name => 'time', diff => 1 }, { name => 'display' } ],
                output_template => 'Collection Time : %s ms',
                perfdatas => [
                    { label => 'time', value => 'time', template => '%s',
                      unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'count', set => {
                key_values => [ { name => 'count', diff => 1 }, { name => 'display' } ],
                output_template => 'Collection Count : %s',
                perfdatas => [
                    { label => 'count', value => 'count', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_gc_output {
    my ($self, %options) = @_;
    
    return "Garbage collector '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                "filter-name:s"           => { name => 'filter_name' },
                                });
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{request} = [
         { mbean => "java.lang:type=GarbageCollector,name=*", attributes => [ { name => 'CollectionCount' }, { name => 'CollectionTime' } ] }
    ];

    $self->{gc} = {};
    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 1);

    foreach my $key (keys %$result) { 
        $key =~ /name=(.*?)(?:,|$)/;
        my $name = $1;
    
        $self->{gc}->{$name} = { 
            display => $name, 
            time => $result->{$key}->{CollectionTime},
            count => $result->{$key}->{CollectionCount}
        }
    }
    
    if (scalar(keys %{$self->{gc}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No garbage collector found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "jvm_standard_" . $self->{mode} . '_' . md5_hex($options{custom}->get_connection_info()) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check garbage collectors.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^count$'

=item B<--filter-name>

Filter garbage collector name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'count', 'time' (ms).

=item B<--critical-*>

Threshold critical.
Can be: 'count', 'time' (ms).

=back

=cut
