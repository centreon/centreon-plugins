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

package apps::voip::asterisk::ami::mode::channelusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'channels-active', set => {
                key_values => [ { name => 'channels_active' } ],
                output_template => 'Channels Active: %s',
                perfdatas => [
                    { label => 'channels_active', value => 'channels_active', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'calls-active', set => {
                key_values => [ { name => 'calls_active' } ],
                output_template => 'Calls Active: %s',
                perfdatas => [
                    { label => 'calls_active', value => 'calls_active', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'extcalls-active', set => {
                key_values => [ { name => 'extcalls_active' } ],
                output_template => 'External Calls Active: %s',
                perfdatas => [
                    { label => 'extcalls_active', value => 'extcalls_active', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'calls-count', set => {
                key_values => [ { name => 'calls_count', diff => 1 } ],
                output_template => 'Calls Count: %s',
                perfdatas => [
                    { label => 'calls_count', value => 'calls_count', template => '%s', min => 0 },
                ],
            }
        },
    ];
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

    my $result = $options{custom}->command(cmd => 'core show channels');
    $self->{global} = { channels_active => 0, calls_active => 0, 
        calls_count => undef, extcalls_active => 0 };
    
    $self->{global}->{channels_active} = $1
        if ($result =~ /^(\d+)\s+active\s+channels/ms);
    $self->{global}->{calls_active} = $1
        if ($result =~ /^(\d+)\s+active\s+calls/ms);
    $self->{global}->{calls_count} = $1
        if ($result =~ /^(\d+)\s+calls\s+processed/ms);
    
    my $count = 0;
    $count++ while ($result =~ /Outgoing\s+Line/msig);
    $self->{global}->{extcalls_active} = $count;
    
    $self->{cache_name} = "asterisk_" . '_' . $self->{mode} . '_' . $options{custom}->get_connect_info() . '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check channel usage: active calls, external calls.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'channels-active', 'calls-active', 'extcalls-active', 
'calls-count'.

=item B<--critical-*>

Threshold critical.
Can be: 'channels-active', 'calls-active', 'extcalls-active', 
'calls-count'.

=back

=cut
