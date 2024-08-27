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

package centreon::common::airespace::snmp::mode::listaps;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    # Collecting all the relevant informations user may needs when using discovery function for AP in Cisco WLC controllers.
    # They had been select with https://oidref.com/1.3.6.1.4.1.14179.2.2.1.1.3 as support.
    my $mapping = {
        name => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.3' }, # bsnAPName
        location => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.4' }, # bsnAPLocation
        model => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.16' } # bsnAPModel
    };
    # parent oid for all the mapping usage
    my $oid_bsnAPEntry = '.1.3.6.1.4.1.14179.2.2.1.1';

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_bsnAPEntry,
        start => $mapping->{name}->{oid}, # First oid of the mapping => here : 3
        end => $mapping->{model}->{oid} # Last oid of the mapping => here : 16
    );

    my $results = {};
    # Iterate for all oids catch in snmp result above
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $oid_path = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $oid_path);

        $results->{$oid_path} = {
            name => $result->{name},
            location => $result->{location},
            model => $result->{model}
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
                '[oid_path: %s] [name: %s] [location: %s] [model: %s]',
                $oid_path,
                $results->{$oid_path}->{name},
                $results->{$oid_path}->{location},
                $results->{$oid_path}->{model}
            )
        );
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List aps'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name','location','model']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $oid_path (sort keys %$results) {
        $self->{output}->add_disco_entry(
            name => $results->{$oid_path}->{name},
            location => $results->{$oid_path}->{location},
            model => $results->{$oid_path}->{model}
        );
    }
}

1;

__END__

=head1 MODE

List wireless name.

=over 8

=back

=cut
