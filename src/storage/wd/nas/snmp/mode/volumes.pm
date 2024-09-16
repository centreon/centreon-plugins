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

package storage::wd::nas::snmp::mode::volumes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        "space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub prefix_volume_output {
    my ($self, %options) = @_;

    return sprintf(
        "volume '%s' ",
        $options{instance_value}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'volumes', type => 1, cb_prefix_output => 'prefix_volume_output', message_multiple => 'All volumes are ok' }
    ];

    $self->{maps_counters}->{volumes} = [
         { label => 'space-usage', nlabel => 'volume.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'space-usage-free', display_ok => 0, nlabel => 'volume.space.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'space-usage-prct', display_ok => 0, nlabel => 'volume.space.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'name' }
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
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $nas = {
        ex2 => {
            volumeTable => '.1.3.6.1.4.1.5127.1.1.1.2.1.9.1',
            volume => {
                name  => { oid => '.1.3.6.1.4.1.5127.1.1.1.2.1.9.1.2' },
                total => { oid => '.1.3.6.1.4.1.5127.1.1.1.2.1.9.1.5' },
                free  => { oid => '.1.3.6.1.4.1.5127.1.1.1.2.1.9.1.6' }
            }
        },
        ex2ultra => {
            volumeTable => '.1.3.6.1.4.1.5127.1.1.1.8.1.9.1',
            volume => {
                name  => { oid => '.1.3.6.1.4.1.5127.1.1.1.8.1.9.1.2' },
                total => { oid => '.1.3.6.1.4.1.5127.1.1.1.8.1.9.1.5' },
                free  => { oid => '.1.3.6.1.4.1.5127.1.1.1.8.1.9.1.6' }
            }
        },
        ex4100 => {
            volumeTable => '.1.3.6.1.4.1.5127.1.1.1.6.1.9.1',
            volume => {
                name  => { oid => '.1.3.6.1.4.1.5127.1.1.1.6.1.9.1.2' },
                total => { oid => '.1.3.6.1.4.1.5127.1.1.1.6.1.9.1.5' },
                free  => { oid => '.1.3.6.1.4.1.5127.1.1.1.6.1.9.1.6' }
            }
        },
        pr2100 => {
            volumeTable => '.1.3.6.1.4.1.5127.1.1.1.9.1.9.1',
            volume => {
                name  => { oid => '.1.3.6.1.4.1.5127.1.1.1.9.1.9.1.2' },
                total => { oid => '.1.3.6.1.4.1.5127.1.1.1.9.1.9.1.5' },
                free  => { oid => '.1.3.6.1.4.1.5127.1.1.1.9.1.9.1.6' }
            }
        },
        pr4100 => {
            volumeTable => '.1.3.6.1.4.1.5127.1.1.1.10.1.9.1',
            volume => {
                name  => { oid => '.1.3.6.1.4.1.5127.1.1.1.10.1.9.1.2' },
                total => { oid => '.1.3.6.1.4.1.5127.1.1.1.10.1.9.1.5' },
                free  => { oid => '.1.3.6.1.4.1.5127.1.1.1.10.1.9.1.6' }
            }
        }
    };

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $nas->{ex2}->{volumeTable} },
            { oid => $nas->{ex2ultra}->{volumeTable} },
            { oid => $nas->{ex4100}->{volumeTable} },
            { oid => $nas->{pr2100}->{volumeTable} },
            { oid => $nas->{pr4100}->{volumeTable} }
        ],
        nothing_quit => 1
    );

    $self->{volumes} = {};
    foreach my $type (keys %$nas) {
        next if (scalar(keys %{$snmp_result->{ $nas->{$type}->{volumeTable} }}) <= 0);

        foreach (keys %{$snmp_result->{ $nas->{$type}->{volumeTable} }}) {
            next if (! /^$nas->{$type}->{volume}->{name}->{oid}\.(\d+)$/);

            my $result = $options{snmp}->map_instance(mapping => $nas->{$type}->{volume}, results => $snmp_result->{ $nas->{$type}->{volumeTable} }, instance => $1);
            next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $result->{name} !~ /$self->{option_results}->{filter_name}/);

            $result->{total} =~ /^([0-9\.]+)\s*(\S+)/;
            $result->{total} = centreon::plugins::misc::convert_bytes(value => $1, unit => $2 . 'B');

            $result->{free} =~ /^([0-9\.]+)\s*(\S+)/;
            $result->{free} = centreon::plugins::misc::convert_bytes(value => $1, unit => $2 . 'B');

            $self->{volumes}->{ $result->{name} } = {
                name => $result->{name},
                total => $result->{total},
                free => $result->{free},
                used => $result->{total} - $result->{free},
                prct_used => ($result->{total} - $result->{free}) * 100 / $result->{total},
                prct_free => $result->{free} * 100 / $result->{total}
            };
        }
    }
}

1;

__END__

=head1 MODE

Check volumes.

=over 8

=item B<--filter-name>

Filter volumes by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage-prct', 'space-usage', 'space-usage-free'.

=back

=cut
