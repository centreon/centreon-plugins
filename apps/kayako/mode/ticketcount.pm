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
# Author : Stéphane DURET <sduret@merethis.com>
#
####################################################################################

package apps::kayako::mode::ticketcount;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use centreon::plugins::httplib;
use XML::XPath;
use Digest::SHA qw(hmac_sha256_base64);
use Time::Local;

my $url_original_path;
my $start = "";
my $end = "";
my $priority_filter;
my @priority_filters;
my $ticket_total = 0;
my %tickets;
my $label;
my %handlers = (ALRM => {} );

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
         {
		"hostname:s"            => { name => 'hostname' },
		"port:s"                => { name => 'port' },
		"proto:s"               => { name => 'proto', default => "http" },
		"urlpath:s"             => { name => 'url_path', default => '/api/index.php?' },
		"kayako-api-key:s"		=> { name => 'kayako_api_key' },
		"kayako-secret-key:s"	=> { name => 'kayako_secret_key' },
		"reload-cache-time:s"   => { name => 'reload_cache_time', default => 180 },
		"department-id:s"		=> { name => 'department_id' },
        "staff-id:s"			=> { name => 'staff_id' },
        "status-id:s"			=> { name => 'status_id' },
		"priority-id:s"			=> { name => 'priority_id' },
		"warning:s"				=> { name => 'warning' },
        "critical:s"            => { name => 'critical' },
		"start-date:s"			=> { name => 'start_date' },
        "end-date:s"			=> { name => 'end_date' },
         });
    $self->set_signal_handlers;
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_signal_handlers {
    my $self = shift;

    $SIG{ALRM} = \&class_handle_ALRM;
    $handlers{ALRM}->{$self} = sub { $self->handle_ALRM() };
}

sub class_handle_ALRM {
    foreach (keys %{$handlers{ALRM}}) {
        &{$handlers{ALRM}->{$_}}();
    }
}

