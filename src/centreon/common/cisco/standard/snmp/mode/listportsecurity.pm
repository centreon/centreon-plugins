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

package centreon::common::cisco::standard::snmp::mode::listportsecurity;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw/is_excluded/;
use centreon::common::cisco::standard::snmp::mode::portsecurity;

my @attributes = qw(name description alias index port_security status violation_action admin_status oper_status);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-interface:s' => { name => 'include_interface', default => '' },
        'exclude-interface:s' => { name => 'exclude_interface', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = centreon::common::cisco::standard::snmp::mode::portsecurity::get_port_security(snmp => $options{snmp});

    my @interfaces;
    foreach my $result (values %$results) {
        next if is_excluded($result->{name}, $self->{option_results}->{include_interface}, $self->{option_results}->{exclude_interface}, output => $self->{output});

        push @interfaces, { map { $_ => $result->{$_} // '' } @attributes };
    }

    return [ sort { $a->{index} <=> $b->{index} } @interfaces ];
}

sub run {
    my ($self, %options) = @_;

    my $interfaces = $self->manage_selection(snmp => $options{snmp});
    foreach my $interface (@$interfaces) {
        $self->{output}->output_add(long_msg => join('', map { "[$_: " . $interface->{$_} . ']' } @attributes));
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List port security interfaces:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @attributes ]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $interfaces = $self->manage_selection(snmp => $options{snmp});
    $self->{output}->add_disco_entry(%$_) foreach (@$interfaces);
}

1;

__END__

=head1 MODE

List the interfaces with a port security configuration (CISCO-PORT-SECURITY-MIB).

=over 8

=item B<--include-interface>

Filter interfaces by name (C<ifName>, can be a regexp).

=item B<--exclude-interface>

Exclude interfaces by name (C<ifName>, can be a regexp).

=back

=cut
