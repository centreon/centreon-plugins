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

package network::backbox::rest::mode::configstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'config', type => 0 },
    ];

    $self->{maps_counters}->{config} = [
        { label => 'identical', nlabel => 'config.identical.count', set => {
            key_values      => [ { name => 'identical' } ],
            output_template => 'identical: %d',
            perfdatas       => [
                { value => 'identical', template => '%d', min => 0 }
            ]
        }
        },
        { label => 'changed', nlabel => 'config.changed.count', set => {
            key_values      => [ { name => 'changed' } ],
            output_template => 'changed: %d',
            perfdatas       => [
                { value => 'changed', template => '%d', min => 0 }
            ]
        }
        },
        { label => 'na', nlabel => 'config.na.count', set => {
            key_values      => [ { name => 'na' } ],
            output_template => 'n/a: %d',
            perfdatas       => [
                { value => 'na', template => '%d', min => 0 }
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
        'filter-type:s' => { name => 'filter_type' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $config = $options{custom}->get_config_status();
    $self->{config} = {
        identical => $config->{identical},
        changed   => $config->{changed},
        na        => $config->{na}
    };
}
1;

__END__

=head1 MODE

Check Backbox configs status.

=over 8

=item B<--filter-type>

Filter configs by type.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'identical', 'changed', 'na'.

=back

=cut
