################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com> 
#           Stephande Duret <sduret@merethis.com>
#           Simon Bomm <sbomm@merethis.com>
#
####################################################################################

package network::alcatel::common::mode::cpu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"   => { name => 'warning', default => '' },
                                  "critical:s"  => { name => 'critical', default => '' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    ($self->{warn1m}, $self->{warn1h}) = split /,/, $self->{option_results}->{warning};
    ($self->{crit1m}, $self->{crit1h}) = split /,/, $self->{option_results}->{critical};
    
    if (($self->{perfdata}->threshold_validate(label => 'warn1m', value => $self->{warn1m})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (1min) threshold '" . $self->{warn1m} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn1h', value => $self->{warn1h})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (1hour) threshold '" . $self->{warn1h} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit1m', value => $self->{crit1m})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (1min) threshold '" . $self->{crit1m} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit5h', value => $self->{crit5})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (1hour) threshold '" . $self->{crit1h} . "'.");
       $self->{output}->option_exit();
    }
}

sub check_cpu {
    my ($self, %options) = @_;
    
    my $exit1 = $self->{perfdata}->threshold_check(value => $options{'1min'}, threshold => [ { label => 'crit1m', exit_litteral => 'critical' },
                                                                                    { label => 'warn1m', exit_litteral => 'warning' },
                                                                                  ]);

    my $exit2 = $self->{perfdata}->threshold_check(value => $options{'1hour'}, threshold => [ { label => 'crit1h', exit_litteral => 'critical' },
                                                                                     { label => 'warn1h', exit_litteral => 'warning' },  
                                                                                   ]);

    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("%s: %.2f%% (1min), %.2f%% (1hour)", $options{name}, $options{'1min'}, $options{'1hour'}));

    $self->{output}->perfdata_add(label => "cpu1m" . $options{perf_label} , unit => '%',
                                  value => $options{'1min'},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1m'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1m'),
                                  min => 0, max => 100);
    $self->{output}->perfdata_add(label => "cpu1h" . $options{perf_label} , unit => '%',
                                  value => $options{'1hour'},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1h'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1h'),
                                  min => 0, max => 100);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_healthDeviceCpu1MinAvg = '.1.3.6.1.4.1.6486.800.1.2.1.16.1.1.1.14'; # it's '.0' but it's for walk multiple
    my $oid_healthDeviceCpu1HrAvg = '.1.3.6.1.4.1.6486.800.1.2.1.16.1.1.1.15'; # it's '.0' but it's for walk multiple
    my $oid_healthModuleCpu1MinAvg = '.1.3.6.1.4.1.6486.800.1.2.1.16.1.1.2.1.1.15';
    my $oid_healthModuleCpu1HrAvg = '.1.3.6.1.4.1.6486.800.1.2.1.16.1.1.2.1.1.16';
    
    my $result = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_healthDeviceCpu1MinAvg },
                                                            { oid => $oid_healthDeviceCpu1HrAvg },
                                                            { oid => $oid_healthModuleCpu1MinAvg },
                                                            { oid => $oid_healthModuleCpu1HrAvg },
                                                           ], nothing_quit => 1);
    
    $self->check_cpu(name => 'Device cpu', perf_label => '_device', 
                     '1min' => $result->{$oid_healthDeviceCpu1MinAvg}->{$oid_healthDeviceCpu1MinAvg . '.' . 0}, 
                     '1hour' => $result->{$oid_healthDeviceCpu1HrAvg}->{$oid_healthDeviceCpu1HrAvg . '.' . 0});
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_healthModuleCpu1MinAvg}})) {
        $oid =~ /^$oid_healthModuleCpu1MinAvg\.(.*)$/;
        $self->check_cpu(name => "Module cpu '$1'", perf_label => "_module_$1", 
                         '1min' => $result->{$oid_healthModuleCpu1MinAvg}->{$oid_healthModuleCpu1MinAvg . '.' . $1}, 
                         '1hour' => $result->{$oid_healthModuleCpu1HrAvg}->{$oid_healthModuleCpu1HrAvg . '.' . $1});
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check cpu usage (AlcatelIND1Health.mib).

=over 8

=item B<--warning>

Threshold warning in percent (1m,1h).

=item B<--critical>

Threshold critical in percent (1m,1h).

=back

=cut
    
