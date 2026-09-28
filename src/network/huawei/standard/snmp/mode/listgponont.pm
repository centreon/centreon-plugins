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

package network::huawei::standard::snmp::mode::listgponont;

use base qw(centreon::plugins::mode);
use centreon::plugins::misc qw/is_excluded/;
use centreon::common::huawei::standard::snmp::functions qw/get_serial_string/;

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
            'include-name:s'   => { name => 'include_name',    default => '' },
            'exclude-name:s'   => { name => 'exclude_name',    default => '' },
            'include-status:s' => { name => 'include_status',  default => '' },
            'exclude-status:s' => { name => 'exclude_status',  default => '' },
            'include-serial:s' => { name => 'include_serial',  default => '' },
            'exclude-serial:s' => { name => 'exclude_serial',  default => '' }
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
            { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.3' },# hwGponDeviceOntSn
        name   =>
            { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.9' },# hwGponDeviceOntDespt
        state  =>
            { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.10', map => $mapping_status },# hwGponDeviceOntEntryStatus
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

        my $serial = get_serial_string($result->{serial});
        $result->{serial_hex} = uc(unpack("H*", $result->{serial}));
        $result->{serial} = $serial // '';
        next if is_excluded($result->{name} // '', $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});
        next if is_excluded($result->{serial}, $self->{option_results}->{include_serial}, $self->{option_results}->{exclude_serial}, output => $self->{output});
        next if is_excluded($result->{state} // '', $self->{option_results}->{include_status}, $self->{option_results}->{exclude_status}, output => $self->{output});

        push @{$self->{ont}}, $result;
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);

    $self->{output}->option_exit(short_msg => "No ONT found matching.")
        unless keys @{$self->{ont}};

    foreach (sort { $a->{name} cmp $b->{name} } @{$self->{ont}}) {
        $self->{output}->output_add(
            long_msg =>
                sprintf(
                    "[Name = %s] [Serial = %s] [Serial Hex = %s] [State = %s]",
                    $_->{name},
                    $_->{serial},
                    $_->{serial_hex},
                    $_->{state}
                )
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List ONT:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ 'name', 'serial', 'serial_hex', 'state' ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);

    foreach (sort { $a->{name} cmp $b->{name} } @{$self->{ont}}) {
        $self->{output}->add_disco_entry(
            name       => $_->{name},
            serial     => $_->{serial},
            serial_hex => $_->{serial_hex},
            state      => $_->{state}
        );
    }
}

1;

__END__

=head1 MODE

List ONT for GPON.

=over 8

=item B<--include-name>

Filter ONT by name (can be a regexp).

=item B<--exclude-name>

Exclude ONT by name (can be a regexp).

=item B<--include-serial>

Filter ONT by serial (can be a regexp).

=item B<--exclude-serial>

Exclude ONT by serial (can be a regexp).

=item B<--include-status>

Filter ONT by status

=item B<--exclude-status>

Exclude ONT by status

=back

=cut
