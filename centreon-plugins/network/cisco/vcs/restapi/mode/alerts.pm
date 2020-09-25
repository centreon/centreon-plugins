#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::cisco::vcs::restapi::mode::alerts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_output_global {
    my ($self, %options) = @_;

    return 'Alerts ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output_global' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'alerts.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'acknowledged', nlabel => 'alerts.acknowledged.current.count', set => {
                key_values => [ { name => 'acknowledged' }, { name => 'total' } ],
                output_template => 'acknowledged: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'unacknowledged', nlabel => 'alerts.unacknowledged.current.count', set => {
                key_values => [ { name => 'unacknowledged' }, { name => 'total' } ],
                output_template => 'unacknowledged: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
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
        'filter-reason:s' => { name => 'filter_reason' },
        'display-alerts'  => { name => 'display_alerts' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_endpoint(
        endpoint => '/getxml?location=/Status/Warnings',
        force_array => ['Warning']
    );

    $self->{global} = { total => 0, acknowledged => 0, unacknowledged => 0 };
    foreach my $alert (@{$results->{Warnings}->{Warning}}) {
        next if (defined($self->{option_results}->{filter_reason}) && $self->{option_results}->{filter_reason} ne '' 
            && $alert->{Reason}->{content} !~ /$self->{option_results}->{filter_reason}/);

        $self->{global}->{ lc($alert->{State}->{content}) }++;
        $self->{global}->{total}++;
        if (defined($self->{option_results}->{display_alerts})) {
            $self->{output}->output_add(
                long_msg => sprintf(
                    'alert [id: %s] [state: %s]: %s',
                    $alert->{ID}->{content},
                    lc($alert->{State}->{content}),
                    $alert->{Reason}->{content}
                )
            );
        }
    }
}

1;

__END__

=head1 MODE

Check alerts.

=over 8

=item B<--filter-reason>

Filter alerts by reason (Can use regexp).

=item B<--display-alerts

Display alerts in verbose output.

=item B<--warning-*> B<--critical-*> 

Thresholds.
Can be: 'total', 'acknowledged', 'unacknowledged'.

=back

=cut
