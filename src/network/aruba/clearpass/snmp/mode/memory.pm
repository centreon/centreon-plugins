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
# Authors : Alexandre Moreau <alexandre.moreau@cheops.fr> (@SpyL1nk)

package network::aruba::clearpass::snmp::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "warning:s"       => { name => 'warning' },
        "critical:s"      => { name => 'critical' }
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

    my $oid_cppmSystemMemoryFree = '.1.3.6.1.4.1.14823.1.6.1.1.1.1.1.13.0';
    my $oid_cppmSystemMemoryTotal = '.1.3.6.1.4.1.14823.1.6.1.1.1.1.1.12.0';

    my $result = $self->{snmp}->get_leef(
        oids => [$oid_cppmSystemMemoryFree, $oid_cppmSystemMemoryTotal],
        nothing_quit => 1
    );

    my $memory = {
        free => $result->{$oid_cppmSystemMemoryFree},
        total => $result->{$oid_cppmSystemMemoryTotal}
    };

    $memory->{used} = $memory->{total} - $memory->{free};
    $memory->{used_prct} = ($memory->{used} / $memory->{total}) * 100 ;
    $memory->{free_prct} = 100 - $memory->{used_prct};

    my $exit = $self->{perfdata}->threshold_check(value => $memory->{used_prct}, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->output_add(
        severity => $exit,
        short_msg => sprintf(
            "Memory total: %skB used: %skB (%.2f%%) free: %skB (%.2f%%)",
                        $memory->{total} / 1024,
                        $memory->{used} / 1024,
                        $memory->{used_prct},
                        $memory->{free} / 1024,
                        $memory->{free_prct}
        )
    );

    my $warning_value = 0;
    my $critical_value = 0;

    if (defined($self->{option_results}->{warning}) && $self->{option_results}->{warning} ne '') {
        $warning_value = int(($self->{option_results}->{warning}/100) * $memory->{total});
    }
    if (defined($self->{option_results}->{critical}) && $self->{option_results}->{critical} ne '') {
        $critical_value = int(($self->{option_results}->{critical}/100) * $memory->{total});
    }

    $self->{output}->perfdata_add(
        label => "used", unit => 'B',
        value => $memory->{used},
        min => 0,
        warning => $warning_value,
        critical => $critical_value,
        max => $memory->{total},
    );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check ClearPass server memory.

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
