#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package centreon::common::cisco::standard::snmp::mode::listaaaservers;

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

my $map_protocol = {
    1 => 'tacacsplus', 2 => 'radius', 3 => 'ldap',
    4 => 'kerberos', 5 => 'ntlm', 6 => 'sdi',
    7 => 'other'
};

my $mapping = {
    address     => { oid => '.1.3.6.1.4.1.9.10.56.1.1.2.1.3' }, # casAddress
    authen_port => { oid => '.1.3.6.1.4.1.9.10.56.1.1.2.1.4' }, # casAuthenPort
    acc_port    => { oid => '.1.3.6.1.4.1.9.10.56.1.1.2.1.5' }  # casAcctPort
};
my $oid_casConfigEntry = '.1.3.6.1.4.1.9.10.56.1.1.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_casConfigEntry,
        start => $mapping->{address}->{oid},
        end => $mapping->{acc_port}->{oid},
        nothing_quit => 1
    );

    my $results = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{address}->{oid}\.((\d+).*)$/);
        my ($instance, $protocol) = ($1, $map_protocol->{$2});

        $results->{$instance} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        $results->{$instance}->{protocol} = $protocol; 
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $name (sort keys %$results) {
        $self->{output}->output_add(long_msg => 
            join('', map("[$_ = " . $results->{$name}->{$_} . ']', keys(%$mapping))) . '[protocol = ' . $results->{$name}->{protocol} . ']'
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List AAA servers:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['protocol', keys %$mapping]);
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

List AAA servers.

=over 8

=back

=cut
