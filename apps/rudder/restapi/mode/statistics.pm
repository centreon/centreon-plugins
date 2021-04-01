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

package apps::rudder::restapi::mode::statistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'nodes', set => {
                key_values => [ { name => 'nodes' } ],
                output_template => 'Nodes: %d',
                perfdatas => [
                    { label => 'nodes', value => 'nodes', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'pending-nodes', set => {
                key_values => [ { name => 'pending_nodes' } ],
                output_template => 'Pending Nodes: %d',
                perfdatas => [
                    { label => 'pending_nodes', value => 'pending_nodes', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'rules', set => {
                key_values => [ { name => 'rules' } ],
                output_template => 'Rules: %d',
                perfdatas => [
                    { label => 'rules', value => 'rules', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'directives', set => {
                key_values => [ { name => 'directives' } ],
                output_template => 'Directives: %d',
                perfdatas => [
                    { label => 'directives', value => 'directives', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'groups', set => {
                key_values => [ { name => 'groups' } ],
                output_template => 'Groups: %d',
                perfdatas => [
                    { label => 'groups', value => 'groups', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'techniques', set => {
                key_values => [ { name => 'techniques' } ],
                output_template => 'Techniques: %d',
                perfdatas => [
                    { label => 'techniques', value => 'techniques', template => '%d',
                      min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{compliances} = {};

    my $results = $options{custom}->request_api(url_path => '/nodes?include=minimal');
    $self->{global}->{nodes} = scalar(@{$results->{nodes}});
    $results = $options{custom}->request_api(url_path => '/nodes/pending?include=minimal');
    $self->{global}->{pending_nodes} = scalar(@{$results->{nodes}});
    $results = $options{custom}->request_api(url_path => '/rules');
    $self->{global}->{rules} = scalar(@{$results->{rules}});
    $results = $options{custom}->request_api(url_path => '/directives');
    $self->{global}->{directives} = scalar(@{$results->{directives}});
    $results = $options{custom}->request_api(url_path => '/groups');
    $self->{global}->{groups} = scalar(@{$results->{groups}});
    $results = $options{custom}->request_api(url_path => '/techniques');
    $self->{global}->{techniques} = scalar(@{$results->{techniques}});
}

1;

__END__

=head1 MODE

Check statistics (objects count).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'nodes', 'pending-nodes', 'rules',
'directives', 'groups', 'techniques'.

=item B<--critical-*>

Threshold critical.
Can be: 'nodes', 'pending-nodes', 'rules',
'directives', 'groups', 'techniques'.

=back

=cut