sub handle_ALRM {
    my $self = shift;
    
    $self->{output}->output_add(severity => 'UNKNOWN',
                                short_msg => sprintf("Cannot finished API execution (timeout received)"));
    $self->{output}->display();
    $self->{output}->exit();
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{timeout}) && $self->{option_results}->{timeout} =~ /^\d+$/ &&
        $self->{option_results}->{timeout} > 0) {
        alarm($self->{option_results}->{timeout});
    }
    if (!defined($self->{option_results}->{'kayako_api_key'})) {
        $self->{output}->add_option_msg(short_msg => "Please specify an API key for Kayako.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{'kayako_secret_key'})) {
        $self->{output}->add_option_msg(short_msg => "Please specify a secret key for Kayako.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{'department_id'})) {
        $self->{output}->add_option_msg(short_msg => "Please specify at least one department ID.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{'staff_id'})) {
		$self->{option_results}->{'staff_id'} = "-1";
    }
    if (!defined($self->{option_results}->{'status_id'})) {
		$self->{option_results}->{'status_id'} = "-1";
    }
	if (defined($self->{option_results}->{'priority_id'})) {
		@priority_filters = split(/,/, $self->{option_results}->{'priority_id'});
	}
    if (defined($self->{option_results}->{'start_date'})) {
		if ($self->{option_results}->{'start_date'} !~ m/^\d{1,2}-\d{1,2}-\d{4}$/){
			$self->{output}->add_option_msg(short_msg => "Please specify a valid date (DD-MM-YYYY).");
			$self->{output}->option_exit();	
		} else {
			my ($mday,$mon,$year) = split(/-/, $self->{option_results}->{'start_date'});
			$start = $self->{option_results}->{'start_date'};
			$self->{option_results}->{'start_date'} = timelocal(0,0,0,$mday,$mon-1,$year);
		}
	}
    if (defined($self->{option_results}->{'end_date'})) {
        if ($self->{option_results}->{'end_date'} !~ m/^\d{1,2}-\d{1,2}-\d{4}$/){
            $self->{output}->add_option_msg(short_msg => "Please specify a valid date (DD-MM-YYYY).");
            $self->{output}->option_exit();
        } else {
            my ($mday,$mon,$year) = split(/-/, $self->{option_results}->{'end_date'});
			$end = $self->{option_results}->{'end_date'};
            $self->{option_results}->{'end_date'} = timelocal(59,59,23,$mday,$mon-1,$year);
        }
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
    
	$self->{statefile_cache}->check_options(%options);
    $self->{statefile_value}->check_options(%options);
}

sub reload_cache {
    my ($self) = @_;
    my $datas = {};

    $datas->{last_timestamp} = time();
	
	my $salt;
    $salt .= int(rand(10)) for 1..10;
    my $digest = hmac_sha256_base64 ($salt, $self->{option_results}->{'kayako_secret_key'});
	$self->{option_results}->{'url_path'} = $url_original_path . "/Base/Department&apikey=" . $self->{option_results}->{'kayako_api_key'} . "&salt=" . $salt . "&signature=" . $digest . "=";
	my $webcontent = centreon::plugins::httplib::connect($self);
    my $xp = XML::XPath->new( $webcontent );
    my $nodes = $xp->find('departments/department');
    foreach my $actionNode ($nodes->get_nodelist) {
        my ($id) = $xp->find('./id', $actionNode)->get_nodelist;
        my $trim_id = centreon::plugins::misc::trim($id->string_value);
        my ($title) = $xp->find('./title', $actionNode)->get_nodelist;
        my $trim_title = centreon::plugins::misc::trim($title->string_value);
		$datas->{"department_".$trim_id} = $self->{output}->to_utf8($trim_title);
	}

	$self->{option_results}->{'url_path'} = $url_original_path . "/Tickets/TicketPriority&apikey=" . $self->{option_results}->{'kayako_api_key'} . "&salt=" . $salt . "&signature=" . $digest . "=";
    $webcontent = centreon::plugins::httplib::connect($self);
    $xp = XML::XPath->new( $webcontent );
    $nodes = $xp->find('ticketpriorities/ticketpriority');
    foreach my $actionNode ($nodes->get_nodelist) {
        my ($id) = $xp->find('./id', $actionNode)->get_nodelist;
        my $trim_id = centreon::plugins::misc::trim($id->string_value);
        my ($title) = $xp->find('./title', $actionNode)->get_nodelist;
        my $trim_title = centreon::plugins::misc::trim($title->string_value);
        $datas->{"priority_".$trim_id} = $self->{output}->to_utf8($trim_title);
    }

    $self->{option_results}->{'url_path'} = $url_original_path . "/Base/Staff&apikey=" . $self->{option_results}->{'kayako_api_key'} . "&salt=" . $salt . "&signature=" . $digest . "=";
    $webcontent = centreon::plugins::httplib::connect($self);
    $xp = XML::XPath->new( $webcontent );
    $nodes = $xp->find('staffusers/staff');
    foreach my $actionNode ($nodes->get_nodelist) {
        my ($id) = $xp->find('./id', $actionNode)->get_nodelist;
        my $trim_id = centreon::plugins::misc::trim($id->string_value);
        my ($title) = $xp->find('./username', $actionNode)->get_nodelist;
        my $trim_title = centreon::plugins::misc::trim($title->string_value);
        $datas->{"staff_".$trim_id} = $self->{output}->to_utf8($trim_title);
    }

	$self->{option_results}->{'url_path'} = $url_original_path . "/Tickets/TicketStatus&apikey=" . $self->{option_results}->{'kayako_api_key'} . "&salt=" . $salt . "&signature=" . $digest . "=";
    $webcontent = centreon::plugins::httplib::connect($self);
    $xp = XML::XPath->new( $webcontent );
    $nodes = $xp->find('ticketstatuses/ticketstatus');
	foreach my $actionNode ($nodes->get_nodelist) {
        my ($id) = $xp->find('./id', $actionNode)->get_nodelist;
        my $trim_id = centreon::plugins::misc::trim($id->string_value);
        my ($title) = $xp->find('./title', $actionNode)->get_nodelist;
        my $trim_title = centreon::plugins::misc::trim($title->string_value);
        $datas->{"status_".$trim_id} = $self->{output}->to_utf8($trim_title);
    }

    $self->{statefile_cache}->write(data => $datas);
}

sub run {
    my ($self, %options) = @_;
	my $salt;
	$salt .= int(rand(10)) for 1..10;
	my $digest = hmac_sha256_base64 ($salt, $self->{option_results}->{'kayako_secret_key'});
	$url_original_path = $self->{option_results}->{'url_path'};

    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_api_' . ($self->{option_results}->{hostname})  . '_kayako');
    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    if ($has_cache_file == 0 ||
        !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {
            $self->reload_cache();
            $self->{statefile_cache}->read();
    }
	
	$self->{option_results}->{'url_path'} = $url_original_path . "/Tickets/Ticket/ListAll/" . $self->{option_results}->{'department_id'} . "/" . $self->{option_results}->{'status_id'} . "/" . $self->{option_results}->{'staff_id'} . "/-1/-1/1420120620/-1/-1&apikey=" . $self->{option_results}->{'kayako_api_key'} . "&salt=" . $salt . "&signature=" . $digest . "=";
	my $webcontent = centreon::plugins::httplib::connect($self);
	my $xp = XML::XPath->new( $webcontent );
	my $nodes = $xp->find('tickets/ticket');

	foreach my $actionNode ($nodes->get_nodelist) {
		my $date_verif = 0;
		my ($id) = $xp->find('./displayid', $actionNode)->get_nodelist;
		my $trim_id = centreon::plugins::misc::trim($id->string_value);
		my ($priorityid) = $xp->find('./priorityid', $actionNode)->get_nodelist;
		my $trim_priorityid = centreon::plugins::misc::trim($priorityid->string_value);
		my ($date) = $xp->find('./lastactivity', $actionNode)->get_nodelist;
		my $trim_date = centreon::plugins::misc::trim($date->string_value);
		if (defined($self->{option_results}->{'start_date'}) and (defined($self->{option_results}->{'end_date'}))) {
			if ($trim_date > $self->{option_results}->{'start_date'} and $trim_date < $self->{option_results}->{'end_date'}) {
				if (defined($self->{option_results}->{'priority_id'})){
					foreach $priority_filter (@priority_filters) {
						if ($priority_filter == $trim_priorityid){
							$tickets{$priority_filter}++;
							$ticket_total++;
						}
					}
				} else {
					$ticket_total++;
				}
			}
		} elsif (defined($self->{option_results}->{'start_date'}) and (!defined($self->{option_results}->{'end_date'}))) {
			if ($trim_date > $self->{option_results}->{'start_date'}) {
                if (defined($self->{option_results}->{'priority_id'})){
                    foreach $priority_filter (@priority_filters) {
                        if ($priority_filter == $trim_priorityid){
                            $tickets{$priority_filter}++;
                            $ticket_total++;
                        }
                    }
                } else {
                    $ticket_total++;
                }
			}
        } elsif (!defined($self->{option_results}->{'start_date'}) and (defined($self->{option_results}->{'end_date'}))) {
            if ($trim_date < $self->{option_results}->{'end_date'}) {
                if (defined($self->{option_results}->{'priority_id'})){
                    foreach $priority_filter (@priority_filters) {
                        if ($priority_filter == $trim_priorityid){
                            $tickets{$priority_filter}++;
                            $ticket_total++;
                        }
                    }
                } else {
                    $ticket_total++;
                }
            }
        } else {
			if (defined($self->{option_results}->{'priority_id'})){
				foreach $priority_filter (@priority_filters) {
					if ($priority_filter == $trim_priorityid){
						$tickets{$priority_filter}++;
                        $ticket_total++;
					}
                }
			} else {
				$ticket_total++;
            }
		}
	}

###########
# Manage Output
###########
	my $exit = $self->{perfdata}->threshold_check(value => $ticket_total, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
	my $staff = "";
	my $ticket_status = "";
	my $period = "";
	
	if (defined($self->{option_results}->{'staff_id'}) && ($self->{option_results}->{'staff_id'} =~ m/^\d*$/)) {
        $staff = " for staff '" . $self->{statefile_cache}->get(name => 'staff_'.$self->{option_results}->{'staff_id'}) ."'";
    }

    if (defined($self->{option_results}->{'status_id'}) && ($self->{option_results}->{'status_id'} =~ m/^\d*$/)) {
        $ticket_status = " in status '" . $self->{statefile_cache}->get(name => 'status_'.$self->{option_results}->{'status_id'}) ."'";
    }

    if (defined($self->{option_results}->{'start_date'}) || defined($self->{option_results}->{'end_date'})){
        $period = " -";
    }

    if (defined($self->{option_results}->{'start_date'})){
		$start = " Start: " . $start;
    }

	if (defined($self->{option_results}->{'end_date'})){
		$end = " End: " . $end;
	}

	if (defined($self->{option_results}->{'priority_id'})){
		foreach $priority_filter (@priority_filters) {
			$label = $self->{statefile_cache}->get(name => 'priority_'.$priority_filter);
			$self->{output}->perfdata_add(label => $label, value => $tickets{$priority_filter},
											min => 0, max => $ticket_total);
		}
	}
	$self->{output}->perfdata_add(label => 'Total', value => $ticket_total,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));

	$self->{output}->output_add(severity => $exit,
								short_msg => sprintf("%s tickets%s%s%s%s%s", $ticket_total, $staff, $ticket_status, $period, $start, $end));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Count tickets of kayako 

=over 8

=item B<--hostname>

IP Addr/FQDN of the webserver host (required)

=item B<--port>

Port used by Apache

=item B<--proto>

Specify https if needed

=item B<--proxyurl>

Proxy URL if any

=item B<--kayako-api-url>

This is the URL you should dispatch all GET, POST, PUT & DELETE requests to. (required)

=item B<--kayako-api-key>

This is your unique API key. (required)

=item B<--kayako-secret-key>

The secret key is used to sign all the requests dispatched to Kayako. (required)

=item B<--reload-cache-time>

Time in seconds before reloading cache file (default: 180).

=item B<--department-id>

Filter the tickets by the specified department id, you can specify multiple id's by separating the values using a comma. Example: 1,2,3 .
You must define at least one id. (required)

=item B<--priority-id>

Filter the tickets by the specified ticket priority id, you can specify multiple id's by separating the values using a comma. Example: 1,2,3 .
By default, all ticket priority are included.

=item B<--staff-id>

Filter the tickets by the specified owner staff id, you can specify multiple id's by separating the values using a comma. Example: 1,2,3 .
By default, all staff users are included.

=item B<--status-id>

Filter the tickets by the specified ticket status id, you can specify multiple id's by separating the values using a comma. Example: 1,2,3 .
By default, the filter is on unresolved ticket statuses.

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--start-date>

Filter on last activity. For example: 21-03-2014

=item B<--end-date>

Filter on last activity. For example: 21-03-2014

=back

=cut
