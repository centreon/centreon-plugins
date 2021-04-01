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

package network::citrix::sdx::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

sub set_system {
    my ($self, %options) = @_;
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        default => [
            ['OK', 'OK'],
            ['ERROR', 'CRITICAL']
        ]
    };
    
    $self->{components_path} = 'network::citrix::sdx::snmp::mode::components';
    $self->{components_module} = ['hardware', 'software'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_performance => 1, no_load_components => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

1;

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'hardware', 'software'.

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter=hardware,name

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='hardware,WARNING,ERROR'

=back

=cut

package network::citrix::sdx::snmp::mode::components::hardware;

use strict;
use warnings;

my $mapping_hw = {
    hardwareResourceName    => { oid => '.1.3.6.1.4.1.5951.6.2.1000.1.1.1' },
    hardwareResourceStatus  => { oid => '.1.3.6.1.4.1.5951.6.2.1000.1.1.7' },
};

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $mapping_hw->{hardwareResourceName}->{oid} },
        { oid => $mapping_hw->{hardwareResourceStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking hardware");
    $self->{components}->{hardware} = {name => 'hardware', total => 0, skip => 0};
    return if ($self->check_filter(section => 'hardware'));

    my $datas = { %{$self->{results}->{ $mapping_hw->{hardwareResourceStatus}->{oid} }}, %{$self->{results}->{ $mapping_hw->{hardwareResourceName}->{oid} }} };
    foreach ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping_hw->{hardwareResourceStatus}->{oid} }})) {
        /^$mapping_hw->{hardwareResourceStatus}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_hw, results => $datas, instance => $instance);

        next if ($self->check_filter(section => 'hardware', instance => $result->{hardwareResourceName}));

        $self->{components}->{hardware}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("hardware '%s' status is '%s' [instance = %s]",
                                                        $result->{hardwareResourceName}, $result->{hardwareResourceStatus}, $result->{hardwareResourceName}));
        my $exit = $self->get_severity(label => 'default', section => 'hardware', value => $result->{hardwareResourceStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                       short_msg => sprintf("Hardware '%s' status is '%s'", $result->{hardwareResourceName}, $result->{hardwareResourceStatus}));
        }
    }
}

1;

package network::citrix::sdx::snmp::mode::components::software;

use strict;
use warnings;

my $mapping_soft = {
    softwareResourceName    => { oid => '.1.3.6.1.4.1.5951.6.2.1000.2.1.1' },
    softwareResourceStatus  => { oid => '.1.3.6.1.4.1.5951.6.2.1000.2.1.7' },
};

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $mapping_soft->{softwareResourceName}->{oid} },
        { oid => $mapping_soft->{softwareResourceStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking software");
    $self->{components}->{software} = {name => 'software', total => 0, skip => 0};
    return if ($self->check_filter(section => 'software'));

    my $datas = { %{$self->{results}->{ $mapping_soft->{softwareResourceStatus}->{oid} }}, %{$self->{results}->{ $mapping_soft->{softwareResourceName}->{oid} }} };
    foreach ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping_soft->{softwareResourceStatus}->{oid} }})) {
        /^$mapping_soft->{softwareResourceStatus}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_soft, results => $datas, instance => $instance);

        next if ($self->check_filter(section => 'software', instance => $result->{softwareResourceName}));

        $self->{components}->{software}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("software '%s' status is '%s' [instance = %s]",
                                                        $result->{softwareResourceName}, $result->{softwareResourceStatus}, $result->{softwareResourceName}));
        my $exit = $self->get_severity(label => 'default', section => 'software', value => $result->{softwareResourceStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                       short_msg => sprintf("Software '%s' status is '%s'", $result->{softwareResourceName}, $result->{softwareResourceStatus}));
        }
    }
}

1;
