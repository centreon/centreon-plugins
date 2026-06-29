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

package network::ubiquiti::uap::snmp::mode::listradios;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'filter-name:s'  => { name => 'filter_name' },
            'filter-radio:s' => { name => 'filter_radio' }
        });

    return $self;
}

my @labels = ('name', 'radio', 'channel');

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        name    => { oid => '.1.3.6.1.4.1.41112.1.6.1.1.1.2' },# unifiRadioName
        radio   => { oid => '.1.3.6.1.4.1.41112.1.6.1.1.1.3' },# unifiRadioRadio
        channel => { oid => '.1.3.6.1.4.1.41112.1.6.1.1.1.6' }# unifiRadioCuTotal
    };

    my $oid_unifiRadioEntry = '.1.3.6.1.4.1.41112.1.6.1.1.1';

    my $snmp_result = $options{snmp}->get_table(
        oid   => $oid_unifiRadioEntry,
        start => $mapping->{name}->{oid},
        end   => $mapping->{channel}->{oid},
    );

    my $results = {};

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);

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

        if (defined($self->{option_results}->{filter_radio}) && $self->{option_results}->{filter_radio} ne '' &&
            $result->{radio} !~ /$self->{option_results}->{filter_radio}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $result->{radio} . "': no matching filter.",
                debug    => 1
            );
            next;
        }

        $results->{$instance} = {
            instance => $instance,
            name     => $result->{name},
            radio    => $result->{radio},
            channel  => $result->{channel}
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
        short_msg => 'List radios'
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

List radios.

=over 8

=item B<--filter-name>

Filter access point name (can be a regexp)

=item B<--filter-radio>

Filter radio (can be a regexp). Example: '^ng$'

=back

=cut
