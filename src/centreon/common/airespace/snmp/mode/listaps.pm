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

    my $mapping = {
        name => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.3' } # bsnAPName
    };

    my $snmp_result = $options{snmp}->get_table(
        oid => $mapping->{name}->{oid}
    );
    my $results = {};
    foreach my $oid (keys %$snmp_result) {
        $oid =~ /^$mapping->{name}->{oid}\.(.*?)\.(.*)$/;
        my ($num, $index) = ($1, $2);

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $num . '.' . $index);
        my $name = $self->{output}->decode(join('', map(chr($_), split(/\./, $index))));

        $results->{$name} = {
            name => $result->{name}
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $name (sort keys %$results) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[name: %s] [name: %s]',
                $name,
                $results->{$name}->{name}
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
    
    $self->{output}->add_disco_format(elements => ['name', 'name']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $name (sort keys %$results) {
        $self->{output}->add_disco_entry(
            name => $name,
            name => $results->{$name}->{name}
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
