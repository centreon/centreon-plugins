#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package network::brocade::snmp::mode::listsfpports;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'add-interface-name' => { name => 'add_interface_name' }
        });

    return $self;
}

my @labels = ('instance', 'number', 'tx_power_status', 'rx_power_status');

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{add_interface_name}) || defined($self->{option_results}->{add_interface_name})) {
        push @labels, 'interface_name';
    }
}

my $map_gen_status = {
    1 => 'notSupported',
    2 => 'notApplicable',
    3 => 'highAlarm',
    4 => 'highWarn',
    5 => 'normal',
    6 => 'lowWarn',
    7 => 'lowAlarm'
};

sub manage_selection {
    my ($self, %options) = @_;

    # Select relevant oids for discovery function
    my $mapping = {
        sfpTemperature   => { oid => '.1.3.6.1.4.1.1588.3.1.8.1.1.1.2' },
        sfpTxPowerStatus =>
            { oid => '.1.3.6.1.4.1.1588.3.1.8.1.1.1.3', map => $map_gen_status },
        sfpRxPowerStatus =>
            { oid => '.1.3.6.1.4.1.1588.3.1.8.1.1.1.6', map => $map_gen_status },# bcsiOptMonLaneRxPowerStatus
    };

    my $oid_bcsiOptMonLaneEntry = '.1.3.6.1.4.1.1588.3.1.8.1.1.1';

    my $snmp_result = $options{snmp}->get_table(
        oid   => $oid_bcsiOptMonLaneEntry,
        start => $mapping->{sfpTemperature}->{oid}
    );

    my $results = {};
    my $names = undef;
    my $oid_name = '.1.3.6.1.2.1.31.1.1.1.1';

    if (defined($self->{option_results}->{add_interface_name}) || defined($self->{option_results}->{add_interface_name})) {
        $names = $options{snmp}->get_table(
            oid          => $oid_name,
            nothing_quit => 1
        );
    }

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{sfpTemperature}->{oid}\.(.*)$/);

        my $instance = $1;
        my ($index, $port) = $instance =~ /^(\d+)(?:\.(\d+))?$/;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $results->{$instance} = {
            instance        => $instance,
            number          => $port,
            interface_name  => defined($names->{$oid_name . '.' . $index}) ?
                $names->{$oid_name . '.' . $index} : '',
            tx_power_status => $result->{sfpTxPowerStatus},
            rx_power_status => $result->{sfpRxPowerStatus}
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $number (sort keys %$results) {
        $self->{output}->output_add(long_msg =>
            join('', map("[$_: " . $results->{$number}->{$_} . ']', @labels))
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List SFP'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @labels ]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach (sort keys %$results) {
        $self->{output}->add_disco_entry(
            %{$results->{$_}}
        );
    }
}

1;

__END__

=head1 MODE

List SFP ports.

=over 8

=item B<--add-interface-name>

Add the corresponding interface name when set.

=back

=cut
