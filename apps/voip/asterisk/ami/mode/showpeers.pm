################################################################################
# Copyright 2005-2015 MERETHIS
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
# Authors : Mathieu Cinquin <mcinquin@merethis.com>
#
####################################################################################

package apps::voip::asterisk::ami::mode::showpeers;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use apps::voip::asterisk::ami::lib::ami;

use Data::Dumper;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "hostname:s"        => { name => 'hostname' },
                                  "port:s"            => { name => 'port', default => 5038 },
                                  "username:s"          => { name => 'username' },
                                  "password:s"          => { name => 'password' },
                                  "filter-name:s"     => { name => 'filter_name', },
                                  "timeout:s"         => { name => 'timeout', default => 20 },
                                  "protocol:s"        => { name => 'protocol', },
                              });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the --hostname option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{username})) {
        $self->{output}->add_option_msg(short_msg => "Please set the --username option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{password})) {
        $self->{output}->add_option_msg(short_msg => "Please set the --password option");
        $self->{output}->option_exit();
    }

}


sub run {
    my ($self, %options) = @_;
    
    # Get data from asterisk
    apps::voip::asterisk::lib::ami::connect($self);
    if ($self->{option_results}->{protocol} eq 'sip' || $self->{option_results}->{protocol} eq 'SIP')
    {
    	$self->{command} = 'sip show peers';
    }
    elif ($self->{option_results}->{protocol} eq 'iax' || $self->{option_results}->{protocol} eq 'IAX')
    {
    	$self->{command} = 'iax2 show peers';
    }
    my @result = apps::voip::asterisk::lib::ami::action($self);
    apps::voip::asterisk::lib::ami::quit();
    
    # Compute data
    foreach my $line (@result) {
        next if ($line !~ /^(\w*)\/\w* .* (OK|Unreachable) \((.*)\)/);
        my ($trunkname, $trunkstatus, $trunkvalue) = ($1, $2, $3);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $trunkname !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping trunk '" . $trunkname . "': no matching filter name");
            next;
        }
        	
        $self->{result}->{$trunkname} = {name => $trunkname, status => $trunkstatus, value => $trunkvalue};
    }
    
    # Send formated data to Centreon
    my $msg;
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'Everything is OK');

    foreach my $name (sort(keys %{$self->{result}})) {
        $msg = sprintf("Trunk: %s %s", $self->{result}->{$name}->{name}, $self->{result}->{$name}->{status});
        $self->{output}->perfdata_add(label => $self->{result}->{$name}->{name},
                                  value => $self->{result}->{$name}->{value},
                                  # keep this lines for future upgrade of this plugin
                                  #warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1'),
                                  #critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1'),
                                  min => 0);
        if (!$self->{output}->is_status(value => $self->{result}->{$name}->{status}, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $self->{result}->{$name}->{status},
                                        short_msg => $msg);
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Show peers for different protocols.

=over 8

=item B<--hostname>

Hostname to query.

=item B<--port>

port to connect.

=item B<--username>

username for conection.

=item B<--password>

password for conection.

=item B<--filter-name>

Filter on trunkname (regexp can be used).

=item B<--timeout>

connection timeout.

=item B<--protocol>

show peer for this protocol (sip or iax).

=back

=cut
