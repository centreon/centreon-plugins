#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package apps::kayako::sql::mode::ticketcount;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use Time::Local;

my $ticket_total = 0;
my %tickets;
my $label;
my $start = "";
my $end = "";
my $priority_filter;
my @priority_filters;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "reload-cache-time:s"    => { name => 'reload_cache_time', default => 180 },
        "department-id:s"        => { name => 'department_id' },
        "staff-id:s"             => { name => 'staff_id' },
        "status-id:s"            => { name => 'status_id' },
        "priority-id:s"          => { name => 'priority_id' },
        "warning:s"              => { name => 'warning' },
        "critical:s"             => { name => 'critical' },
        "start-date:s"           => { name => 'start_date' },
        "end-date:s"             => { name => 'end_date' }
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{start_date})) {
        if ($self->{option_results}->{start_date} !~ m/^\d{1,2}-\d{1,2}-\d{4}$/){
            $self->{output}->add_option_msg(short_msg => "Please specify a valid date (DD-MM-YYYY).");
            $self->{output}->option_exit();   
        } else {
            my ($mday,$mon,$year) = split(/-/, $self->{option_results}->{'start_date'});
            $start = $self->{option_results}->{start_date};
            $self->{option_results}->{start_date} = timelocal(0,0,0,$mday,$mon-1,$year);
        }
    }
    if (defined($self->{option_results}->{end_date})) {
        if ($self->{option_results}->{end_date} !~ m/^\d{1,2}-\d{1,2}-\d{4}$/){
            $self->{output}->add_option_msg(short_msg => "Please specify a valid date (DD-MM-YYYY).");
            $self->{output}->option_exit();
        } else {
            my ($mday,$mon,$year) = split(/-/, $self->{option_results}->{end_date});
            $end = $self->{option_results}->{end_date};
            $self->{option_results}->{end_date} = timelocal(59,59,23,$mday,$mon-1,$year);
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
    if (defined($self->{option_results}->{priority_id})) {
        @priority_filters = split(/,/, $self->{option_results}->{priority_id});
    }

    $self->{statefile_cache}->check_options(%options);
}

sub reload_cache {
    my ($self) = @_;
    my $datas = {};

    $datas->{last_timestamp} = time();

    $self->{sql}->query(query => "SELECT departmentid, title FROM swdepartments");
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        $datas->{"department_" . $row->{departmentid}} = $self->{output}->decode($row->{title});
    }

    $self->{sql}->query(query => "SELECT priorityid, title FROM swticketpriorities");
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        $datas->{"priority_" . $row->{priorityid}} = $self->{output}->decode($row->{title});
    }

    $self->{sql}->query(query => "SELECT staffid, username FROM swstaff");
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        $datas->{"staff_" . $row->{staffid}} = $self->{output}->decode($row->{username});
    }

    $self->{sql}->query(query => "SELECT ticketstatusid, title FROM swticketstatus");
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        $datas->{"status_" . $row->{ticketstatusid}} = $self->{output}->decode($row->{title});
    }

    $self->{statefile_cache}->write(data => $datas);
}

sub run {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};
    
    $self->{sql}->connect();
    
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
        if (defined($self->{option_results}->{priority_id})) {
            foreach $priority_filter (@priority_filters) {
                if ($priority_filter == $row->{priorityid}) {
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
    my $exit = $self->{perfdata}->threshold_check(value => $ticket_total, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    my $staff = "";
    my $ticket_status = "";
    my $period = "";
   
    if (defined($self->{option_results}->{staff_id}) && ($self->{option_results}->{staff_id} =~ m/^\d*$/)) {
        $staff = " for staff '" . $self->{statefile_cache}->get(name => 'staff_'.$self->{option_results}->{'staff_id'}) ."'";
    }

    if (defined($self->{option_results}->{status_id}) && ($self->{option_results}->{status_id} =~ m/^\d*$/)) {
        $ticket_status = " in status '" . $self->{statefile_cache}->get(name => 'status_'.$self->{option_results}->{'status_id'}) ."'";
    }

    if (defined($self->{option_results}->{start_date}) || defined($self->{option_results}->{end_date})){
        $period = " -";
    }

    if (defined($self->{option_results}->{start_date})){
        $start = " Start: " . $start;
    }

    if (defined($self->{option_results}->{end_date})){
        $end = " End: " . $end;
    }

    if (defined($self->{option_results}->{priority_id})) {
        foreach $priority_filter (@priority_filters) {
            $label = $self->{statefile_cache}->get(name => 'priority_' . $priority_filter);
            $self->{output}->perfdata_add(label => $label, value => $tickets{$priority_filter},
                                          min => 0, max => $ticket_total);
        }
    }
    $self->{output}->perfdata_add(label => 'Total', value => $ticket_total,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

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
