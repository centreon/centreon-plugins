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

package centreon::common::jvm::mode::threads;

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
        { label => 'active', set => {
                key_values => [ { name => 'ThreadCount' } ],
                output_template => 'Active : %s',
                perfdatas => [
                    { label => 'active', value => 'ThreadCount', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'started', set => {
                key_values => [ { name => 'TotalStartedThreadCount', diff => 1 } ],
                output_template => 'Started : %s',
                perfdatas => [
                    { label => 'started', value => 'TotalStartedThreadCount', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'daemon', set => {
                key_values => [ { name => 'DaemonThreadCount' } ],
                output_template => 'Daemon : %s',
                perfdatas => [
                    { label => 'daemon', value => 'DaemonThreadCount', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "Threads ";
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

    my $mbean = 'java.lang:type=Threading';
    my $request = [
        { mbean => $mbean, attributes => [ { name => 'TotalStartedThreadCount' }, { name => 'ThreadCount' }, { name => 'DaemonThreadCount' } ] },
    ];
    my $result = $options{custom}->get_attributes(request => $request, nothing_quit => 1);

    $self->{global} = { %{$result->{$mbean}} };
    
    $self->{cache_name} = "jvm_standard_" . $self->{mode} . '_' . md5_hex($options{custom}->get_connection_info()) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check threads.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'active', 'started', 'daemon'.

=item B<--critical-*>

Threshold critical.
Can be: 'active', 'started', 'daemon'.

=back

=cut
