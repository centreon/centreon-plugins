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

package network::cambium::cnmatrix::snmp::mode::listsfpport;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw/is_excluded/;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'add-interface-name' => { name => 'add_interface_name' },
            'include-type:s'     => { name => 'include_type' },
            'exclude-type:s'     => { name => 'exclude_type' }
        });

    return $self;
}

my @labels = ('number', 'vendor', 'vendor_oui', 'vendor_part_no', 'serial', 'type');

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{add_interface_name}) || defined($self->{option_results}->{add_interface_name})) {
        push @labels, 'interface_name';
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $map_type = {
        1  => 'cn1000BASE-T',
        2  => 'cn1000BASE-CX',
        3  => 'cn1000BASE-LX',
        4  => 'cn1000BASE-SX',
        5  => 'cn10GBASE-SR',
        6  => 'cn10GBASE-LR',
        7  => 'cn10GBASE-ER',
        8  => 'cn10GBASE-LRM',
        9  => 'cn10GBASE-SW',
        10 => 'cn10GBASE-LW',
        11 => 'cn10GBASE-EW'
    };

    # Select relevant oids for discovery function
    my $mapping = {
        type         => { oid => '.1.3.6.1.4.1.2076.81.18.1.1.11.1.3', map => $map_type },# cnTransceiverType
        vendor       => { oid => '.1.3.6.1.4.1.2076.81.18.1.1.11.1.5' },# cnTransceiverVendorName
        vendorOUI    => { oid => '.1.3.6.1.4.1.2076.81.18.1.1.11.1.6' },# cnTransceiverVendorOUI
        vendorPartNo => { oid => '.1.3.6.1.4.1.2076.81.18.1.1.11.1.7' },# cnTransceiverVendorPartNo
        serial       => { oid => '.1.3.6.1.4.1.2076.81.18.1.1.11.1.9' },# cnTransceiverVendorSerial
    };

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids        => [
            { oid => $mapping->{type}->{oid} },
            { oid => $mapping->{vendor}->{oid} },
            { oid => $mapping->{vendorOUI}->{oid} },
            { oid => $mapping->{vendorPartNo}->{oid} },
            { oid => $mapping->{serial}->{oid} },
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
        next if ($oid !~ /^$mapping->{serial}->{oid}\.(.*)$/);

        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if is_excluded(
            $result->{type},
            $self->{option_results}->{include_type},
            $self->{option_results}->{exclude_type},
            output => $self->{output}
        );

        my $oui = join '-', map {sprintf "%02X", ord($_)} split //, $result->{vendorOUI};

        $results->{$instance} = {
            number         => $instance,
            vendor         => ($result->{vendor} =~ s/^\s+|\s+$//gr),
            vendor_oui     => $oui,
            vendor_part_no => ($result->{vendorPartNo} =~ s/^\s+|\s+$//gr),
            serial         => ($result->{serial} =~ s/^\s+|\s+$//gr),
            type           => $result->{type},
            interface_name => defined($names->{$oid_name . '.' . $instance}) ?
                $names->{$oid_name . '.' . $instance} : ''
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $port (sort keys %$results) {
        $self->{output}->output_add(long_msg =>
            join('', map("[$_: " . $results->{$port}->{$_} . ']', @labels))
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

List C<SFP> ports.

=over 8

=item B<--add-interface-name>

Add the corresponding interface name when set.

=item B<--include-type>

Filters the ports by the connector type. Can be: C<sc>, C<fiberJack>, C<lc>, C<mtrj>, C<mu>, C<sg>, C<opticalPigtail>, C<hssdcii>, C<copperPigtail>

=item B<--exclude-type>

Filters the ports by the connector type. Can be: C<sc>, C<fiberJack>, C<lc>, C<mtrj>, C<mu>, C<sg>, C<opticalPigtail>, C<hssdcii>, C<copperPigtail>

=back

=cut
