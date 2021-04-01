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

package centreon::common::fortinet::fortigate::snmp::mode::disk;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'warning:s'  => { name => 'warning' },
        'critical:s' => { name => 'critical' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    my $oid_fgSysDiskUsage = '.1.3.6.1.4.1.12356.101.4.1.6.0'; # in MB
    my $oid_fgSysDiskCapacity = '.1.3.6.1.4.1.12356.101.4.1.7.0'; # in MB
    $self->{result} = $options{snmp}->get_leef(
        oids => [ $oid_fgSysDiskUsage, $oid_fgSysDiskCapacity ], 
        nothing_quit => 1
    );

    if (!defined($self->{result}->{$oid_fgSysDiskCapacity}) || $self->{result}->{$oid_fgSysDiskCapacity} == 0) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => sprintf("No disk present.")
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    my $fgSysDiskUsage = $self->{result}->{$oid_fgSysDiskUsage} * 1024 * 1024;
    my $fgSysDiskCapacity = $self->{result}->{$oid_fgSysDiskCapacity} * 1024 * 1024;

    my $prct = $fgSysDiskUsage * 100 / $fgSysDiskCapacity;
    
    my $exit = $self->{perfdata}->threshold_check(
        value => $prct, 
        threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]
    );
    my ($size_value, $size_unit) = $self->{perfdata}->change_bytes(value => $fgSysDiskCapacity);
    $self->{output}->output_add(
        severity => $exit,
        short_msg => sprintf(
            "Disk Usage: %.2f%% used [Total: %s]", 
            $prct, $size_value . " " . $size_unit
        )
    );

    $self->{output}->perfdata_add(
        label => 'used', unit => 'B',
        nlabel => 'storage.space.usage.bytes',
        value => $fgSysDiskUsage,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $fgSysDiskCapacity, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $fgSysDiskCapacity, cast_int => 1),
        min => 0, max => $fgSysDiskCapacity
    );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check system disk usage (FORTINET-FORTIGATE).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
