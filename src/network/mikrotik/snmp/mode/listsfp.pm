#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::mikrotik::snmp::mode::listsfp;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw/is_excluded/;

# MIKROTIK-MIB::mtxrOpticalTable, indexed by ifIndex
my $mapping = {
    name       => { oid => '.1.3.6.1.4.1.14988.1.1.19.1.1.2' },  # mtxrOpticalName
    wavelength => { oid => '.1.3.6.1.4.1.14988.1.1.19.1.1.5' },  # mtxrOpticalWavelength (nm * 100)
    vendor     => { oid => '.1.3.6.1.4.1.14988.1.1.19.1.1.11' }, # mtxrOpticalVendorName
    serial     => { oid => '.1.3.6.1.4.1.14988.1.1.19.1.1.12' }  # mtxrOpticalVendorSerial
};
my $oid_mtxrOpticalEntry = '.1.3.6.1.4.1.14988.1.1.19.1.1';

my @labels = ('index', 'name', 'vendor', 'serial', 'wavelength');

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-name:s' => { name => 'include_name' },
        'exclude-name:s' => { name => 'exclude_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid   => $oid_mtxrOpticalEntry,
        start => $mapping->{name}->{oid},
        end   => $mapping->{serial}->{oid}
    );

    my $results = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(\d+)$/);
        my $index = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $index);

        my $name = $self->{output}->decode($result->{name});
        next if (is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name},
            output => $self->{output}));

        $results->{$index} = {
            index      => $index,
            name       => $name,
            vendor     => $self->{output}->decode($result->{vendor} // ''),
            serial     => $self->{output}->decode($result->{serial} // ''),
            wavelength => defined($result->{wavelength}) ? sprintf('%.2f', $result->{wavelength} / 100) : ''
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $index (sort { $a <=> $b } keys %$results) {
        $self->{output}->output_add(
            long_msg => join('', map("[$_: " . $results->{$index}->{$_} . ']', @labels))
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List SFP modules:'
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
    foreach my $index (sort { $a <=> $b } keys %$results) {
        $self->{output}->add_disco_entry(%{$results->{$index}});
    }
}

1;

__END__

=head1 MODE

List the SFP modules plugged in Mikrotik equipment (C<MIKROTIK-MIB::mtxrOpticalTable>).
The wavelength is given in nanometers.

=over 8

=item B<--include-name>

Only list the modules whose interface name matches this regular expression.

=item B<--exclude-name>

Exclude the modules whose interface name matches this regular expression.

=back

=cut
