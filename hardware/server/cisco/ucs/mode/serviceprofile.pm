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

package hardware::server::cisco::ucs::mode::serviceprofile;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %error_status = (
    1 => ["online", 'OK'],
    2 => ["offline", 'CRITICAL'], 
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"               => { name => 'warning' },
                                  "critical:s"              => { name => 'critical' },
                                  "skip"                    => { name => 'skip' },
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

    my $oid_cucsLsBindingDn = '.1.3.6.1.4.1.9.9.719.1.26.2.1.2';
    my $oid_cucsLsBindingOperState = '.1.3.6.1.4.1.9.9.719.1.26.2.1.10';

    my $result = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_cucsLsBindingDn },
                                                            { oid => $oid_cucsLsBindingOperState },
                                                            ],
                                                   nothing_quit => 1
                                                   );

    my $ls_online = 0;
    my $ls_offline = 0;

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_cucsLsBindingDn}})) {
        # index
        $key =~ /\.(\d+)$/;
        my $ls_index = $1;
        my $ls_name = $result->{$oid_cucsLsBindingDn}->{$oid_cucsLsBindingDn . '.' . $ls_index};
        my $ls_operstate = $result->{$oid_cucsLsBindingOperState}->{$oid_cucsLsBindingOperState . '.' . $ls_index};

        if ($ls_operstate == 1) {
            $ls_online++;
        } else {
            $ls_offline++;
        }

        if ($ls_operstate == 2 && defined($self->{option_results}->{skip})) {
            next;
        }
        if ($ls_operstate != 1) {
            $self->{output}->output_add(severity => ${$error_status{$ls_operstate}}[1],
                                        short_msg => sprintf("Service profile '%s' is %s", $ls_name, ${$error_status{$ls_operstate}}[0]));
        }
    }

    my $ls_total = $ls_online + $ls_offline;
    my $exit = $self->{perfdata}->threshold_check(value => $ls_online, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("%d service profiles online", $ls_online));

    $self->{output}->perfdata_add(label => "sp_online",
                                  value => $ls_online,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0, max => $ls_total);

    $self->{output}->perfdata_add(label => "sp_offline",
                                  value => $ls_offline,
                                  min => 0, max => $ls_total);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check service profiles status.

=over 8

=item B<--skip>

Skip 'offline' service profiles.

=item B<--warning>

Threshold warning for 'online' service profiles.

=item B<--critical>

Threshold critical for 'online' service profiles.

=back

=cut
    
