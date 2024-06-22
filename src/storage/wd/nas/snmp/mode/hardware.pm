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

package storage::wd::nas::snmp::mode::hardware;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_fan_output {
    my ($self, %options) = @_;

    return "fan '" . $options{instance} . "' ";
}

sub prefix_drive_output {
    my ($self, %options) = @_;

    return "drive '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'fans', type => 1, cb_prefix_output => 'prefix_fan_output', skipped_code => { -10 => 1 } },
        { name => 'drives', type => 1, cb_prefix_output => 'prefix_drive_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'system-temperature', nlabel => 'hardware.temperature.celsius', set => {
                key_values => [ { name => 'temperature' } ],
                output_template => 'system temperature: %s C',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'C',
                        instances => 'system',
                        value => $self->{result_values}->{temperature},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
                    );
                }
            }
        }
    ];

    $self->{maps_counters}->{fans} = [
        { label => 'fan-status', type => 2, critical_default => '%{status} ne "running"', set => {
                key_values => [ { name => 'status' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{drives} = [
        { label => 'drive-temperature', nlabel => 'hardware.temperature.celsius', set => {
                key_values => [ { name => 'temperature' }, { name => 'serial' } ],
                output_template => 'temperature: %s C',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'C',
                        instances => 'drive:' . $self->{result_values}->{serial},
                        value => $self->{result_values}->{temperature},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
                    );
                }
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

    my $nas = {
        ex2 => {
            system => {
                temperature => { oid => '.1.3.6.1.4.1.5127.1.1.1.2.1.7' },
                fanStatus => { oid => '.1.3.6.1.4.1.5127.1.1.1.2.1.8' }
            },
            drive => {
                serial => { oid => '.1.3.6.1.4.1.5127.1.1.1.2.1.10.1.4' },
                temperature => { oid => '.1.3.6.1.4.1.5127.1.1.1.2.1.10.1.5' }
            },
            driveTable => '.1.3.6.1.4.1.5127.1.1.1.2.1.10.1'
        },
        ex2ultra => {
            system => {
                temperature => { oid => '.1.3.6.1.4.1.5127.1.1.1.8.1.7' },
                fanStatus => { oid => '.1.3.6.1.4.1.5127.1.1.1.8.1.8' }
            },
            drive => {
                serial => { oid => '.1.3.6.1.4.1.5127.1.1.1.8.1.10.1.4' },
                temperature => { oid => '.1.3.6.1.4.1.5127.1.1.1.8.1.10.1.5' }
            },
            driveTable => '.1.3.6.1.4.1.5127.1.1.1.8.1.10.1'
        },
        ex4100 => {
            system => {
                temperature => { oid => '.1.3.6.1.4.1.5127.1.1.1.6.1.7' },
                fanStatus => { oid => '.1.3.6.1.4.1.5127.1.1.1.6.1.8' }
            },
            drive => {
                serial => { oid => '.1.3.6.1.4.1.5127.1.1.1.6.1.10.1.4' },
                temperature => { oid => '.1.3.6.1.4.1.5127.1.1.1.6.1.10.1.5' }
            },
            driveTable => '.1.3.6.1.4.1.5127.1.1.1.6.1.10.1'
        },
        pr2100 => {
            system => {
                temperature => { oid => '.1.3.6.1.4.1.5127.1.1.1.9.1.7' },
                fanStatus => { oid => '.1.3.6.1.4.1.5127.1.1.1.9.1.8' }
            },
            drive => {
                serial => { oid => '.1.3.6.1.4.1.5127.1.1.1.9.1.10.1.4' },
                temperature => { oid => '.1.3.6.1.4.1.5127.1.1.1.9.1.10.1.5' }
            },
            driveTable => '.1.3.6.1.4.1.5127.1.1.1.9.1.10.1'
        },
        pr4100 => {
            system => {
                temperature => { oid => '.1.3.6.1.4.1.5127.1.1.1.10.1.7' },
                fanStatus => { oid => '.1.3.6.1.4.1.5127.1.1.1.10.1.8' }
            },
            drive => {
                serial => { oid => '.1.3.6.1.4.1.5127.1.1.1.10.1.10.1.4' },
                temperature => { oid => '.1.3.6.1.4.1.5127.1.1.1.10.1.10.1.5' }
            },
            driveTable => '.1.3.6.1.4.1.5127.1.1.1.10.1.10.1'
        }
    };

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map({ $nas->{$_}->{system}->{temperature}->{oid} . '.0', $nas->{$_}->{system}->{fanStatus}->{oid} . '.0' } keys(%$nas)) ],
        nothing_quit => 1
    );

    $self->{global} = {};
    $self->{fans} = {};
    $self->{drives} = {};
    foreach my $type (keys %$nas) {
        next if (!defined($snmp_result->{ $nas->{$type}->{system}->{temperature}->{oid} . '.0' }));

        my $result = $options{snmp}->map_instance(mapping => $nas->{$type}->{system}, results => $snmp_result, instance => 0);

        $self->{global}->{temperature} = $1 if ($result->{temperature} =~ /Centigrade:(\d+)/i);
        while ($result->{fanStatus} =~ /fan(\d+):\s*(\S+)/g) {
            $self->{fans}->{$1} = { status => $2 };
        }

        $snmp_result = $options{snmp}->get_table(
            oid => $nas->{$type}->{driveTable},
            start => $nas->{$type}->{drive}->{serial}->{oid},
            end => $nas->{$type}->{drive}->{temperature}->{oid}
        );

        foreach (keys %$snmp_result) {
            next if (! /^$nas->{$type}->{drive}->{serial}->{oid}\.(\d+)$/);
            $result = $options{snmp}->map_instance(mapping => $nas->{$type}->{drive}, results => $snmp_result, instance => $1);
            $self->{drives}->{ $result->{serial} } = { serial => $result->{serial} };
            $self->{drives}->{ $result->{serial} }->{temperature} = $1 if ($result->{temperature} =~ /Centigrade:(\d+)/i);
        }
    }
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--warning-fan-status>

Define the conditions to match for the status to be WARNING (default : '%{status} ne "running"').
You can use the following variables: %{status}

=item B<--critical-fan-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{status}

=item B<--warning-*> B<--critical-*>

Thresholds. Can be:
'system-temperature', 'drive-temperature'.

=back

=cut
