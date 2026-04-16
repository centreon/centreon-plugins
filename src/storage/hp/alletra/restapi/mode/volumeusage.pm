#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package storage::hp::alletra::restapi::mode::volumeusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(
        value => $self->{result_values}->{total}
    );
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(
        value => $self->{result_values}->{used}
    );
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(
        value => $self->{result_values}->{free}
    );
    my ($reserved_value, $reserved_unit) = $self->{perfdata}->change_bytes(
        value => $self->{result_values}->{reserved}
    );

    return sprintf(
        "Total: %s Reserved: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $reserved_value . " " . $reserved_unit,
        $used_value . " " . $used_unit,
        $self->{result_values}->{prct_used},
        $free_value . " " . $free_unit,
        $self->{result_values}->{prct_free},
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'volume',
            type             => 1,
            cb_prefix_output => 'prefix_volume_output',
            message_multiple => 'All volumes are ok'
        },
    ];

    $self->{maps_counters}->{volume} = [
        {
            label  => 'usage',
            nlabel => 'volume.space.usage.bytes',
            set    => {
                key_values            =>
                    [
                        { name => 'used' },
                        { name => 'free' },
                        { name => 'prct_used' },
                        { name => 'prct_free' },
                        { name => 'total' },
                        { name => 'reserved' },
                        { name => 'name' },
                        { name => 'id' }
                    ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas             => [
                    {
                        template             => '%d',
                        min                  => 0,
                        max                  => 'total',
                        unit                 => 'B',
                        cast_int             => 1,
                        label_extra_instance => 1,
                        instance_use         => 'name'
                    }
                ]
            }
        },
        {
            label      => 'usage-free',
            display_ok => 0,
            nlabel     => 'volume.space.free.bytes',
            set        => {
                key_values            =>
                    [
                        { name => 'free' },
                        { name => 'used' },
                        { name => 'prct_used' },
                        { name => 'prct_free' },
                        { name => 'total' },
                        { name => 'reserved' },
                        { name => 'name' },
                        { name => 'id' }
                    ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas             =>
                    [
                        {
                            template             => '%d',
                            min                  => 0,
                            max                  => 'total',
                            unit                 => 'B',
                            cast_int             => 1,
                            label_extra_instance => 1,
                            instance_use         => 'name'
                        }
                    ]
            }
        },
        {
            label      => 'usage-prct',
            display_ok => 0,
            nlabel     => 'volume.space.usage.percentage',
            set        => {
                key_values      => [ { name => 'prct_used' }, { name => 'name' }, { name => 'id' } ],
                output_template => 'Used : %.2f %%',
                perfdatas       => [
                    {
                        template             => '%.2f',
                        min                  => 0,
                        max                  => 100,
                        unit                 => '%',
                        label_extra_instance => 1,
                        instance_use         => 'name'
                    }
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
            'filter-id:s'   => { name => 'filter_id' },
            'filter-name:s' => { name => 'filter_name' }
        });

    return $self;
}

sub prefix_volume_output {
    my ($self, %options) = @_;

    return "Volume '" . $options{instance_value}->{name} . "' (#" . $options{instance_value}->{id} . ") ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->request_api(endpoint => '/api/v1/volumes');
    my $volumes = $response->{members};
    $self->{volume} = {};

    for my $volume (@{$volumes}) {
        my $name = $volume->{name};
        my $id = $volume->{id};

        if (defined($self->{option_results}->{filter_name}) and $self->{option_results}->{filter_name} ne '' and
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(
                long_msg =>
                    "Skipping volume named '" . $name . "': not matching filter /" . $self->{option_results}->{filter_name} . "/.",
                debug    =>
                    1
            );
            next;
        }
        if (defined($self->{option_results}->{filter_id}) and $self->{option_results}->{filter_id} ne '' and
            $id !~ /$self->{option_results}->{filter_id}/) {
            $self->{output}->output_add(
                long_msg =>
                    "Skipping volume #" . $id . ": not matching filter /" . $self->{option_results}->{filter_id} . "/.",
                debug    => 1
            );
            next;
        }

        my $total = $volume->{sizeMiB} * 1024 * 1024;
        my $reserved = $volume->{totalReservedMiB} * 1024 * 1024;
        my $used = $volume->{totalUsedMiB} * 1024 * 1024;
        my $free = ($total - $used) >= 0 ? ($total - $used) : 0;

        $self->{volume}->{$name} = {
            id        => $id,
            name      => $name,
            total     => $total,
            reserved  => $reserved,
            used      => $used,
            free      => $free,
            prct_used => $used * 100 / $total,
            prct_free => $free * 100 / $total
        };
    }

    if (scalar(keys %{$self->{volume}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No volume found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check volume usage.

=over 8

=item B<--filter-counters>

Define which counters (filtered by regular expression) should be monitored.
Can be : usage usage-free usage-prct
Example: --filter-counters='^usage$'

=item B<--filter-id>

Define which volumes should be monitored based on their IDs.
This option will be treated as a regular expression.

=item B<--filter-name>

Define which volumes should be monitored based on the volume names.
This option will be treated as a regular expression.

=back

=head2 Thresholds for volume usage metrics

=over 8

=item B<--warning-usage>

Threshold in bytes.

=item B<--critical-usage>

Threshold in bytes.

=item B<--warning-usage-free>

Threshold in bytes.

=item B<--critical-usage-free>

Threshold in bytes.

=item B<--warning-usage-prct>

Threshold in percentage.

=item B<--critical-usage-prct>

Threshold in percentage.

=back

=cut
