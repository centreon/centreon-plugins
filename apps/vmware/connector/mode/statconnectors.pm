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

package apps::vmware::connector::mode::statconnectors;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'container', type => 1, cb_prefix_output => 'prefix_container_output', message_multiple => 'All containers are ok' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total-requests', nlabel => 'connector.requests.total.count', set => {
                key_values => [ { name => 'requests', diff => 1 } ],
                output_template => 'Total %s requests',
                perfdatas => [
                    { label => 'requests', template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{container} = [
        { label => 'requests', nlabel => 'connector.requests.total.count', set => {
                key_values => [ { name => 'requests', diff => 1 } ],
                output_template => '%s requests',
                perfdatas => [
                    { label => 'requests', template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_container_output {
    my ($self, %options) = @_;

    return "Container '" . $options{instance_value}->{display} . "' : ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { requests => 0 };
    $self->{container} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'stats'
    );

    foreach my $container_name (keys %{$response->{data}}) {
        $self->{container}->{$container_name} = {
            display => $container_name,
            requests => $response->{data}->{$container_name}->{requests}
        };
        $self->{global}->{requests} += $response->{data}->{$container_name}->{requests};
    }
    
    $self->{cache_name} = "cache_vmware_" . $options{custom}->get_id() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Get number of requests for each connectors (information from daemon. Not VMWare).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'total-requests', 'requests'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-requests', 'requests'.

=back

=cut
