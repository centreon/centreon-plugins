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

package apps::kayako::sql::mode::ticketcount;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use Time::Local;

my $ticket_total = 0;
my %tickets;
my $label;
my %handlers = (ALRM => {} );
my $start = "";
my $end = "";
my $priority_filter;
my @priority_filters;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
         {
            "reload-cache-time:s"   => { name => 'reload_cache_time', default => 180 },
            "department-id:s"	=> { name => 'department_id' },
            "staff-id:s" 	    => { name => 'staff_id' },
            "status-id:s"	    => { name => 'status_id' },
	        "priority-id:s"	    => { name => 'priority_id' },
	        "warning:s"		    => { name => 'warning' },
            "critical:s"        => { name => 'critical' },
	        "start-date:s"	    => { name => 'start_date' },
            "end-date:s"	    => { name => 'end_date' },
         });
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

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
    if (defined($self->{option_results}->{'priority_id'})) {
        @priority_filters = split(/,/, $self->{option_results}->{'priority_id'});
    }

    $self->{statefile_cache}->check_options(%options);
}

sub reload_cache {
    my ($self) = @_;
    my $datas = {};

    $datas->{last_timestamp} = time();

    $self->{sql}->query(query => "SELECT departmentid, title FROM swdepartments");
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        $datas->{"department_" . $row->{departmentid}} = $self->{output}->to_utf8($row->{title});
    }

    $self->{sql}->query(query => "SELECT priorityid, title FROM swticketpriorities");
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        $datas->{"priority_" . $row->{priorityid}} = $self->{output}->to_utf8($row->{title});
    }

    $self->{sql}->query(query => "SELECT staffid, username FROM swstaff");
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        $datas->{"staff_" . $row->{staffid}} = $self->{output}->to_utf8($row->{username});
    }

    $self->{sql}->query(query => "SELECT ticketstatusid, title FROM swticketstatus");
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        $datas->{"status_" . $row->{ticketstatusid}} = $self->{output}->to_utf8($row->{title});
    }

    $self->{statefile_cache}->write(data => $datas);
}

sub run {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};
    
    $self->{sql}->connect();

    if (!($self->{sql}->is_version_minimum(version => '5'))) {
        $self->{output}->add_option_msg(short_msg => "MySQL version '" . $self->{sql}->{version} . "' is not supported (need version >= '5.x').");
        $self->{output}->option_exit();
    }
    
    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_sql_' . $self->{sql}->get_unique_id4save() . '_kayako');
    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    if ($has_cache_file == 0 ||
        !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {
            $self->reload_cache();
            $self->{statefile_cache}->read();
    }

    my $query = "SELECT priorityid FROM swtickets WHERE ticketid IS NOT NULL";

    if (defined($self->{option_results}->{'department_id'})) {
        $query .= " AND departmentid IN (" . $self->{option_results}->{'department_id'} . ")";
    }
    if (defined($self->{option_results}->{'priority_id'})) {
        $query .= " AND priorityid IN (" . $self->{option_results}->{'priority_id'} . ")";
    }
    if (defined($self->{option_results}->{'staff_id'})) {
        $query .= " AND ownerstaffid IN (" . $self->{option_results}->{'staff_id'} . ")";
    }
    if (defined($self->{option_results}->{'status_id'})) {
        $query .= " AND ticketstatusid IN (" . $self->{option_results}->{'status_id'} . ")";
    }
    if (defined($self->{option_results}->{'start_date'})) {
        $query .= " AND lastactivity > " . $self->{option_results}->{'start_date'};
    }
    if (defined($self->{option_results}->{'end_date'})) {
        $query .= " AND lastactivity < " . $self->{option_results}->{'end_date'};
    }

    $self->{sql}->query(query => $query);

    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        if (defined($self->{option_results}->{'priority_id'})){
            foreach $priority_filter (@priority_filters) {
                if ($priority_filter == $row->{priorityid}){
                    $tickets{$priority_filter}++;
                    $ticket_total++;
                }
            }
        } else {
            $ticket_total++;
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
