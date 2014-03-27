###############################################################################
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
# permission to link this program with independent modules to produce an timeelapsedutable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting timeelapsedutable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Author : Florian Asche <info@florian-asche.de>
#
# Based on De Bodt Lieven plugin
# Based on Apache Mode by Simon BOMM
####################################################################################

package apps::hddtemp::mode::listdrives;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use IO::Socket;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
            {
            "hostname:s"            => { name => 'hostname' },
            "port:s"                => { name => 'port', default => '7634' },
            "timeout:s"             => { name => 'timeout', default => '10' },
            "filter-name:s"         => { name => 'filter_name', },
            });

    $self->{result} = {};
    $self->{hostname} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
        $self->{output}->option_exit();
    }

}

sub manage_selection {
    my ($self, %options) = @_;

    my $oSocketConn = new IO::Socket::INET ( Proto      => 'tcp', 
                                             PeerAddr   => $self->{option_results}->{hostname},
                                             PeerPort   => $self->{option_results}->{port},
                                             Timeout    => $self->{option_results}->{timeout},
                                           );
    
    if (!defined($oSocketConn)) {
        $self->{output}->add_option_msg(short_msg => "Could not connect.");
        $self->{output}->option_exit();
    }

    #|/dev/sda|SD280813AS|35|C|#|/dev/sdb|ST2000CD005-1CH134|35|C|

    my $line;
    
    eval {
        local $SIG{ALRM} = sub { die "Timeout by signal ALARM\n"; };
        alarm(10);
        $line = <$oSocketConn>;
        alarm(0);
    };
    $oSocketConn->shutdown(2);
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot get informations.");
        $self->{output}->option_exit();
    }

    while ($line =~ /\|([^|]+)\|([^|]+)\|([^|]+)\|(C|F)\|/g) {
        my ($drive, $serial, $temperature, $unit) = ($1, $2, $3, $4);
               
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                 $drive !~ /$self->{option_results}->{filter_name}/);

        $self->{result}->{$drive} = {serial => $serial, temperature => $temperature, unit => $unit};
    }
}

sub run {
    my ($self, %options) = @_;
    
    $self->manage_selection();

    my $drive_display = '';
    my $drive_display_append = '';
    foreach my $name (sort(keys %{$self->{result}})) {
        $drive_display .= $drive_display_append . 'name = ' . $name . ' [temperature = ' . $self->{result}->{$name}->{temperature} . $self->{result}->{$name}->{unit} . ']';
        $drive_display_append = ', ';
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List Drives: ' . $drive_display);
    $self->{output}->display(nolabel => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'temperature']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {     
        $self->{output}->add_disco_entry(name => $name,
                                         temperature => $self->{result}->{$name}->{temperature}
                                         );
    }
}

1;

__END__

=head1 MODE

List HDDTEMP Harddrives

=over 8

=item B<--hostname>

IP Address or FQDN of the Server

=item B<--port>

Port used by Hddtemp (Default: 7634)

=item B<--timeout>

Set Timeout for Socketconnect

=item B<--filter-name>

Filter Harddrive name (regexp can be used).

=back

=cut
