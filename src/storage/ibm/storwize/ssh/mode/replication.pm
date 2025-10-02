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

package storage::ibm::storwize::ssh::mode::replication;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_replication_output {
    my ($self, %options) = @_;

    return sprintf(
        'Volume %s [group: %s, vdisk: %s] ',
        $options{instance_value}->{name},
        $options{instance_value}->{group_name},
        $options{instance_value}->{vdisk_name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'replication', type => 1, cb_prefix_output => 'prefix_replication_output', message_multiple => 'All volumes are in consistent_synchronized state'}
    ];

    $self->{maps_counters}->{replication} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{status} =~ /idling/i',
            set => {
                key_values => [ { name => 'status' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-consistency-group-name:s' => { name => 'filter_group' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($content) = $options{custom}->execute_command(command => 'lsrcrelationship -delim :',
                                                      wrap_command => 1 );
    my $result = $options{custom}->get_hasharray(content => $content, delim => ':');

    $self->{replication} = {};
    foreach my $item (@$result) {
        next if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '' &&
            $item->{consistency_group_name} !~ /$self->{option_results}->{filter_group}/);

        $self->{replication}->{ $item->{id} } = {
            name => $item->{name},
            vdisk_name => $item->{aux_vdisk_name},
            group_name => $item->{consistency_group_name},
            status => $item->{state}
        };
    }

    if (scalar(keys %{$self->{replication}}) <= 0){
        $self->{output}->add_option_msg(short_msg => 'No volume found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check replication usages.

=over 8

=item B<--filter-consistency-group-name>

Filter group name (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /idling/i').
You can use the following variables: %{status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{status}

=back

=cut
