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

package network::waystream::snmp::mode::listsfpport;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 'add-interface-name' => { name => 'add_interface_name' } });

    return $self;
}

my @labels = ('number', 'serial', 'connector', 'bitrate');

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{add_interface_name}) || defined($self->{option_results}->{add_interface_name})) {
        push @labels, 'interface_name';
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $map_connector_type = {
        1  => 'sc',
        6  => 'fiberJack',
        7  => 'lc',
        8  => 'mtrj',
        9  => 'mu',
        10 => 'sg',
        11 => 'opticalPigtail',
        32 => 'hssdcii',
        33 => 'copperPigtail'
    };

    # Select relevant oids for discovery function
    my $mapping = {
        sfpNumber       => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.1' },# wsSFPIndex
        sfpSerialNumber => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.53' },# wsSFPSerialNumber
        sfpConnector    => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.3', map => $map_connector_type },# wsSFPConnector
        sfpBitrate      => { oid => '.1.3.6.1.4.1.9303.4.1.4.1.6' },# wsSFPBitrate
    };

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids        => [
            { oid => $mapping->{sfpNumber}->{oid} },
            { oid => $mapping->{sfpSerialNumber}->{oid} },
            { oid => $mapping->{sfpConnector}->{oid} },
            { oid => $mapping->{sfpBitrate}->{oid} }
        ],
        return_type => 1, nothing_quit => 1
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
        next if ($oid !~ /^$mapping->{sfpSerialNumber}->{oid}\.(.*)$/);

        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $results->{$result->{sfpNumber}} = {
            number         => $result->{sfpNumber},
            serial         => $result->{sfpSerialNumber},
            connector      => $result->{sfpConnector},
            bitrate        => $result->{sfpBitrate},
            interface_name => defined($names->{$oid_name . '.' . $instance}) ?
                $names->{$oid_name . '.' . $instance} : ''
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

=back

=cut
