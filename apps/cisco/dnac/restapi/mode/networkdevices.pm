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

package apps::cisco::dnac::restapi::mode::networkdevices;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_health_output {
    my ($self, %options) = @_;

    return sprintf(
        '%.2f%% (%s on %s)',
        $self->{result_values}->{prct},
        $self->{result_values}->{count},
        $self->{result_values}->{total}
    );
}

sub category_long_output {
    my ($self, %options) = @_;

    return "checking network category '" . $options{instance_value}->{name} . "'";
}

sub prefix_category_output {
    my ($self, %options) = @_;

    return "Network category '" . $options{instance_value}->{name} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Network devices ';
}

sub prefix_good_output {
    my ($self, %options) = @_;

    return 'good devices: ';
}

sub prefix_fair_output {
    my ($self, %options) = @_;

    return 'fair devices: ';
}

sub prefix_bad_output {
    my ($self, %options) = @_;

    return 'bad devices: ';
}

sub prefix_unmonitored_output {
    my ($self, %options) = @_;

    return 'unmonitored devices: ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'categories', type => 3, cb_prefix_output => 'prefix_categorie_output', cb_long_output => 'category_long_output', indent_long_output => '    ', message_multiple => 'All network categories are ok',
            group => [
                { name => 'good', type => 0, cb_prefix_output => 'prefix_good_output', skipped_code => { -10 => 1 } },
                { name => 'fair', type => 0, cb_prefix_output => 'prefix_fair_output', skipped_code => { -10 => 1 } },
                { name => 'bad', type => 0, cb_prefix_output => 'prefix_bad_output', skipped_code => { -10 => 1 } },
                { name => 'unmonitored', type => 0, cb_prefix_output => 'prefix_unmonitored_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'devices-total', nlabel => 'network.devices.total.count', display_ok => 0, set => {
                key_values => [ { name => 'devices_total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    foreach (('good', 'fair', 'bad', 'unmonitored')) {
        $self->{maps_counters}->{$_} = [
            { label => 'category-devices-health-' . $_ . '-usage', nlabel => 'category.network.devices.health.' . $_ . '.count', set => {
                    key_values => [ { name => 'count' }, { name => 'prct' }, { name => 'total' } ],
                    closure_custom_output => $self->can('custom_health_output'),
                    perfdatas => [
                        { template => '%d', min => 0, max => 'total',  label_extra_instance => 1 }
                    ]
                }
            },
            { label => 'category-devices-health-' . $_ . '-usage-prct', nlabel => 'category.network.devices.health.' . $_ . '.percentage', display_ok => 0, set => {
                    key_values => [ { name => 'count' }, { name => 'prct' }, { name => 'total' } ],
                    closure_custom_output => $self->can('custom_health_output'),
                    perfdatas => [
                        { template => '%.2f', min => 0, max => 100, label_extra_instance => 1 }
                    ]
                }
            }
        ];
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-category-name:s' => { name => 'filter_category_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $networks = $options{custom}->request_api(
        endpoint => '/network-health'
    );

    $self->{global} = { devices_total => 0 };
    $self->{categories} = {};

    foreach (@{$networks->{healthDistirubution}}) {
        if (defined($self->{option_results}->{filter_category_name}) && $self->{option_results}->{filter_category_name} ne '' &&
            $_->{category} !~ /$self->{option_results}->{filter_category_name}/) {
            $self->{output}->output_add(long_msg => "skipping category '" . $_->{category} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{categories}->{ $_->{category} } = {
            name => $_->{category},
            good => {
                name => $_->{category},
                total => $_->{totalCount},
                count => $_->{goodCount},
                prct => $_->{goodCount} * 100 / $_->{totalCount}
            },
            fair => {
                name => $_->{category},
                total => $_->{totalCount},
                count => $_->{fairCount},
                prct => $_->{fairCount} * 100 / $_->{totalCount}
            },
            bad => {
                name => $_->{category},
                total => $_->{totalCount},
                count => $_->{badCount},
                prct => $_->{badCount} * 100 / $_->{totalCount}
            },
            unmonitored => {
                name => $_->{category},
                total => $_->{totalCount},
                count => $_->{unmonCount},
                prct => $_->{unmonCount} * 100 / $_->{totalCount}
            }
        };

        $self->{global}->{devices_total} += $_->{totalCount};
    }
}

1;

__END__

=head1 MODE

Check network devices by categories.

=over 8

=item B<--filter-category-name>

Filter categories by name (Can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'category-devices-health-good-usage', 'category-devices-health-good-usage-prct',
'category-devices-health-unmonitored-usage', 'category-devices-health-unmonitored-usage-prct', 
'category-devices-health-fair-usage', 'category-devices-health-fair-usage-prct',
'category-devices-health-bad-usage', 'category-devices-health-bad-usage-prct', 
'devices-total'.

=back

=cut
