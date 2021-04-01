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

package centreon::common::jvm::mode::classcount;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'current', set => {
                key_values => [ { name => 'LoadedClassCount' } ],
                output_template => 'Current : %s',
                perfdatas => [
                    { label => 'current', value => 'LoadedClassCount', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'loaded', set => {
                key_values => [ { name => 'TotalLoadedClassCount', diff => 1 } ],
                output_template => 'Loaded : %s',
                perfdatas => [
                    { label => 'loaded', value => 'TotalLoadedClassCount', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'unloaded', set => {
                key_values => [ { name => 'UnloadedClassCount', diff => 1 } ],
                output_template => 'Unloaded : %s',
                perfdatas => [
                    { label => 'unloaded', value => 'UnloadedClassCount', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "Class ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mbean = 'java.lang:type=ClassLoading';
    my $request = [
        { mbean => $mbean, attributes => [ { name => 'UnloadedClassCount' }, { name => 'LoadedClassCount' }, { name => 'TotalLoadedClassCount' } ] },
    ];
    my $result = $options{custom}->get_attributes(request => $request, nothing_quit => 1);

    $self->{global} = { %{$result->{$mbean}} };
    
    $self->{cache_name} = "jvm_standard_" . $self->{mode} . '_' . md5_hex($options{custom}->get_connection_info()) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check Java Class Loading Mbean.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='current'

=item B<--warning-*>

Threshold warning.
Can be: 'unloaded', 'loaded', 'current'.

=item B<--critical-*>

Threshold critical.
Can be: 'unloaded', 'loaded', 'current'.

=back

=cut
