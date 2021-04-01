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

package apps::slack::restapi::mode::countmembers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_output {
    my ($self, %options) = @_;

    return "User '" . $options{instance_value}->{real_name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'members', type => 1, cb_prefix_output => 'prefix_output' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'count', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Number of members : %d',
                perfdatas => [
                    { label => 'count', value => 'count', template => '%d',
                      min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{members} = [
        { label => 'info', set => {
                key_values => [ { name => 'id' }, { name => 'real_name' }, { name => 'display_name' } ],
                closure_custom_calc => $self->can('custom_info_calc'),
                closure_custom_output => $self->can('custom_info_output'),
                closure_custom_perfdata => sub { return 0; },
            }
        },
    ];
}
sub custom_info_output {
    my ($self, %options) = @_;

    my $msg = sprintf("[id: %s] [display name: %s]", $self->{result_values}->{id}, $self->{result_values}->{display_name});
    return $msg;
}

sub custom_info_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{id} = $options{new_datas}->{$self->{instance} . '_id'};
    $self->{result_values}->{real_name} = $options{new_datas}->{$self->{instance} . '_real_name'};
    $self->{result_values}->{display_name} = $options{new_datas}->{$self->{instance} . '_display_name'};

    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get_object(url_path => '/users.list');

    $self->{global}->{count} = 0;

    foreach my $member (@{$result->{members}}) {
        $self->{members}->{$member->{id}} = {
            id => $member->{id},
            real_name => $member->{profile}->{real_name_normalized},
            display_name => $member->{profile}->{display_name_normalized},
        };

        $self->{global}->{count}++;
    }
    
    if (scalar(keys %{$self->{members}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No members found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check members count.

=over 8

=item B<--warning-count>

Threshold warning for members count.

=item B<--critical-count>

Threshold critical for members count.

=back

=cut
