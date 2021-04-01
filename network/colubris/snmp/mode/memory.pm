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

package network::colubris::snmp::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'warning:s'  => { name => 'warning' },
        'critical:s' => { name => 'critical' },
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
    $self->{snmp} = $options{snmp};

    my $oid_coUsInfoRamTotal = '.1.3.6.1.4.1.8744.5.21.1.1.9.0';
    my $oid_coUsInfoRamFree = '.1.3.6.1.4.1.8744.5.21.1.1.10.0';
    my $oid_coUsInfoRamBuffer = '.1.3.6.1.4.1.8744.5.21.1.1.11.0';
    my $oid_coUsInfoRamCached = '.1.3.6.1.4.1.8744.5.21.1.1.12.0';

    my $result = $self->{snmp}->get_leef(
        oids => [
            $oid_coUsInfoRamTotal, $oid_coUsInfoRamFree,
            $oid_coUsInfoRamBuffer, $oid_coUsInfoRamCached
        ],
        nothing_quit => 1
    );

    my $cached_used = $result->{$oid_coUsInfoRamCached};
    my $buffer_used = $result->{$oid_coUsInfoRamBuffer};
    my $physical_used = ($result->{$oid_coUsInfoRamTotal}) - ($result->{$oid_coUsInfoRamFree});
    my $nobuf_used = $physical_used - $buffer_used - $cached_used;
    
    my $total_size = $result->{$oid_coUsInfoRamTotal};
    
    my $prct_used = $nobuf_used * 100 / $total_size;
    my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_size);
    my ($nobuf_value, $nobuf_unit) = $self->{perfdata}->change_bytes(value => $nobuf_used);
    my ($buffer_value, $buffer_unit) = $self->{perfdata}->change_bytes(value => $buffer_used);
    my ($cached_value, $cached_unit) = $self->{perfdata}->change_bytes(value => $cached_used);
    
    $self->{output}->output_add(
        severity => $exit,
        short_msg => sprintf(
            "Ram Total: %s, Used (-buffers/cache): %s (%.2f%%), Buffer: %s, Cached: %s",
            $total_value . " " . $total_unit,
            $nobuf_value . " " . $nobuf_unit, $prct_used,
            $buffer_value . " " . $buffer_unit,
            $cached_value . " " . $cached_unit
        )
    );

    $self->{output}->perfdata_add(
        label => "cached", unit => 'B',
        value => $cached_used,
        min => 0
    );
    $self->{output}->perfdata_add(
        label => "buffer", unit => 'B',
        value => $buffer_used,
        min => 0
    );
    $self->{output}->perfdata_add(
        label => "used", unit => 'B',
        value => $nobuf_used,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_size, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_size, cast_int => 1),
        min => 0, max => $total_size
    );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check memory usage.

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
