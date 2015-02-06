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
# Authors : Simon Bomm <sbomm@merethis.com>
#
####################################################################################

package apps::voip::cisco::meetingplace::mode::audiolicenses;

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
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold'" . $self->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
#   Nombre de ports audio utilise
    my $oid_cmpAudioLicense = '.1.3.6.1.4.1.9.9.733.1.3.1.0';
#   Nombre maximum de ports audio disponibles
    my $oid_cmpMaxAudioLicense = '.1.3.6.1.4.1.9.9.733.1.3.2.0';

    my $result = $self->{snmp}->get_leef(oids => [$oid_cmpAudioLicense, $oid_cmpMaxAudioLicense], nothing_quit => 1);
    my $prct;
    
    if ($result->{$oid_cmpAudioLicense} > 0) {
        $prct = $result->{$oid_cmpAudioLicense} / $result->{$oid_cmpMaxAudioLicense} * 100;
    } else {
        $prct = 0;
    }
    my $abs_warning = $self->{option_results}->{warning} / 100 * $result->{$oid_cmpMaxAudioLicense};
    my $abs_critical = $self->{option_results}->{critical} / 100 * $result->{$oid_cmpMaxAudioLicense};
    
    my $exit = $self->{perfdata}->threshold_check(value => $prct,
    	                                          threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]
						 );

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("%.2f%% of audio licenses are in use.  (%d max)",
                                                     $prct, $result->{$oid_cmpMaxAudioLicense}));

    $self->{output}->perfdata_add(label => "audio-licenses", unit => 'licenses',
                                  value => $result->{$oid_cmpAudioLicense},
                                  warning => $abs_warning,
                                  critical => $abs_critical,
				  min => 0,
				  max => $result->{$oid_cmpMaxAudioLicense});
    
    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check the percentage of audio licenses used on this cisco meeting place platform.

=over 8

=item B<--warning>

Threshold warning: Percentage value of audio licenses usage resulting in a warning state

=item B<--critical>

Threshold critical: Percentage value of audio licenses usage resulting in a critical state

=back

==cut
