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

package apps::slack::restapi::mode::countchannels;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_output {
    my ($self, %options) = @_;

    return "Channel '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'channels', type => 1, cb_prefix_output => 'prefix_output' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'count', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Number of channels : %d',
                perfdatas => [
                    { label => 'count', value => 'count', template => '%d',
                      min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{channels} = [
        { label => 'members', set => {
                key_values => [ { name => 'id' }, { name => 'name' }, { name => 'num_members' } ],
                closure_custom_calc => $self->can('custom_info_calc'),
                closure_custom_output => $self->can('custom_info_output'),
                closure_custom_perfdata => $self->can('custom_info_perfdata'),
                closure_custom_threshold_check => $self->can('custom_info_threshold'),
            }
        },
    ];
}

sub custom_info_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'members',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{name} : undef,
        value => $self->{result_values}->{num_members},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_info_threshold {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{num_members},
                                                  threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                                                                 { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_info_output {
    my ($self, %options) = @_;

    my $msg = sprintf("[id: %s] [members: %s]", $self->{result_values}->{id}, $self->{result_values}->{num_members});
    return $msg;
}

sub custom_info_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{id} = $options{new_datas}->{$self->{instance} . '_id'};
    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{num_members} = $options{new_datas}->{$self->{instance} . '_num_members'};

    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-channel:s"      => { name => 'filter_channel' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get_object(url_path => '/channels.list');

    $self->{global}->{count} = 0;

    foreach my $channel (@{$result->{channels}}) {
        if (defined($self->{option_results}->{filter_channel}) && $self->{option_results}->{filter_channel} ne '' &&
            $channel->{name_normalized} !~ /$self->{option_results}->{filter_channel}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $channel->{name_normalized} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{channels}->{$channel->{id}} = {
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

Check channels count.

=over 8

=item B<--warning-count>

Threshold warning for channels count.

=item B<--critical-count>

Threshold critical for channels count.

=item B<--warning-members>

Threshold warning for members count per channel.

=item B<--critical-members>

Threshold critical for members count per channel.

=back

=cut
