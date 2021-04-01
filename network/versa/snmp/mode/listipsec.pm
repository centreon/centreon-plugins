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

package network::versa::snmp::mode::listipsec;

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

    my $oid_ipsecMibIpsecStatsOrgName = '.1.3.6.1.4.1.42359.2.2.1.2.1.9.1.1.2';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_ipsecMibIpsecStatsOrgName,
        nothing_quit => 1
    );

    my $result = {};
    foreach (keys %$snmp_result) {
        $result->{ $snmp_result->{$_} } = { org_name => $snmp_result->{$_} };
    }

    return $result;
}

sub run {
    my ($self, %options) = @_;

    my $result = $self->manage_selection(snmp => $options{snmp});
    foreach (sort keys %$result) {
        $self->{output}->output_add(long_msg => 
            sprintf(
                '[org_name = %s]',
                $result->{$_}->{org_name}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List IPsec:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['org_name']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $result = $self->manage_selection(snmp => $options{snmp});
    foreach (sort keys %$result) {        
        $self->{output}->add_disco_entry(
            %{$result->{$_}}
        );
    }
}

1;

__END__

=head1 MODE

List IPsec tunnels.

=over 8

=back

=cut
