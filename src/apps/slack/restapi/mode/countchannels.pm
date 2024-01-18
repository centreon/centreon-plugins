#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::slack::restapi::mode::countchannels;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_output {
    my ($self, %options) = @_;

    return sprintf(
        "Channel '%s' [id: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{id}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'channels', type => 1, cb_prefix_output => 'prefix_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'count', nlabel => 'channels.total.count', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Number of channels: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{channels} = [
        { label => 'members', nlabel => 'channel.members.count', set => {
                key_values => [ { name => 'num_members' }, { name => 'id' }, { name => 'name' } ],
                output_template => 'members: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-channel:s' => { name => 'filter_channel' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_web_api(endpoint => '/conversations.list');

    $self->{global}->{count} = 0;
    foreach my $channel (@{$result->{channels}}) {
        if (defined($self->{option_results}->{filter_channel}) && $self->{option_results}->{filter_channel} ne '' &&
            $channel->{name_normalized} !~ /$self->{option_results}->{filter_channel}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $channel->{name_normalized} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{channels}->{ $channel->{id} } = {
            id => $channel->{id},
            name => $channel->{name_normalized},
            num_members => $channel->{num_members},
        };

        $self->{global}->{count}++;
    }

    if (scalar(keys %{$self->{channels}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No channels found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check channels.

Scope: 'channels.read'.

=over 8

=item B<--filter-channel>

Filter channels by channel name (can be a regexp).

=item B<--warning-count>

Warning threshold for channels count.

=item B<--critical-count>

Critical threshold for channels count.

=item B<--warning-members>

Warning threshold for members count per channel.

=item B<--critical-members>

Critical threshold for members count per channel.

=back

=cut
