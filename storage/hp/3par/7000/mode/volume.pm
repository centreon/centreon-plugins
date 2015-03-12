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
#
####################################################################################

package storage::hp::3par::7000::mode::volume;

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
								  "hostname:s"              => { name => 'hostname' },
                                  "timeout:s"               => { name => 'timeout', default => 30 },
                                  "sudo"                    => { name => 'sudo' },
                                  "ssh-option:s@"           => { name => 'ssh_option' },
                                  "ssh-path:s"              => { name => 'ssh_path' },
                                  "ssh-command:s"           => { name => 'ssh_command', default => 'ssh' },
                                  "warning:s"				=> { name => 'warning' },
								  "critical:s"				=> { name => 'critical' },
								  "filter-type:s"			=> { name => 'filter_type' },
								  "volume:s"				=> { name => 'volume' },
								  "name"					=> { name => 'name' },
								  "regexp"					=> { name => 'regexp' },
                                });
    $self->{components} = {};
    $self->{no_components} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

	if (!defined($self->{option_results}->{hostname})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a hostname.");
       $self->{output}->option_exit(); 
    }

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

	$self->{option_results}->{remote} = 1;
	my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => "showvv -showcols Id,Name,VSize_MB,Snp_Rsvd_MB,Snp_Used_MB,Adm_Rsvd_MB,Adm_Used_MB,Usr_Rsvd_MB,Usr_Used_MB",
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});


	my $total_volumes = 0;
	my @volumes = split("\n",$stdout);
	foreach my $volume (@volumes) {
		if ($volume =~ /(\d+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/) {
			$total_volumes++;
			my $volumeId = $1;
			my $volumeName = $2;
			my $volumeSize = $3 * 1024 * 1024;
			my $volumeSnpSize = $4 * 1024 * 1024;
            my $volumeSnpUsed = $5 * 1024 * 1024;
			my $volumeAdmSize = $6 * 1024 * 1024;
			my $volumeAdmUsed = $7 * 1024 * 1024;
			my $volumeUsrSize = $8 * 1024 * 1024;
			my $volumeUsrUsed = $9 * 1024 * 1024;
			my $volumeUsed = $volumeSnpUsed + $volumeAdmUsed + $volumeUsrUsed;
			my $volumeFree = $volumeSize - $volumeUsed;
			my $percentUsed = ($volumeUsed / $volumeSize) * 100;
			my $percentFree = 100 - $percentUsed;

			my $string_to_compare = $volumeId;
			if (defined($self->{option_results}->{name})) {
				$string_to_compare = $volumeName;
			}

			next if (defined($self->{option_results}->{volume}) && defined($self->{option_results}->{regexp}) && ($string_to_compare !~ /$self->{option_results}->{volume}/i));
			next if (defined($self->{option_results}->{volume}) && !defined($self->{option_results}->{regexp}) && ($string_to_compare ne $self->{option_results}->{volume}));

			my ($volumeSizeValue, $volumeSizeUnit) = $self->{perfdata}->change_bytes(value => $volumeSize);
			my ($volumeUsedValue, $volumeUsedUnit) = $self->{perfdata}->change_bytes(value => $volumeUsed);
			my ($volumeFreeValue, $volumeFreeUnit) = $self->{perfdata}->change_bytes(value => $volumeFree);
			my ($volumeSnpSizeValue, $volumeSnpSizeUnit) = $self->{perfdata}->change_bytes(value => $volumeSnpSize);
			my ($volumeSnpUsedValue, $volumeSnpUsedUnit) = $self->{perfdata}->change_bytes(value => $volumeSnpUsed);
			my ($volumeAdmSizeValue, $volumeAdmSizeUnit) = $self->{perfdata}->change_bytes(value => $volumeAdmSize);
            my ($volumeAdmUsedValue, $volumeAdmUsedUnit) = $self->{perfdata}->change_bytes(value => $volumeAdmUsed);
			my ($volumeUsrSizeValue, $volumeUsrSizeUnit) = $self->{perfdata}->change_bytes(value => $volumeUsrSize);
            my ($volumeUsrUsedValue, $volumeUsrUsedUnit) = $self->{perfdata}->change_bytes(value => $volumeUsrUsed);

			$self->{output}->output_add(long_msg => sprintf("Volume %d '%s' Total: %.2f%s Used: %.2f%s (%.2f%%) Free: %.2f%s (%.2f%%) Usr: %.2f%s Adm: %.2f%s Snp: %.2f%s",
										$volumeId, $volumeName, $volumeSizeValue, $volumeSizeUnit,
										$volumeUsedValue, $volumeUsedUnit, $percentUsed,
										$volumeFreeValue, $volumeFreeUnit, $percentFree,
										$volumeUsrUsedValue, $volumeUsrUsedUnit,
										$volumeAdmUsedValue, $volumeAdmUsedUnit,
										$volumeSnpUsedValue, $volumeSnpUsedUnit,));
			my $exit = $self->{perfdata}->threshold_check(value => $percentUsed, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
			if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
				$self->{output}->output_add(severity => $exit,
											short_msg => sprintf("Volume %d '%s' Total: %.2f%s Used: %.2f%s (%.2f%%) Free: %.2f%s (%.2f%%) Usr: %.2f%s Adm: %.2f%s Snp: %.2f%s",
                                        $volumeId, $volumeName, $volumeSizeValue, $volumeSizeUnit,
                                        $volumeUsedValue, $volumeUsedUnit, $percentUsed,
                                        $volumeFreeValue, $volumeFreeUnit, $percentFree,
                                        $volumeUsrUsedValue, $volumeUsrUsedUnit,
                                        $volumeAdmUsedValue, $volumeAdmUsedUnit,
                                        $volumeSnpUsedValue, $volumeSnpUsedUnit,));
			}
			$self->{output}->perfdata_add(label => 'volume_'.$volumeName,
										  unit => 'B',
										  value => $volumeUsed,
										  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $volumeSize, cast_int => 1),
										  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $volumeSize, cast_int => 1),
										  min => 0,
										  max => $volumeSize);
		}
	}

	$self->{output}->output_add(severity => 'OK',
                                short_msg => 'All volumes are ok.');
	 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Physical disks.

=over 8

=item B<--hostname>

Hostname to query.

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh').

=item B<--sudo>

Use sudo.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=back

=cut
    

