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

package apps::ceph::restapi::mode::osd;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_online_output {
    my ($self, %options) = @_;

    return sprintf(
        'online %.2f%% (%s on %s)',
        $self->{result_values}->{online_prct},
        $self->{result_values}->{online},
        $self->{result_values}->{detected}
    );
}

sub custom_participating_output {
    my ($self, %options) = @_;

    return sprintf(
        'participating %.2f%% (%s on %s)',
        $self->{result_values}->{participating_prct},
        $self->{result_values}->{participating},
        $self->{result_values}->{detected}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of osd ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'osd-detected', nlabel => 'osd.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'osd-online', nlabel => 'osd.online.count', set => {
                key_values => [ { name => 'online' }, { name => 'online_prct' }, { name => 'detected' } ],
                closure_custom_output => $self->can('custom_online_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'detected' }
                ]
            }
        },
        { label => 'osd-online-prct', nlabel => 'osd.online.percentage', display_ok => 0, set => {
                key_values => [ { name => 'online_prct' }, { name => 'online' }, { name => 'detected' } ],
                closure_custom_output => $self->can('custom_online_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'osd-participating', nlabel => 'osd.participating.count', set => {
                key_values => [ { name => 'participating' }, { name => 'participating_prct' }, { name => 'detected' } ],
                closure_custom_output => $self->can('custom_participating_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'detected' }
                ]
            }
        },
        { label => 'osd-participating-prct', nlabel => 'osd.participating.percentage', display_ok => 0, set => {
                key_values => [ { name => 'participating_prct' }, { name => 'participating' }, { name => 'detected' } ],
                closure_custom_output => $self->can('custom_participating_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $health = $options{custom}->request_api(endpoint => '/api/health/full');

    $self->{global} = { detected => 0, online => 0, participating => 0 };
    foreach my $osd (@{$health->{osd_map}->{osds}}) {
        $self->{global}->{detected}++;

        $self->{global}->{participating}++ if ($osd->{in} == 1);
        $self->{global}->{online}++ if ($osd->{up} == 1);
    }

    if ($self->{global}->{detected} > 0) {
        $self->{global}->{participating_prct} = $self->{global}->{participating} * 100 / $self->{global}->{detected};
        $self->{global}->{online_prct} = $self->{global}->{online} * 100 / $self->{global}->{detected};
    }
}

1;

__END__

=head1 MODE

Check object storage daemons.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='detected'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'osd-detected',
'osd-online', 'osd-online-prct',
'osd-participating', 'osd-participating-prct'.

=back

=cut
