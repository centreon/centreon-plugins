#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package database::oracle::mode::dataguardlag;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use DateTime;

sub new {
	my ($class, %options) = @_;
	my $self = $class->SUPER::new(package => __PACKAGE__, %options);
	bless $self, $class;
	
	$options{options}->add_options(arguments => { 
		"warning:s"               => { name => 'warning', },
		"critical:s"              => { name => 'critical', },
		"warning-sequence:s"      => { name => 'warning_sequence', },
		"critical-sequence:s"     => { name => 'critical_sequence', },
		"filter-destination:s"    => { name => 'filter_destination', },
		"timezone:s"              => { name => 'timezone', },
	});

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

	if (($self->{perfdata}->threshold_validate(label => 'warning_sequence', value => $self->{option_results}->{warning_sequence})) == 0) {
		$self->{output}->add_option_msg(short_msg => "Wrong warning-sequence threshold '" . $self->{option_results}->{warning_sequence} . "'.");
		$self->{output}->option_exit();
	}

	if (($self->{perfdata}->threshold_validate(label => 'critical_sequence', value => $self->{option_results}->{critical_sequence})) == 0) {
		$self->{output}->add_option_msg(short_msg => "Wrong critical-sequence threshold '" . $self->{option_results}->{critical_sequence} . "'.");
		$self->{output}->option_exit();
	}

	if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
		$ENV{TZ} = $self->{option_results}->{timezone};
	}
}

sub run {
	my ($self, %options) = @_;
	# $options{sql} = sqlmode object
	$self->{sql} = $options{sql};

	$self->{sql}->connect();
	my $query = q{SELECT a.sequence#,
					  ((a.first_time - date '1970-01-01')*24*60*60) as first_time,
					   a.applied,
					  ((a.completion_time - date '1970-01-01')*24*60*60) as completion_time,
					   a.archival_thread#,
					   c.destination
				  FROM v$archived_log a ,
					   ( SELECT MAX(SEQUENCE#) max_seq,
								thread#,
								ARCHIVED,
								applied,
								dest_id 
						   FROM v$archived_log
						  WHERE DEST_ID IN ( SELECT DEST_ID FROM v$archive_dest WHERE STATUS='VALID' AND TARGET='STANDBY' ) AND applied = 'YES'
						  GROUP BY thread#,ARCHIVED,applied,dest_id 
						  UNION
						 SELECT sequence#,
								thread#,
								ARCHIVED,
								applied,
								dest_id 
						   FROM v$archived_log
						  WHERE DEST_ID IN ( SELECT DEST_ID FROM v$archive_dest WHERE STATUS='VALID' AND TARGET='STANDBY' ) AND applied = 'NO'
						) b,
						v$archive_dest c
				 WHERE a.sequence#=b.max_seq
				   AND a.archival_thread#=b.thread#
				   AND a.dest_id=b.dest_id
				   AND a.dest_id = c.dest_id
	};

	$self->{sql}->query(query => $query);
	my $result = $self->{sql}->fetchall_arrayref();
	$self->{sql}->disconnect();

	$self->{output}->output_add(severity => 'OK',
								short_msg => sprintf("Archived logs are all applied."));
								
	$self->{destinations} = {};
	foreach my $row (@$result) {
		my ($sequencenum, $first_time, $applied, $completion_time, $archival_threadnum, $destination) = @$row;

		if (defined($self->{option_results}->{filter_destination}) && $self->{option_results}->{filter_destination} ne '' &&
			$destination !~ /$self->{option_results}->{filter_destination}/) {
			$self->{output}->output_add(long_msg => "skipping  '" . $destination . "': no matching filter destination.", debug => 1);
			next;
		}

		if (!defined($self->{destinations}->{$destination})) {
			$self->{destinations}->{$destination} = { count => 0, archlog_age => 0};
		}
		
		if ($applied eq 'YES') {
			my @values = localtime($completion_time);
			my $dt = DateTime->new(
							year       => $values[5] + 1900,
							month      => $values[4] + 1,
							day        => $values[3],
							hour       => $values[2],
							minute     => $values[1],
							second     => $values[0],
							time_zone  => 'UTC',
			);
			my $offset = $completion_time - $dt->epoch;
			$completion_time = $completion_time + $offset;			

			my $archlog_age = time() - $completion_time;
		
			if ($archlog_age > $self->{destinations}->{$destination}->{archlog_age}) {
				$self->{destinations}->{$destination}->{archlog_age} = $archlog_age;
			}
		} else {
			$self->{destinations}->{$destination}->{count}++;
		}
	}

	foreach my $destination (keys %{$self->{destinations}}) {
		my $count = $self->{destinations}->{$destination}->{count};
		my $archlog_age = $self->{destinations}->{$destination}->{archlog_age};
		my $archlog_age_convert = centreon::plugins::misc::change_seconds(value => $archlog_age);
		my $exit_code;

		$exit_code = $self->{perfdata}->threshold_check(value => $archlog_age,
							   threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
		$self->{output}->output_add(severity => $exit_code,
									short_msg => sprintf("Last Archived log applied on destination '%s': %s", $destination, $archlog_age_convert));
		$self->{output}->perfdata_add(label => 'archlog_age_' . $destination,
									  value => $archlog_age,
									  unit => 's',
									  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
									  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
									  min => 0);

		$exit_code = $self->{perfdata}->threshold_check(value => $count,
							   threshold => [ { label => 'critical_sequence', 'exit_litteral' => 'critical' }, { label => 'warning_sequence', exit_litteral => 'warning' } ]);
		$self->{output}->output_add(severity => $exit_code,
									short_msg => sprintf("%d Archived log not applied on destination '%s'", $count, $destination));
		$self->{output}->perfdata_add(label => 'archlog_lag_' . $destination,
									  value => $count,
									  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_sequence'),
									  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_sequence'),
									  min => 0);
	}
	
	$self->{output}->display();
	$self->{output}->exit();
}	
	
1;

__END__

=head1 MODE

Check Oracle DataGuard lag.

=over 8

=item B<--warning>

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=item B<--warning-sequence>

Threshold warning in number of sequence.

=item B<--critical-sequence>

Threshold critical in number of sequence.

=item B<--filter-destination>

Filter archived logs destination

=item B<--timezone>

Timezone of oracle server (If not set, we use current server execution timezone).

=back

=cut
