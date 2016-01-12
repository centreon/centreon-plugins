#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package network::juniper::common::screenos::mode::sessions;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning', },
                                  "warning-failed:s"        => { name => 'warning_failed', },
                                  "critical:s"              => { name => 'critical', },
                                  "critical-failed:s"       => { name => 'critical_failed', },
                                });
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);

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
    if (($self->{perfdata}->threshold_validate(label => 'warning-failed', value => $self->{option_results}->{warning_failed})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-failed threshold '" . $self->{option_results}->{warning_failed} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-failed', value => $self->{option_results}->{critical_failed})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-failed threshold '" . $self->{option_results}->{critical_failed} . "'.");
        $self->{output}->option_exit();
    }
    
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();
    
    my $new_datas = {};
    my $old_timestamp = undef;
    my $old_failed = undef;
    
    $self->{statefile_value}->read(statefile => 'juniper_' . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    
    my $oid_nsResSessAllocate = '.1.3.6.1.4.1.3224.16.3.2.0';
    my $oid_nsResSessMaxium = '.1.3.6.1.4.1.3224.16.3.3.0';
    my $oid_nsResSessFailed = '.1.3.6.1.4.1.3224.16.3.4.0';
    
    my $result = $self->{snmp}->get_leef(oids => [$oid_nsResSessAllocate, $oid_nsResSessMaxium, $oid_nsResSessFailed], nothing_quit => 1);
    
    my $spu_done = 0;
    my $cp_total = $result->{$oid_nsResSessMaxium};
    my $cp_used = $result->{$oid_nsResSessAllocate};
    my $cp_failed = $result->{$oid_nsResSessFailed};    
    my $prct_used = $cp_used * 100 / $cp_total;
    $spu_done = 1;
    
    $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    $old_failed = $self->{statefile_value}->get(name => 'session_failed');
    $new_datas->{last_timestamp} = time();
    $new_datas->{session_failed} = $cp_failed;

    if (!defined($old_timestamp) || !defined($old_failed) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    $old_failed = 0 if ($old_failed > $new_datas{session_failed});
    my $delta_time = $new_datas->{last_timestamp} - $old_timestamp;
    $delta_time = 1 if ($delta_time == 0);
    
    my $sessFailedPerSec = ($new_datas->{session_failed} - $old_failed) / $delta_time;
    
    my $exit_used = $self->{perfdata}->threshold_check(value => $prct_used, 
                            threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    my $exit_failed = $self->{perfdata}->threshold_check(value => $sessFailedPerSec,
                            threshold => [ { label => 'critical-failed', 'exit_litteral' => 'critical' }, { label => 'warning-failed', exit_litteral => 'warning' } ]);
   
    $self->{output}->output_add(severity => $exit_used,
                                short_msg => sprintf("%.2f%% of the sessions limit reached (%d of max. %d)", 
                                    $prct_used, $cp_used, $cp_total));
    $self->{output}->output_add(severity => $exit_failed,
                                short_msg => sprintf("'%i' failed sessions/s", 
                                                     $sessFailedPerSec));
    
    $self->{output}->perfdata_add(label => 'sessions',
                                  value => $cp_used,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $cp_total, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $cp_total, cast_int => 1),
                                  min => 0, max => $cp_total);
    $self->{output}->perfdata_add(label => 'failed_sessions_Per_Sec',
                                  value => $sessFailedPerSec,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-failed', cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-failed', cast_int => 1),);

    if ($spu_done == 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot check sessions usage (no total values).");
        $self->{output}->option_exit();
    }
    
    $self->{statefile_value}->write(data => $new_datas);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Juniper sessions usage and failed sessions (NETSCREEN-RESOURCE-MIB).

=over 8

=item B<--warning>

Threshold warning (percentage).

=item B<--critical>

Threshold critical (percentage).

=item B<--warning-failed>

Threshold warning on failed sessions (failed sesssions / seconds).

=item B<--critical-failed>

Threshold critical in failed sessions (failed sessions / seconds).

=back

=cut
