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

package storage::hp::3par::ssh::mode::psu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub psu_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking node '%s' power supply '%s'",
        $options{instance_value}->{node_id},
        $options{instance_value}->{psu_id}
    );
}

sub prefix_psu_output {
    my ($self, %options) = @_;

    return sprintf(
        "node '%s' power supply '%s' ",
        $options{instance_value}->{node_id},
        $options{instance_value}->{psu_id}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'psu', type => 3, cb_prefix_output => 'prefix_psu_output', cb_long_output => 'psu_long_output', indent_long_output => '    ', message_multiple => 'All power supplies are ok',
            group => [
                { name => 'global', type => 0 },
                { name => 'ac', type => 0 },
                { name => 'dc', type => 0 },
                { name => 'fan', type => 0 },
                { name => 'battery', type => 0 }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{status} !~ /ok/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'node_id' }, { name => 'psu_id' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    foreach ('ac', 'dc', 'fan', 'battery') {
        $self->{maps_counters}->{$_} = [
            {
                label => $_ . '-status',
                type => 2,
                critical_default => '%{status} !~ /ok/i',
                set => {
                    key_values => [ { name => 'status' }, { name => 'node_id' }, { name => 'psu_id' } ],
                    output_template => $_ . ' status: %s',
                    closure_custom_perfdata => sub { return 0; },
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
            }
        ];
    }

    push @{$self->{maps_counters}->{battery}}, 
        { label => 'charge-remaining', nlabel => 'battery.charge.remaining.percent', set => {
                key_values => [ { name => 'capacity' }, { name => 'node_id' }, { name => 'psu_id' } ],
                output_template => 'remaining capacity: %.2f %%',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => '%',
                        instances => ['node' . $self->{result_values}->{node_id}, 'psu' . $self->{result_values}->{psu_id}],
                        value => sprintf('%.2f', $self->{result_values}->{capacity}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0, max => 100
                    );
                }
            }
        },
        { label => 'charge-remaining-minutes', nlabel => 'battery.charge.remaining.minutes', set => {
                key_values => [ { name => 'time' }, { name => 'node_id' }, { name => 'psu_id' } ],
                output_template => 'remaining time: %s minutes',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'm',
                        instances => ['node' . $self->{result_values}->{node_id}, 'psu' . $self->{result_values}->{psu_id}],
                        value => sprintf('%s', $self->{result_values}->{time}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        };
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-node-id:s' => { name => 'filter_node_id' },
        'filter-psu-id:s'  => { name => 'filter_psu_id' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($content) = $options{custom}->execute_command(commands => ['shownode -ps -verbose']);
    #---------------Node 0 PS 0----------------
    #Node ID                 :   0
    #Power Supply ID         :   0
    #Manufacturer            :   XYRATEX
    #Assembly Part           :   682372-001
    #Assembly Serial Number  :   5CQLQAXXXXXXX1
    #State                   :   OK
    #Fan State               :   OK
    #Fan Speed               :   Low
    #AC State                :   OK
    #DC State                :   OK
    #Battery State           :   OK
    #Battery Detail State    :   normal
    #Battery Charge State    :   FullyCharged
    #Battery Charge Level(%) :   100
    #Max Battery Life(mins)  :   16
    #
    #---------------Node 0 PS 1----------------
    #Node ID                 :   0
    #Power Supply ID         :   1
    #Manufacturer            :   XYRATEX
    #Assembly Part           :   682372-001
    #Assembly Serial Number  :   5CQLQAXXXXXXX2
    #State                   :   OK
    #Fan State               :   OK
    #Fan Speed               :   Low
    #AC State                :   OK
    #DC State                :   OK
    #Battery State           :   OK
    #Battery Detail State    :   normal
    #Battery Charge State    :   FullyCharged
    #Battery Charge Level(%) :   100
    #Max Battery Life(mins)  :   16

    $self->{psu} = {};
    while ($content =~ /^(Node ID.*?)(?=Node ID|\Z$)/msig) {
        my $entry = $1;
        my ($node_id, $psu_id);
        $node_id = $1 if ($entry =~ /^Node\s+ID\s*:\s*(\S+)/msi);
        $psu_id = $1 if ($entry =~ /^Power\s+Supply\s+ID\s*:\s*(\S+)/msi);
        next if (!defined($node_id));

        next if (defined($self->{option_results}->{filter_node_id}) && $self->{option_results}->{filter_node_id} ne '' &&
            $node_id !~ /$self->{option_results}->{filter_node_id}/);
        next if (defined($self->{option_results}->{filter_psu_id}) && $self->{option_results}->{filter_psu_id} ne '' &&
            $psu_id !~ /$self->{option_results}->{filter_psu_id}/);

        $self->{psu}->{ $node_id . ':' . $psu_id } = {
            node_id => $node_id,
            psu_id => $psu_id,
            global => { node_id => $node_id, psu_id => $psu_id },
            ac => { node_id => $node_id, psu_id => $psu_id },
            dc => { node_id => $node_id, psu_id => $psu_id },
            fan => { node_id => $node_id, psu_id => $psu_id },
            battery => { node_id => $node_id, psu_id => $psu_id },
        };
        $self->{psu}->{ $node_id . ':' . $psu_id }->{global}->{status} = $1 if ($entry =~ /^State\s*:\s*(\S+)/msi);
        $self->{psu}->{ $node_id . ':' . $psu_id }->{ac}->{status} = $1 if ($entry =~ /^AC\s+State\s*:\s*(\S+)/msi);
        $self->{psu}->{ $node_id . ':' . $psu_id }->{dc}->{status} = $1 if ($entry =~ /^DC\s+State\s*:\s*(\S+)/msi);
        $self->{psu}->{ $node_id . ':' . $psu_id }->{fan}->{status} = $1 if ($entry =~ /^Fan\s+State\s*:\s*(\S+)/msi);
        $self->{psu}->{ $node_id . ':' . $psu_id }->{battery}->{status} = $1 if ($entry =~ /^Battery\s+State\s*:\s*(\S+)/msi);
        $self->{psu}->{ $node_id . ':' . $psu_id }->{battery}->{capacity} = $1 if ($entry =~ /^Battery\s+Charge\s+Level.*?:\s*(\S+)/msi);
        $self->{psu}->{ $node_id . ':' . $psu_id }->{battery}->{time} = $1 if ($entry =~ /^Max\s+Battery\s+Life.*?:\s*(\S+)/msi);
    }

    if (scalar(keys %{$self->{psu}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Couldn't get power supplies information");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check power supplies.

=over 8

=item B<--filter-node-id>

Filter nodes by ID (can be a regexp).

=item B<--filter-psu-id>

Filter power supplies by ID (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{node_id}, %{psu_id}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{node_id}, %{psu_id}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /ok/i').
You can use the following variables: %{status}, %{node_id}, %{psu_id}

=item B<--unknown-ac-status>

Set unknown threshold for AC status.
You can use the following variables: %{status}, %{node_id}, %{psu_id}

=item B<--warning-ac-status>

Set warning threshold for AC status.
You can use the following variables: %{status}, %{node_id}, %{psu_id}

=item B<--critical-ac-status>

Set critical threshold for AC status (default: '%{status} !~ /ok/i').
You can use the following variables: %{status}, %{node_id}, %{psu_id}

=item B<--unknown-dc-status>

Set unknown threshold for DC status.
You can use the following variables: %{status}, %{node_id}, %{psu_id}

=item B<--warning-dc-status>

Set warning threshold for DC status.
You can use the following variables: %{status}, %{node_id}, %{psu_id}

=item B<--critical-dc-status>

Set critical threshold for DC status (default: '%{status} !~ /ok/i').
You can use the following variables: %{status}, %{node_id}, %{psu_id}

=item B<--unknown-fan-status>

Set unknown threshold for fan status.
You can use the following variables: %{status}, %{node_id}, %{psu_id}

=item B<--warning-fan-status>

Set warning threshold for fan status.
You can use the following variables: %{status}, %{node_id}, %{psu_id}

=item B<--critical-fan-status>

Set critical threshold for fan status (default: '%{status} !~ /ok/i').
You can use the following variables: %{status}, %{node_id}, %{psu_id}

=item B<--unknown-battery-status>

Set unknown threshold for battery status.
You can use the following variables: %{status}, %{node_id}, %{psu_id}

=item B<--warning-battery-status>

Set warning threshold for battery status.
You can use the following variables: %{status}, %{node_id}, %{psu_id}

=item B<--critical-battery-status>

Set critical threshold for battery status (default: '%{status} !~ /ok/i').
You can use the following variables: %{status}, %{node_id}, %{psu_id}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'charge-remaining', 'charge-remaining-minutes.

=back

=cut
