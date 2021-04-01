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

package cloud::aws::ec2::mode::spotactiveinstances;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'active', nlabel => 'ec2.spot.instances.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => 'Active instances : %s',
                perfdatas => [
                    { label => 'active', value => 'active', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'healthy', nlabel => 'ec2.spot.instances.healthy.count', set => {
                key_values => [ { name => 'healthy' } ],
                output_template => 'Healthy instances : %s',
                perfdatas => [
                    { label => 'healthy', value => 'healthy', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'unhealthy', nlabel => 'ec2.spot.instances.unhealthy.count', set => {
                key_values => [ { name => 'unhealthy' } ],
                output_template => 'Unhealty instances : %s',
                perfdatas => [
                    { label => 'unhealthy', value => 'unhealthy', template => '%s',
                      min => 0 },
                ],
            }
        },
    ]
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments =>  {
        'spot-fleet-request-id:s' => { name => 'spot_fleet_request_id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{spot_fleet_request_id}) || $self->{option_results}->{spot_fleet_request_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --spot-fleet-request-id option.");
        $self->{output}->option_exit();
    }

}

sub manage_selection {
    my ($self, %options) = @_;
 
    $self->{global} = { active => 0, healthy => 0, unhealthy => 0 };
    $self->{instances} = $options{custom}->ec2spot_get_active_instances_status(spot_fleet_request_id => $self->{option_results}->{spot_fleet_request_id});

    foreach my $instance_id (keys %{$self->{instances}}) {
        $self->{global}->{active}++;
        $self->{global}->{lc($self->{instances}->{$instance_id}->{health})}++;
    }
}

1;

__END__

=head1 MODE

Check EC2 Spot active instance for a specific fleet

=over 8

=item B<--warning-*> B<--critical-*>

Warning and Critical thresholds. You can use 'active', 'healthy', 'unhealthy'

=back

=cut
