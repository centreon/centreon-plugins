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

package apps::scalecomputing::restapi::mode::vdomainblockdevusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use JSON::PP;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_disk_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value =>
        $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value =>
        $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value =>
        $self->{result_values}->{free});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub prefix_disk_output {
    my ($self, %options) = @_;

    my $output = "Virtual domain block device ($options{instance_value}->{type}) '"
        . $options{instance_value}->{display} . "' ";

    if (defined($options{instance_value}->{vir_domain_name})) {
        $output .= "of virtual domain '" . $options{instance_value}->{vir_domain_name} . "' ";
    }

    return $output;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'devs',
            type             => 1,
            cb_prefix_output => 'prefix_disk_output',
            message_multiple => 'All virtual disks are ok'
        }
    ];

    $self->{maps_counters}->{devs} = [
        {
            label  => 'usage',
            nlabel => 'vdisk.usage.bytes',
            set    => {
                key_values            =>
                    [
                        { name => 'used' },
                        { name => 'free' },
                        { name => 'prct_used' },
                        { name => 'prct_free' },
                        { name => 'total' }
                    ],
                closure_custom_output => $self->can('custom_disk_usage_output'),
                perfdatas             =>
                    [
                        {
                            template             => '%d',
                            min                  => 0,
                            max                  => 'total',
                            unit                 => 'B',
                            cast_int             => 1,
                            label_extra_instance => 1
                        }
                    ]
            }
        },
        {
            label      => 'usage-free',
            nlabel     => 'vdisk.space.free.bytes',
            display_ok => 0,
            set        => {
                key_values            =>
                    [
                        { name => 'free' },
                        { name => 'used' },
                        { name => 'prct_used' },
                        { name => 'prct_free' },
                        { name => 'total' }
                    ],
                closure_custom_output => $self->can('custom_disk_usage_output'),
                perfdatas             =>
                    [
                        {
                            template             => '%d',
                            min                  => 0,
                            max                  => 'total_space',
                            unit                 => 'B',
                            cast_int             => 1,
                            label_extra_instance => 1
                        }
                    ]
            }
        },
        {
            label      => 'usage-prct',
            nlabel     => 'vdisk.usage.percentage',
            display_ok => 0,
            set        => {
                key_values            =>
                    [
                        { name => 'prct_used' },
                        { name => 'used' },
                        { name => 'free' },
                        { name => 'prct_free' },
                        { name => 'total' }
                    ],
                closure_custom_output => $self->can('custom_disk_usage_output'),
                perfdatas             =>
                    [
                        { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                    ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'uuid:s'   => { name => 'uuid' },
            'use-name' => { name => 'use_name' }
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{drives} = {};

    my $devs = $options{custom}->list_virtual_domain_block_devices();
    $self->{vdomains} = $options{custom}->list_virtual_domains();
    $self->{vdomain_names} = {};

    foreach my $vdomain (@{$self->{vdomains}}) {
        $self->{vdomain_names}->{$vdomain->{uuid}} = $vdomain->{name};
    }

    foreach my $dev (@{$devs}) {
        if (defined($self->{option_results}->{uuid}) && $self->{option_results}->{uuid} ne '' &&
            $dev->{uuid} !~ /$self->{option_results}->{uuid}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $dev->{uuid} . "'.", debug => 1);
            next;
        }

        push @{$self->{filtered_devs}}, $dev;
    }

    for my $dev (@{$self->{filtered_devs}}) {
        my $total = $dev->{capacity};
        my $used = $dev->{allocation};
        my $free = $total - $used;

        # add the instance
        $self->{devs}->{ defined($self->{option_results}->{use_name}) && length($dev->{name}) > 0 ?
            $dev->{name} : $dev->{uuid} } = {
            display         => defined($self->{option_results}->{use_name}) && length($dev->{name}) > 0 ?
                $dev->{name} : $dev->{uuid},
            uuid            => $dev->{uuid},
            name            => $dev->{name},
            type            => $dev->{type},
            vir_domain_name => defined($self->{vdomain_names}->{$dev->{virDomainUUID}}) ?
                $self->{vdomain_names}->{$dev->{virDomainUUID}} :
                "",
            total           => $total,
            used            => $used,
            free            => $free,
            prct_used       => $total > 0 ? $used * 100 / $total : 0,
            prct_free       => $total > 0 ? $free * 100 / $total : 0
        };
    }

    if (scalar(keys %{$self->{devs}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No drive found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check virtual disk usage.

=over 8

=item B<--uuid>

Gets virtual domains by uuid.

=item B<--use-name>

Use cluster name for perfdata and display.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%)

=back

=cut
