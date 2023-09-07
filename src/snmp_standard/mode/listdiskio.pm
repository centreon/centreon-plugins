#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package snmp_standard::mode::listdiskio;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        index => { oid => '.1.3.6.1.4.1.2021.13.15.1.1.1' }, # diskioindex
        name => { oid => '.1.3.6.1.4.1.2021.13.15.1.1.2' } # diskiodevice
    };
    # parent oid for all the mapping usage
    my $oid_diskioEntry = '.1.3.6.1.4.1.2021.13.15.1.1';

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_diskioEntry,
        start => $mapping->{index}->{oid}, # First oid of the mapping
        end => $mapping->{name}->{oid} # Last oid of the mapping
    );

    my $results = {};
    # Iterate for all oids catch in snmp result above
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{index}->{oid}\.(.*)$/);
        my $oid_path = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $oid_path);
        $results->{$oid_path} = {
            index => $result->{index},
            name  => $result->{name}
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $oid_path (sort keys %$results) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[oid_path: %s] [index: %s] [name: %s]',
                $oid_path,
                $results->{$oid_path}->{index},
                $results->{$oid_path}->{name}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List disk IO device'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['index','name']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $oid_path (sort keys %$results) {
        $self->{output}->add_disco_entry(
            index => $results->{$oid_path}->{index},
            name => $results->{$oid_path}->{name}
        );
    }
}

1;

__END__

=head1 MODE

List disk IO device (UCD-DISKIO-MIB).
Need to enable "includeAllDisks 10%" on snmpd.conf.

=over 8

=back

=cut