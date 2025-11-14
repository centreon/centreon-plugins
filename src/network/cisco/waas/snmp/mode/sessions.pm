#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::cisco::waas::snmp::mode::sessions;

use base qw(centreon::plugins::mode);

use centreon::plugins::misc qw/is_empty/;
use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"       => { name => 'warning', default => '60' },
                                  "critical:s"      => { name => 'critical', default => '70' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    $self->{warning} = $self->{option_results}->{warning};
    $self->{critical} = $self->{option_results}->{critical};
    
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning % threshold '" . $self->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical % threshold'" . $self->{critical} . "'.");
       $self->{output}->option_exit();
	}
}

sub abs_range_from_prct_range {
    my (%options) = @_;
    # $options{range_prct} : the nagios-style range threshold in percent (eg. '0:20', '@10:15' or '60:'
    # $options{max} : the maximum value the metric can have
    # returns the threshold converted into absolute value

    return '' if is_empty($options{range_prct});
    # no change if the max value is not provided
    return $options{range_prct} if (is_empty($options{max}) || $options{max} == 0) ;

    my $range_prct = $options{range_prct};
    my $max = $options{max};
    # keep the starting '@' or empty string
    my $range_abs = $range_prct =~ s/^@// ? '@' : '';

    # split the threshold, perform the calculation, and join it back together to append it to the potential '@'
    $range_abs .= join(':', map {$_ eq '' ? '' : $_ * $max / 100} split /:/, $range_prct);

    return $range_abs;
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    # Number of licenses
    my $oid_cwoTfoStatsMaxActiveConn = '.1.3.6.1.4.1.9.9.762.1.2.1.3.0';
    # Number of optimized sessions
    my $oid_cwoTfoStatsActiveOptConn = '.1.3.6.1.4.1.9.9.762.1.2.1.2.0';
    # Number of pass-through sessions (non-optimized)
    my $oid_cwoTfoStatsActivePTConn = '.1.3.6.1.4.1.9.9.762.1.2.1.10.0';

    my $result = $self->{snmp}->get_leef(oids => [$oid_cwoTfoStatsMaxActiveConn, $oid_cwoTfoStatsActiveOptConn,
                                                  $oid_cwoTfoStatsActivePTConn], nothing_quit => 1);

    my $prct = $result->{$oid_cwoTfoStatsActiveOptConn} / $result->{$oid_cwoTfoStatsMaxActiveConn} * 100;

    my ($abs_warning, $abs_critical) = map {  abs_range_from_prct_range(
        range_prct => $self->{perfdata}->get_perfdata_for_output(label => $_),
        max        => $result->{$oid_cwoTfoStatsMaxActiveConn}
    )} ('warning', 'critical');
    
    my $exit = $self->{perfdata}->threshold_check(value => $prct,
                                        threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Passthrough_connections: %d Optimized_connections: %d / %d licences",
                                                     $result->{$oid_cwoTfoStatsActivePTConn}, $result->{$oid_cwoTfoStatsActiveOptConn}, $result->{$oid_cwoTfoStatsMaxActiveConn})
				);

    $self->{output}->perfdata_add(label => "Passthrough_connections", unit => 'con',
                                  value => $result->{$oid_cwoTfoStatsActivePTConn});
    $self->{output}->perfdata_add(label => "Optimized_connections", unit => 'con',
                                  value => $result->{$oid_cwoTfoStatsActiveOptConn},
                                  warning => $abs_warning,
                                  critical => $abs_critical,
                                  min => 0,
				  max => $result->{$oid_cwoTfoStatsMaxActiveConn});
    
    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check optimized and passthrough sessions on Cisco WAAS equipments against total number of licence (CISCO-WAN-OPTIMIZATION-MIB). Available on all Cisco ISR G2 (You need to configure through IOS CLI).

=over 8

=item B<--warning>

Warning threshold: Percentage value of passthrough sessions resulting in a warning state

=item B<--critical-average>

Critical threshold: Percentage value of passthrough sessions resulting in a critical state

=back

==cut
