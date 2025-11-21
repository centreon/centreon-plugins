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

package storage::wd::nas::snmp::mode::listvolumes;

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

    my $nas = {
        ex2 => {
            volumeTable => '.1.3.6.1.4.1.5127.1.1.1.2.1.9.1',
            volume => {
                name => { oid => '.1.3.6.1.4.1.5127.1.1.1.2.1.9.1.2' },
                type => { oid => '.1.3.6.1.4.1.5127.1.1.1.2.1.9.1.3' }
            }
        },
        ex2ultra => {
            volumeTable => '.1.3.6.1.4.1.5127.1.1.1.8.1.9.1',
            volume => {
                name => { oid => '.1.3.6.1.4.1.5127.1.1.1.8.1.9.1.2' },
                type => { oid => '.1.3.6.1.4.1.5127.1.1.1.8.1.9.1.3' }
            }
        },
        ex4100 => {
            volumeTable => '.1.3.6.1.4.1.5127.1.1.1.6.1.9.1',
            volume => {
                name => { oid => '.1.3.6.1.4.1.5127.1.1.1.6.1.9.1.2' },
                type => { oid => '.1.3.6.1.4.1.5127.1.1.1.6.1.9.1.3' }
            }
        },
        pr2100 => {
            volumeTable => '.1.3.6.1.4.1.5127.1.1.1.9.1.9.1',
            volume => {
                name => { oid => '.1.3.6.1.4.1.5127.1.1.1.9.1.9.1.2' },
                type => { oid => '.1.3.6.1.4.1.5127.1.1.1.9.1.9.1.3' }
            }
        },
        pr4100 => {
            volumeTable => '.1.3.6.1.4.1.5127.1.1.1.10.1.9.1',
            volume => {
                name => { oid => '.1.3.6.1.4.1.5127.1.1.1.10.1.9.1.2' },
                type => { oid => '.1.3.6.1.4.1.5127.1.1.1.10.1.9.1.3' }
            }
        }
    };

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $nas->{ex2}->{volumeTable} },
            { oid => $nas->{ex2ultra}->{volumeTable} },
            { oid => $nas->{ex4100}->{volumeTable} },
            { oid => $nas->{pr2100}->{volumeTable} },
            { oid => $nas->{pr4100}->{volumeTable} }
        ]
    );

    my $volumes = {};
    foreach my $type (keys %$nas) {
        next if (scalar(keys %{$snmp_result->{ $nas->{$type}->{volumeTable} }}) <= 0);
        foreach (keys %{$snmp_result->{ $nas->{$type}->{volumeTable} }}) {
            next if (! /^$nas->{$type}->{volume}->{name}->{oid}\.(\d+)$/);

            $volumes->{$1} = $options{snmp}->map_instance(mapping => $nas->{$type}->{volume}, results => $snmp_result->{ $nas->{$type}->{volumeTable} }, instance => $1);
        }
    }

    return $volumes;
}

sub run {
    my ($self, %options) = @_;
  
    my $volumes = $self->manage_selection(%options);
    foreach (sort keys %$volumes) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[name: %s] [type: %s]',
                $volumes->{$_}->{name},
                $volumes->{$_}->{type}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List volumes:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'type']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $volumes = $self->manage_selection(%options);
    foreach (sort keys %$volumes) { 
        $self->{output}->add_disco_entry(
            %{$volumes->{$_}}
        );
    }
}

1;

__END__

=head1 MODE

List volumes.

=over 8

=back

=cut
