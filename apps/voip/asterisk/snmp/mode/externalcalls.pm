################################################################################
# Copyright 2005-2014 MERETHIS
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

package apps::voip::asterisk::snmp::mode::externalcalls;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;

my $oid_astBase = '.1.3.6.1.4.1.22736';
my $oid_astConfigCallsActive = $oid_astBase.'.1.2.5.0';
my $oid_astChanName = $oid_astBase.'.1.5.2.1.2'; # need an index at the end
my $oid_astChanIndex = $oid_astBase.'.1.5.2.1.1'; # need an index at the end
my $oid_astNumChannels = $oid_astBase.'.1.5.1.0';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"          => { name => 'warning', },
                                  "critical:s"         => { name => 'critical', },
                                  "warnontrunk:s"      => { name => 'warnontrunk', },
                                  "critontrunk:s"      => { name => 'critontrunk', },
                                  "force-oid:s"        => { name => 'force_oid', },
                                  "trunkusernamelist:s"        => { name => 'trunkusernamelist', },
                                  "filter-name"        => { name => 'filter-name' },
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
    if (($self->{perfdata}->threshold_validate(label => 'warnontrunk', value => $self->{option_results}->{warnontrunk})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warnontrunk} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critontrunk', value => $self->{option_results}->{critontrunk})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critontrunk} . "'.");
       $self->{output}->option_exit();
    }
    
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    my ($result, $value);
    my (@callsbytrunk, @error_msg, @msg);
    
    # explode trunk list
    my @trunkusernamelist = split(';',$self->{option_results}->{trunkusernamelist});
	foreach my $trunk (@trunkusernamelist)
	{
		if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $trunk !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping trunk '" . $trunk . "': no matching filter name");
            next;
        }
        push @callsbytrunk , { trunk => $trunk, num => 0};
	}
    # get chanName and sum calls for each
    $result = $self->{snmp}->get_leef(oids => [ $oid_astNumChannels ], nothing_quit => 1);
    my $astNumChannels = $result->{$oid_astNumChannels};
    my $astConfigCallsActive = 0;
    foreach my $i (1..$astNumChannels) {
        $result = $self->{snmp}->get_leef(oids => [ $oid_astChanName.'.'.$i ], nothing_quit => 1);
        $value = $result->{$oid_astChanName.'.'.$i};
        $value =~ /^(.*)\/(.*)-.*/;
        my ($protocol, $trunkname) = ($1, $2);
        foreach my $val (@callsbytrunk)
        {
        	if ( $val->{trunk} eq $trunkname )
        	{
        		$val->{num} = $val->{num}+1;
        		$astConfigCallsActive = $astConfigCallsActive+1;
        	}
        }
    }
    
	#$result = $self->{snmp}->get_leef(oids => [ $oid_astConfigCallsActive ], nothing_quit => 1);
    #my $astConfigCallsActive = $result->{$oid_astConfigCallsActive};
    
    # compute status based on total number of active calls
    my $exit_code = $self->{perfdata}->threshold_check(value => $astConfigCallsActive, 
                              threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    push @msg, {msg => sprintf("Current external calls: %s", $astConfigCallsActive)};
    
    # Perfdata on all active calls
    $self->{output}->perfdata_add(label => 'Total calls',
                                  value => $astConfigCallsActive,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    # Perfdata on number of calls for each trunk
    my ($temp_exit, $exit_msg);
    my (@trunk_msg, @out_msg);
    my $trunk_exit_code = 'ok';
    foreach $value (@callsbytrunk)
    {
    	$temp_exit = $self->{perfdata}->threshold_check(value => $value->{num}, 
                              threshold => [ { label => 'critontrunk', exit_litteral => 'critical' }, { label => 'warnontrunk', exit_litteral => 'warning' } ]);
    	$self->{output}->perfdata_add(label => $value->{trunk},
                                  value => $value->{num},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warnontrunk'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critontrunk'),
                                  min => 0);
        $self->{output}->output_add(long_msg => sprintf("%s : %s", $value->{trunk}, $value->{num}));

        $trunk_exit_code = $self->{output}->get_most_critical(status => [ $temp_exit, $trunk_exit_code ]);
        # create msg for most critical data ....
        if ($self->{output}->is_status(value => $temp_exit, compare => $trunk_exit_code, litteral => 1))
        {
        	push @trunk_msg, {msg => sprintf("'%s': %s", $value->{trunk}, $value->{num})};
        }
    }
    if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1) && !$self->{output}->is_status(value => $trunk_exit_code, compare => 'ok', litteral => 1))
    {
    	unshift @trunk_msg, @msg;
    	$exit_code = $self->{output}->get_most_critical(status => [ $exit_code, $trunk_exit_code ]);
    }
    if (!$self->{output}->is_status(value => $trunk_exit_code, compare => 'ok', litteral => 1))
    {
    	@out_msg=@trunk_msg;
    	$exit_code = $trunk_exit_code ;
    }
    else
    {
    	push @out_msg, @msg;
    }
    
    $exit_msg = '';
    my $separator = '';
    foreach my $out (@out_msg)
    {
    	$exit_msg .= $separator.$out->{msg};
    	$separator = ', ';
    }
    $self->{output}->output_add(severity => $exit_code,
                                short_msg => $exit_msg
                                );
                                                            
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check number of external calls (total and by trunk)

=over 8

=item B<--warning>

Threshold warning for total number of external calls.

=item B<--critical>

Threshold critical for total number of external calls.

=item B<--warnontrunk>

Threshold warning for trunks.

=item B<--critontrunk>

Threshold critical for trunks.

=item B<--force-oid>

Can choose your oid (numeric format only).

=item B<--trunkusernamelist>

List of outgoing trunks' username.

=item B<--filter-name>

Filter on trunk's username (regexp can be used).

=back

=cut