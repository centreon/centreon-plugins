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

package network::versa::snmp::mode::listsdwan;

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

my $mapping_name = {
    org_name    => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.10.1.1.5' }, # sdwanPolicyOrgName    
    policy_name => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.10.1.1.6' }, # sdwanPolicyName
    rule_name   => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.10.1.1.7' }  # sdwanPolicyRuleName
};
my $oid_sdwanPolicyEntry = '.1.3.6.1.4.1.42359.2.2.1.2.1.10.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_sdwanPolicyEntry,
        start => $mapping_name->{org_name}->{oid},
        end => $mapping_name->{rule_name}->{oid},
        nothing_quit => 1
    );

    my $results = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping_name->{org_name}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping_name, results => $snmp_result, instance => $instance);
        $results->{$instance} = $result;
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach (sort keys %$results) {
        $self->{output}->output_add(long_msg => 
            sprintf(
                '[org_name = %s][policy_name = %s][rule_name = %s]',
                $results->{$_}->{org_name},
                $results->{$_}->{policy_name},
                $results->{$_}->{rule_name}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List SD-Wan:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['org_name', 'policy_name', 'rule_name']);
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

List SD-Wan rules.

=over 8

=back

=cut
