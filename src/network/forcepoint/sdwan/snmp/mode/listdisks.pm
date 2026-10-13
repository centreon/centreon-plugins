#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::forcepoint::sdwan::snmp::mode::listdisks;

use strict;
use warnings;

use base qw(centreon::plugins::mode);

use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
    });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        name  => { oid => '.1.3.6.1.4.1.47565.1.1.1.11.3.1.2' },# fwPartitionDevName
        total => { oid => '.1.3.6.1.4.1.47565.1.1.1.11.3.1.4' }# fwPartitionSize
    };
    my $oid_fwDiskStatsEntry = '.1.3.6.1.4.1.47565.1.1.1.11.3.1';

    my $snmp_result = $self->{snmp}->get_multiple_table(
        oids         => [
            { oid => $oid_fwDiskStatsEntry, start => $mapping->{name}->{oid}, end => $mapping->{total}->{oid} },
            { oid => $mapping->{name}->{oid} }
        ],
        return_type  => 1,
        nothing_quit => 1
    );

    $self->{disks} = {};
    foreach my $oid (sort keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        # Filter disks by partition dev name
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/);

        $self->{disks}->{ $oid } = {
            name  => $result->{name},
            total => $result->{total}
        };
    }
}

# Sorts the disks hash by name
sub _sort_output {
    my ($self, %disks) = @_;

    sort {
        $self->{disks}->{$a}->{name} cmp $self->{disks}->{$b}->{name}
    } keys %disks;
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();

    foreach my $oid ($self->_sort_output(%{$self->{disks}})) {
        $self->{output}->output_add(long_msg => "[name = " . $self->{disks}->{$oid}->{name} . "]");
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List disks:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ 'name', 'total' ]);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    foreach my $oid ($self->_sort_output(%{$self->{disks}})) {
        $self->{output}->add_disco_entry(
            name  => $self->{disks}->{$oid}->{name},
            total => $self->{disks}->{$oid}->{total},
        );
    }
}

1;

__END__

=head1 MODE

List disks.

=cut
