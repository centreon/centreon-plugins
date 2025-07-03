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

package network::huawei::gpon::snmp::mode::listont;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $mapping_status = {
    1 => 'active',
    2 => 'notInService',
    3 => 'notReady',
    4 => 'createAndGo',
    5 => 'createAndWait',
    6 => 'destroy'
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'filter-name:s'   => { name => 'filter_name' },
            'filter-status:s' => { name => 'filter_status' }
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        serial =>
            { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.3' }, # hwGponDeviceOntSn
        name   =>
            { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.9' }, # hwGponDeviceOntDespt
        state  =>
            { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.10', map => $mapping_status }, # hwGponDeviceOntEntryStatus
    };

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids         => [
            { oid => $mapping->{serial}->{oid} },
            { oid => $mapping->{name}->{oid} },
            { oid => $mapping->{state}->{oid} }
        ],
        return_type  => 1,
        nothing_quit => 1
    );

    foreach my $oid ($options{snmp}->oid_lex_sort(sort keys %{$snmp_result})) {
        next if ($oid !~ /^$mapping->{serial}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $result->{name} . "': no matching filter.",
                debug    => 1
            );
            next;
        }

        if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status} ne '' &&
            $result->{state} !~ /$self->{option_results}->{filter_status}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $result->{state} . "': no matching filter.",
                debug    => 1
            );
            next;
        }

        push @{$self->{otn}}, $result;
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);

    if (scalar(keys @{$self->{otn}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No otn found matching.");
        $self->{output}->option_exit();
    }

    foreach (sort @{$self->{otn}}) {
        $self->{output}->output_add(
            long_msg =>
                sprintf(
                    "[Name = %s] [Serial = %s] [Serial Hex = %s] [State = %s]",
                    $_->{name},
                    $self->get_serial_string($_->{serial}),
                    uc(unpack("H*", $_->{serial})),
                    $_->{state}
                )
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List switches:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub get_serial_string($) {
    my ($self) = shift;

    # Get the raw OCTET STRING value for the serial number.
    # It may contain both ASCII and binary data.
    my ($raw_bytes) = @_;

    # Extract the first 4 bytes and interpret them as ASCII characters.
    # Example: '52 43 4D 47' => 'RCMG'
    my $ascii_part = substr($raw_bytes, 0, 4);

    # Extract the last 4 bytes, convert them to an uppercase hex string.
    # Example: '1A 98 0E 53' => '1A980E53'
    my $hex_part = uc(unpack("H*", substr($raw_bytes, 4, 4)));

    # Format the final output string, combining name, serial number, and state.
    # The serial number is shown as: [first 4 bytes as ASCII][last 4 bytes as HEX].
    # Example: RCMG1A980E53
    return "$ascii_part$hex_part";
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ 'name', 'serial', 'state' ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);

    foreach (@{$self->{otn}}) {
        $self->{output}->add_disco_entry(
            name       => $_->{name},
            serial     => $self->get_serial_string($_->{serial}),
            serial_hex => uc(unpack("H*", $_->{serial})),
            state      => $_->{state}
        );
    }
}

1;

__END__

=head1 MODE

List switches managed through Fortigate Switch Controller.

=over 8

=item B<--filter-name>

Filter otn by name (can be a regexp).

=item B<--filter-status>

Filter otn by status

=back

=cut