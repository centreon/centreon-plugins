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

package os::aix::local::mode::errpt;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'error-type:s'      => { name => 'error_type' },
        'error-class:s'     => { name => 'error_class' },
        'error-id:s'        => { name => 'error_id' },
        'retention:s'       => { name => 'retention' },
        'timezone:s'        => { name => 'timezone' },
        'description'       => { name => 'description' },
        'filter-resource:s' => { name => 'filter_resource' },
        'filter-id:s'	    => { name => 'filter_id' },
        'exclude-id:s'      => { name => 'exclude_id' },
        'format-date'       => { name => 'format_date' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{exclude_id}) && defined($self->{option_results}->{error_id})) {
        $self->{output}->add_option_msg(short_msg => "Please use --error-id OR --exclude-id, these options are mutually exclusives");
    	$self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $extra_options = '';
    if (defined($self->{option_results}->{error_type})){
        $extra_options .= ' -T '.$self->{option_results}->{error_type};
    }
    if (defined($self->{option_results}->{error_class})){
        $extra_options .= ' -d '.$self->{option_results}->{error_class};
    }
    if (defined($self->{option_results}->{error_id}) && $self->{option_results}->{error_id} ne ''){
    	$extra_options.= ' -j '.$self->{option_results}->{error_id};
    }
    if (defined($self->{option_results}->{exclude_id}) && $self->{option_results}->{exclude_id} ne ''){
    	$extra_options.= ' -k ' . $self->{option_results}->{exclude_id};
    }
    if (defined($self->{option_results}->{retention}) && $self->{option_results}->{retention} ne ''){
        my $retention = time() - $self->{option_results}->{retention};
        if (defined($self->{option_results}->{timezone})){
            $ENV{TZ} = $self->{option_results}->{timezone};
        }
        my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($retention);
        $year = $year - 100;
        if (length($sec) == 1){
            $sec = '0' . $sec;
        }
        if (length($min) == 1){
            $min = '0' . $min;
        }
        if (length($hour) == 1){
            $hour = '0' . $hour;
        }
        if (length($mday) == 1){
            $mday = '0' . $mday;
        }
        $mon = $mon + 1;
        if (length($mon) == 1){
            $mon = '0' . $mon;
        }
        $retention = $mon . $mday . $hour . $min . $year;
        $extra_options .= ' -s '.$retention;
    }

    my ($stdout) = $options{custom}->execute_command(
        command => 'errpt',
        command_options => $extra_options
    );

    my $results = {};
    my @lines = split /\n/, $stdout;
    # Header not needed
    shift @lines;
    foreach my $line (@lines) {
        next if ($line !~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)/);
        
        my ($identifier, $timestamp, $resource_name, $description) = ($1, $2, $5, $6);
        $results->{ $timestamp . '~' . $identifier . '~' . $resource_name } = { description => $description };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $extra_message = '';
    if (defined($self->{option_results}->{retention})) {
        $extra_message = ' since ' . $self->{option_results}->{retention} . ' seconds';
    }

    my $results = $self->manage_selection(custom => $options{custom});
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => sprintf("No error found%s.", $extra_message)
    );

    my $total_error = 0;
    foreach my $errpt_error (sort(keys %$results)) {
	    my @split_error = split ('~', $errpt_error);
	    my $timestamp = $split_error[0];
        my $identifier = $split_error[1];
        my $resource_name = $split_error[2];
        my $description = $results->{$errpt_error}->{description};

        next if (defined($self->{option_results}->{filter_resource}) && $self->{option_results}->{filter_resource} ne '' &&
            $resource_name !~ /$self->{option_results}->{filter_resource}/);
        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $identifier !~ /$self->{option_results}->{filter_id}/);

        my $output_date = $split_error[0];
        if (defined($self->{option_results}->{format_date})) {
            my ($month, $day, $hour, $minute, $year) = unpack("(A2)*", $output_date);
            $output_date = sprintf("20%s/%s/%s %s:%s", $year, $month, $day, $hour, $minute);
        }

        $total_error++;
        if (defined($description)) {
            $self->{output}->output_add(
                long_msg => sprintf(
                    "Error '%s' Date: %s ResourceName: %s Description: %s",
                    $identifier,
                    $output_date,
                    $resource_name,
                    $description
                )
            );           
        } else {
            $self->{output}->output_add(
                long_msg => sprintf(
                    "Error '%s' Date: %s ResourceName: %s",
                    $identifier,
                    $output_date,
                    $resource_name
                )
            );
        }
    }

    if ($total_error != 0) {
        $self->{output}->output_add(
            severity => 'critical',
            short_msg => sprintf("%s error(s) found(s)%s", $total_error, $extra_message)
        );
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check errpt messages.
Command used: 'errpt' with dynamic options

=over 8

=item B<--error-type>

Filter error type separated by a coma (INFO, PEND, PERF, PERM, TEMP, UNKN).

=item B<--error-class>

Filter error class ('H' for hardware, 'S' for software, '0' for errlogger, 'U' for undetermined).

=item B<--error-id>

Filter specific error code (can be a comma separated list).

=item B<--retention>

Retention time of errors in seconds.

=item B<--verbose>

Print error description in long output. [ Error 'CODE' Date: Timestamp ResourceName: RsrcName Description: Desc ]

=item B<--filter-resource>

Filter resource (can use a regexp).

=item B<--filter-id>

Filter error code (can use a regexp).

=item B<--exclude-id>

Filter on specific error code (can be a comma separated list).

=item B<--format-date>

Print the date to format 20YY/mm/dd HH:MM instead of mmddHHMMYY.

=back

=cut
