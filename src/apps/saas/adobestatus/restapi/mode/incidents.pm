#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::saas::adobestatus::restapi::mode::incidents;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc qw/is_excluded/;
use centreon::plugins::constants qw(:counters :values);

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of products ';
}

sub prefix_product_output {
    my ($self, %options) = @_;

    return "Product '" . $options{instance_value}->{productName} . "' number of current incidents ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        { name => 'products', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_product_output', message_multiple => 'All products are ok' }
    ];

    $self->{maps_counters}->{global} = [
        {   label => 'products-detected', display_ok => 0, nlabel => 'products.detected.count',
            unknown_default => '@0',
            set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{products} = [
        { label => 'product-incidents-major', nlabel => 'product.incidents.major.count', set => {
                key_values => [ { name => 'major' }, { name => 'productName' } ],
                output_template => 'major: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'productName' }
                ]
            }
        },
        { label => 'product-incidents-minor', nlabel => 'product.incidents.minor.count', set => {
                key_values => [ { name => 'minor' }, { name => 'productName' } ],
                output_template => 'minor: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'productName' }
                ]
            }
        },
        { label => 'product-incidents-potential', nlabel => 'product.incidents.potential.count', set => {
                key_values => [ { name => 'potential' }, { name => 'productName' } ],
                output_template => 'potential: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'productName' }
                ]
            }
        },
        { label => 'product-incidents-trivial', nlabel => 'product.incidents.trivial.count', set => {
                key_values => [ { name => 'trivial' }, { name => 'productName' } ],
                output_template => 'trivial: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'productName' }
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
       'filter-product-id:s'   => { name => 'filter_product_id', default => '' },
       'filter-product-name:s' => { name => 'filter_product_name', default => '' },
       'display-incidents'     => { name => 'display_incidents' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { detected => 0 };
    $self->{products} = {};
    my $products = $options{custom}->get_products();
    foreach my $id (keys %$products) {
        next if is_excluded($id, $self->{option_results}->{filter_product_id});
        next if is_excluded($products->{$id}, $self->{option_results}->{filter_product_name});

        $self->{global}->{detected}++;
        $self->{products}->{$id} = {
            productName => $products->{$id},
            minor => 0,
            major => 0,
            trivial => 0,
            potential => 0
        };
    }

    my $incidents = $options{custom}->get_incidents();
    foreach my $id (keys %$incidents) {
        next if (!defined($self->{products}->{$id}));

        foreach my $incident (@{$incidents->{$id}}) {
            $self->{products}->{$id}->{ lc($incident->{severity}) }++;
            if (defined($self->{option_results}->{display_incidents})) {
                $self->{output}->output_add(
                    long_msg => sprintf(
                        "incident '%s' [severity: %s] [customerImpact: %s]: %s",
                        $self->{products}->{$id}->{productName},
                        $incident->{severity},
                        $incident->{customerImpact},
                        scalar(localtime($incident->{statusTime}))
                    )
                );
            }
        }
    }
}

1;

__END__

=head1 MODE

Check current incidents.

=over 8

=item B<--filter-product-id>

Filter products by ID (can be a regexp).

=item B<--filter-product-name>

Filter product by name (can be a regexp).

=item B<--display-incidents>

Display incidents in verbose output.

=item B<--warning-products-detected>

Threshold.

=item B<--critical-products-detected>

Threshold.

=item B<--warning-product-incidents-major>

Threshold.

=item B<--critical-product-incidents-major>

Threshold.

=item B<--warning-product-incidents-minor>

Threshold.

=item B<--critical-product-incidents-minor>

Threshold.

=item B<--warning-product-incidents-potential>

Threshold.

=item B<--critical-product-incidents-potential>

Threshold.

=item B<--warning-product-incidents-trivial>

Threshold.

=item B<--critical-product-incidents-trivial>

Threshold.

=back

=cut
