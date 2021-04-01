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

package storage::hitachi::hcp::snmp::mode::listtenants;

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

my $mapping = {
    name        => { oid => '.1.3.6.1.4.1.116.5.46.4.1.1.2' }, # tenantName
    description => { oid => '.1.3.6.1.4.1.116.5.46.4.1.1.3' }  # tenantDescription 
};
my $oid_tenant_entry = '.1.3.6.1.4.1.116.5.46.4.1.1'; # hcpTenantTableEntry

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_tenant_entry,
        start => $mapping->{name}->{oid},
        end => $mapping->{description}->{oid}
    );

    my $tenants = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);
        $tenants->{$1} = $result;
    }

    return $tenants;
}

sub run {
    my ($self, %options) = @_;
  
    my $tenants = $self->manage_selection(%options);
    foreach (sort keys %$tenants) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[name: %s] [description: %s]',
                $tenants->{$_}->{name},
                $tenants->{$_}->{description}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List tenants:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [keys %$mapping]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $tenants = $self->manage_selection(%options);
    foreach (sort keys %$tenants) { 
        $self->{output}->add_disco_entry(
            %{$tenants->{$_}}
        );
    }
}

1;

__END__

=head1 MODE

List tenants.

=over 8

=back

=cut
    
