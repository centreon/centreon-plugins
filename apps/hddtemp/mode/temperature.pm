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
####################################################################################

package apps::hddtemp::mode::temperature;

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
            "name:s"                => { name => 'name' },
            "warning:s"             => { name => 'warning' },
            "critical:s"            => { name => 'critical' },
            "regexp"                => { name => 'use_regexp' },
            "regexp-isensitive"     => { name => 'use_regexpi' },
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
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }

}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $oSocketConn = new IO::Socket::INET ( Proto      => 'tcp', 
                                             PeerAddr   => $self->{option_results}->{hostname},
                                             PeerPort   => $self->{option_results}->{port},
                                             Timeout    => $self->{option_results}->{timeout},
                                           ) || $self->{output}->add_option_msg(short_msg => "Could not connect.") ; $self->{output}->option_exit();
    
    #|/dev/sda|SD280813AS|35|C|#|/dev/sdb|ST2000CD005-1CH134|35|C|

    my $_ =  <$oSocketConn>;
    $oSocketConn->shutdown(2);

    while (m/\|([^|]+)\|([^|]+)\|([^|]+)\|(C|F)\|/g) {
        my ($drive, $serial, $temperature, $unit) = ($1, $2, $3, $4);

        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) 
            && $drive !~ /$self->{option_results}->{name}/i);
        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) 
            && $drive !~ /$self->{option_results}->{name}/);
        next if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi})
            && $drive ne $self->{option_results}->{name});

        $self->{result}->{$drive} = {serial => $serial, temperature => $temperature, unit => $unit};
    }

    if (scalar(keys %{$self->{result}}) <= 0) {
        if (defined($self->{option_results}->{name})) {
            $self->{output}->add_option_msg(short_msg => "No drives found for name '" . $self->{option_results}->{name} . "'.");
        } else {
            $self->{output}->add_option_msg(short_msg => "No drives found.");
        }
        $self->{output}->option_exit();
    }

}

sub run {
    my ($self, %options) = @_;
    
    $self->manage_selection();

    if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All Harddrive Temperatures are ok.');
    };

    foreach my $name (sort(keys %{$self->{result}})) {
        my $exit = $self->{perfdata}->threshold_check(value => $self->{result}->{$name}->{temperature}, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

        $self->{output}->output_add(long_msg => sprintf("Harddrive '%s' Temperature : %s", $name,
                                       $self->{result}->{$name}->{temperature}));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Harddrive '%s' Temperature : %s", $name,
                                        $self->{result}->{$name}->{temperature}));
        }

        my $extra_label = '';
        $extra_label = '_' . $name if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp}));
        $self->{output}->perfdata_add(label => 'temp' . $extra_label,
                                      unit => $self->{result}->{$name}->{unit},
                                      value => sprintf("%.2f", $self->{result}->{$name}->{temperature}),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
    };

    $self->{output}->display();
    $self->{output}->exit();
};

1;

__END__

=head1 MODE

Check HDDTEMP Temperature by Socket Connect

=over 8

=item B<--hostname>

IP Address or FQDN of the Server

=item B<--port>

Port used by Hddtemp (Default: 7634)

=item B<--timeout>

Set Timeout for Socketconnect

=item B<--warning>

Warning Threshold for Temperature

=item B<--critical>

Critical Threshold for Temperature

=item B<--name>

Set the Harddrive name (empty means 'check all Harddrives')

=item B<--regexp>

Allows to use regexp to filter Harddrive (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=back

=cut
