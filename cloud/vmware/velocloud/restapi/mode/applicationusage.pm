#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package cloud::vmware::velocloud::restapi::mode::applicationusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'edges', type => 3, cb_prefix_output => 'prefix_edge_output', cb_long_output => 'long_output',
          message_multiple => 'All edges applications usage are ok', indent_long_output => '    ',
            group => [
                { name => 'apps', display_long => 1, cb_prefix_output => 'prefix_app_output',
                  message_multiple => 'All applications usage are ok', type => 1 },
            ]
        }
    ];

    $self->{maps_counters}->{apps} = [
        { label => 'traffic-in', nlabel => 'application.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in' }, { name => 'display' }, { name => 'id' } ],
                output_change_bytes => 2,
                output_template => 'Traffic In: %s %s/s',
                perfdatas => [
                    { value => 'traffic_in_absolute', template => '%s',
                      min => 0, unit => 'b/s', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'traffic-out', nlabel => 'application.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out' }, { name => 'display' }, { name => 'id' } ],
                output_change_bytes => 2,
                output_template => 'Traffic Out: %s %s/s',
                perfdatas => [
                    { value => 'traffic_out_absolute', template => '%s',
                      min => 0, unit => 'b/s', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'packets-in', nlabel => 'application.packets.in.persecond', set => {
                key_values => [ { name => 'packets_in' }, { name => 'display' }, { name => 'id' } ],
                output_template => 'Packets In: %.2f packets/s',
                perfdatas => [
                    { value => 'packets_in_absolute', template => '%.2f',
                      min => 0, unit => 'packets/s', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'packets-out', nlabel => 'application.packets.out.persecond', set => {
                key_values => [ { name => 'packets_out' }, { name => 'display' }, { name => 'id' } ],
                output_template => 'Packets Out: %.2f packets/s',
                perfdatas => [
                    { value => 'packets_out_absolute', template => '%.2f',
                      min => 0, unit => 'packets/s', label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub prefix_edge_output {
    my ($self, %options) = @_;

    return "Edge '" . $options{instance_value}->{display} . "' ";
}

sub prefix_app_output {
    my ($self, %options) = @_;
    
    return "Application '" . $options{instance_value}->{display} . "' [Id: " . $options{instance_value}->{id} . "] ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking edge '" . $options{instance_value}->{display} . "' [Id: " . $options{instance_value}->{id} . "] ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-edge-name:s"        => { name => 'filter_edge_name' },
        "filter-application-name:s" => { name => 'filter_application_name' },
        "warning-status:s"          => { name => 'warning_status', default => '' },
        "critical-status:s"         => { name => 'critical_status', default => '' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{edges} = {};

    my $results = $options{custom}->list_edges;

    foreach my $edge (@{$results}) {
        if (defined($self->{option_results}->{filter_edge_name}) && $self->{option_results}->{filter_edge_name} ne '' &&
            $edge->{name} !~ /$self->{option_results}->{filter_edge_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $edge->{name} . "'.", debug => 1);
            next;
        }

        $self->{edges}->{$edge->{name}}->{id} = $edge->{id};
        $self->{edges}->{$edge->{name}}->{display} = $edge->{name};

        my $apps = $options{custom}->get_apps_metrics(
            edge_id => $edge->{id},
            timeframe => $self->{timeframe}
        );

        foreach my $app (@{$apps}) {
            if (defined($self->{option_results}->{filter_application_name}) &&
                $self->{option_results}->{filter_application_name} ne '' &&
                $app->{name} !~ /$self->{option_results}->{filter_application_name}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $edge->{id} . "'.", debug => 1);
                next;
            }

            $self->{edges}->{$edge->{name}}->{apps}->{$app->{name}} = {
                id => $app->{application},
                display => $app->{name},
                traffic_out => int($app->{bytesTx} * 8 / $self->{timeframe}),
                traffic_in => int($app->{bytesRx} * 8 / $self->{timeframe}),
                packets_out => $app->{packetsTx} / $self->{timeframe},
                packets_in => $app->{packetsRx} / $self->{timeframe},
            };
        }
    }

    if (scalar(keys %{$self->{edges}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No edge found.");
        $self->{output}->option_exit();
    }
    foreach (keys %{$self->{edges}}) {
        last if (defined($self->{edges}->{$_}->{apps}));
        $self->{output}->add_option_msg(short_msg => "No applications found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check applications usage per edges.

=over 8

=item B<--filter-edge-name>

Filter edge by name (Can be a regexp).

=item B<--filter-application-name>

Filter application by name (Can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'traffic-in', 'traffic-out',
'packets-in', 'packets-out'.

=item B<--critical-*>

Threshold critical.
Can be: 'traffic-in', 'traffic-out',
'packets-in', 'packets-out'.

=back

=cut
