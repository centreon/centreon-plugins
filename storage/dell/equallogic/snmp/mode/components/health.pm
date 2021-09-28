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

package storage::dell::equallogic::snmp::mode::components::health;

use strict;
use warnings;

my %map_health_status = (
    0 => 'unknown', 
    1 => 'normal', 
    2 => 'warning', 
    3 => 'critical'
);

my $mapping = {
    health_status => { oid => '.1.3.6.1.4.1.12740.2.1.5.1.1', map => \%map_health_status } # eqlMemberHealthStatus
};
my $mapping_extra_info = {
    major_version       => { oid => '.1.3.6.1.4.1.12740.2.1.1.1.21' }, # eqlMemberControllerMajorVersion
    minor_version       => { oid => '.1.3.6.1.4.1.12740.2.1.1.1.22' }, # eqlMemberControllerMinorVersion
    maintenance_version => { oid => '.1.3.6.1.4.1.12740.2.1.1.1.23' }, # eqlMemberControllerMaintenanceVersion
    product_family      => { oid => '.1.3.6.1.4.1.12740.2.1.11.1.9' }  # eqlMemberProductFamily
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{health_status}->{oid} };
}

sub get_extra_informations {
    my ($self, %options) = @_;

    my $snmp_result = $self->{snmp}->get_leef(
        oids => [ map($_->{oid} . '.' . $options{instance}, values(%$mapping_extra_info)) ],
    );
    return $self->{snmp}->map_instance(mapping => $mapping_extra_info, results => $snmp_result, instance => $options{instance});
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking health");
    $self->{components}->{health} = {name => 'health', total => 0, skip => 0};
    return if ($self->check_filter(section => 'health'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping->{health_status}->{oid} }})) {
        next if ($oid !~ /^$mapping->{health_status}->{oid}\.(\d+\.\d+)$/);
        my ($member_instance) = ($1);
        my $member_name = $self->get_member_name(instance => $member_instance);
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $mapping->{health_status}->{oid} }, instance => $member_instance);

        next if ($self->check_filter(section => 'health', instance => $member_instance));
        $self->{components}->{health}->{total}++;

        my $extra_infos = get_extra_informations($self, instance => $member_instance);

        $self->{output}->output_add(
            long_msg => sprintf(
                "health '%s' status is %s [instance: %s, product: %s, version: %s].",
                $member_name,
                $result->{health_status},
                $member_instance,
                $extra_infos->{product_family},
                $extra_infos->{major_version} . '.' . $extra_infos->{minor_version} . '.' . $extra_infos->{maintenance_version}
            )
        );
        my $exit = $self->get_severity(section => 'health', value => $result->{health_status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "Health '%s' status is %s",
                    $member_name, $result->{health_status}
                )
            );
        }
    }
}

1;
