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

package centreon::common::cisco::standard::snmp::mode::listcdpneighbors;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::common::cisco::standard::snmp::mode::cdp;

my @attributes = ('name', 'remote_port', 'local_interface', 'local_ifindex');

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-neighbor:s' => { name => 'filter_neighbor' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    return centreon::common::cisco::standard::snmp::mode::cdp::get_neighbors(
        snmp => $options{snmp},
        filter_neighbor => $self->{option_results}->{filter_neighbor}
    );
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $instance (sort { $results->{$a}->{name} cmp $results->{$b}->{name} } keys %$results) {
        $self->{output}->output_add(
            long_msg => join('', map("[$_: " . $results->{$instance}->{$_} . ']', @attributes))
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List CDP neighbors:'
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

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach (sort { $results->{$a}->{name} cmp $results->{$b}->{name} } keys %$results) {
        $self->{output}->add_disco_entry(%{$results->{$_}});
    }
}

1;

__END__

=head1 MODE

List Cisco Discovery Protocol (C<CDP>) neighbors (C<CISCO-CDP-MIB>).

=over 8

=item B<--filter-neighbor>

Filter neighbors by name (can be a regular expression).

=back

=cut
