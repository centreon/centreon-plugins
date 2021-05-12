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
# Authors : Pedro Manuel Santos Delgado - lunik
#

package apps::whois::mode::whois;

use strict;
use warnings;
use base qw(centreon::plugins::mode);
use DateTime;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        "domain:s"            => { name => 'domain'},
        "whois_binary:s"      => { name => 'command', default => '/usr/bin/whois'},
        "timeout:s"           => { name => 'timeout', default => 3},
        "warning-days:s"      => { name => 'warning', default => "30:"},
        "critical-days:s"     => { name => 'critical', default => "10:"},
        "custom-date-regex:s" => { name => 'custom_date_regex', default => 'Expiry Date:\s+(\d{2})-(\d{2})-(\d{4})'}, # Regex for whois outcom
        "custom-date-map:s"   => { name => 'custom_date_map', default => "DMY"}, # day month year
    });
    # This method will execute the command, but will not let me parse the outcome
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    # Check domain has only two levels
    my $domain_levels = split('\.', $self->{option_results}->{domain});
    if ($domain_levels != 2){
        $self->{output}->add_option_msg(
            short_msg => "Wrong domain pattern '" . $self->{option_results}->{domain} . "'. Only DOMAIN.TLD supported");
        $self->{output}->option_exit();
    }
    # Check custom date regex has at least 3 groups 
    my $MinGroupCount = 3;
    my $opening_groups = ($self->{option_results}->{custom_date_regex} =~ tr/\(//);
    if ($opening_groups < $MinGroupCount) {
        $self->{output}->add_option_msg(short_msg => "Error. At least 3 groups needed on regex. found: " . $opening_groups);
        $self->{output}->option_exit();
    }
    my $closing_groups = ($self->{option_results}->{custom_date_regex} =~ tr/\)//);
    if ($opening_groups != $closing_groups) {
        $self->{output}->add_option_msg(short_msg => "Error. count of opening and closing parenthesis differ in regex: " . $opening_groups .'<>'. $closing_groups);
        $self->{output}->option_exit();
    }
    # Check custom date map has same number of groups as the regex, and only contains the Characters YMDhms
    unless ($self->{option_results}->{custom_date_map} =~ /Y/ && $self->{option_results}->{custom_date_map} =~ /D/ && $self->{option_results}->{custom_date_map} =~ /M/) {
        $self->{output}->add_option_msg(short_msg => "Error. custom-date-map must contaion Y, M and D characters.");
        $self->{output}->option_exit();
    }
    if (($self->{option_results}->{custom_date_map} =~ tr/YMDhms//) > $opening_groups) {
        $self->{output}->add_option_msg(short_msg => "custom-date-map expects more groups than the count defined in custom-date-regex");
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
    my $catch_error_message = '';
    # Extracts expiry date
    my ($lerror, $stdout, $exit_code) = centreon::plugins::misc::backtick(
                                                 command => $self->{option_results}->{command},
                                                 arguments => [$self->{option_results}->{domain}],
                                                 timeout => $self->{option_results}->{timeout},
                                                 wait_exit => 1,
                                                 redirect_stderr => 1
                                                 ); 
    my $long_error_message = $stdout; # $lerror . "\n" . $stdout;
    if ($stdout =~ /invalid_query_error/i ) {
        $catch_error_message = "Not supported by whois";
        $self->{output}->output_add(
                severity => 'Unknown',
                short_msg => 'Domain: ' . $self->{option_results}->{domain} . ': ' . $catch_error_message,
                long_msg => $long_error_message
                );
    } elsif ($stdout =~ /NOT FOUND/) {
        $catch_error_message = "Record not found";
        $self->{output}->output_add(
                severity => 'Unknown',
                short_msg => 'Domain: ' . $self->{option_results}->{domain} . ': ' . $catch_error_message,
                long_msg => $long_error_message
                );
    } elsif (int($exit_code) <= 1){  # Bug. whois might exit 1, and yet provide an answer. i.e. outdated info
        # Known Expiry date forms
        if ($stdout =~ /Registry Expiry Date:\s+(\d{4})\-(\d{2})\-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z/){
            my $expire_datetime = DateTime->new(
                year      => $1,
                month     => $2,
                day       => $3,
                hour      => $4,
                minute    => $5,
                second    => $6,
                time_zone => 'UTC',
            );  
            $self->get_expire_days($expire_datetime);
        # Custom Expiry Date regex. Test your whois response first.     
        } elsif ($stdout =~ /$self->{option_results}->{custom_date_regex}/) {
            $self->get_expire_days(
                $self->custom_expiry_date($stdout));
        # Exit error unable to get timestamp.  
        } else {
            $catch_error_message = 'Whois response did not match known Expire Regex'; 
            $self->{output}->output_add(
                severity => 'Unknown',
                short_msg => $catch_error_message,
                long_msg => $long_error_message
                );
        }
    }else{
        # Error calling binary 
        $catch_error_message = "Uncaught error calling binary";
        $self->{output}->output_add(
                severity => 'Unknown',
                short_msg => $catch_error_message,
                long_msg => $long_error_message
                );
    
    }
    
    $self->{output}->display();
    $self->{output}->exit();

}

sub get_expire_days {
    my ($self, $expire_datetime) = @_;
    my $SECONDS_PER_DAY = 86400;  # 24h * 60m * 60s
    # set current timestamp
    my $now_epoch_seconds = DateTime->now(time_zone => 'UTC')->epoch;  # Seconds
    # Calculate days to expire:
    my $seconds_to_expire = ($expire_datetime->epoch - $now_epoch_seconds);
    my $remaining_days = int($seconds_to_expire / $SECONDS_PER_DAY);
    # Compares against thresholds:
    my $exit = $self->{perfdata}->threshold_check(
        value => $remaining_days,
        threshold => [ 
            { label => 'critical', 'exit_litteral' => 'critical' },
            { label => 'warning', 'exit_litteral' => 'warning' }
            ]
        );
    $self->{output}->output_add(severity => $exit,
                        short_msg => sprintf("Expire date for %s is %s.", $self->{option_results}->{domain}, $expire_datetime->datetime)
                        ); 

    $self->{output}->perfdata_add(label => 'remaining_days', unit => undef,
                        value => $remaining_days,
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                        min => 0, max => undef);
}

sub custom_expiry_date {
    my ($self, $whois_outcome) = @_;
    # map_fields indicates which regex group contains
    # the required datetime object parameter.
    # Note that Year, Month and Date are required in
    # the custom regex.
    my %map_fields = (
        'Y' => 1,
        'M' => 2,
        'D' => 3,
        'h' => 99,
        'm' => 99,
        's' => 99,
    );
    my $hour=0;
    my $minute=0;
    my $second=0;
    my $time_zone='UTC';
    # custom_date_regex
    # custom_date_map
    # Update date fields maps
    for (keys %map_fields) {
        # set the index of the map group
        my $key = $_;
        if ($self->{option_results}->{custom_date_map} =~ /($key)/) {
            $map_fields{$key} = $-[0];
        }
        # 
    }
    # Create Variables for datetime object  
    # Main run phase, controls there is a match between the regex
    # and the outcome of the whoiscommand
    my @regex_groups = ($whois_outcome =~ /$self->{option_results}->{custom_date_regex}/);
    my $year = $regex_groups[$map_fields{'Y'}];
    my $month = $regex_groups[$map_fields{'M'}];
    my $day = $regex_groups[$map_fields{'D'}];
    if ($map_fields{'h'} <= scalar @regex_groups) {
        $hour = $regex_groups[$map_fields{'h'}];
    }
    if ($map_fields{'m'} <= scalar @regex_groups) {
        $minute = $regex_groups[$map_fields{'m'}];
    }
    if ($map_fields{'s'} <= scalar @regex_groups) {
        $second = $regex_groups[$map_fields{'s'}];
    }
    my $dateObject = DateTime->new(
        year      => $year,
        month     => $month,
        day       => $day,
        hour      => $hour,
        minute    => $minute,
        second    => $second,
        time_zone => 'UTC' # Forced. Can't create datetime::timezone object from string
        # Not tested with streams of the type: +0300, -0400. This induces inaccuracy in the check 
    );
    return $dateObject
}

1;

__END__

=head1 MODE

Check remaining expiration days for a domain using whois binary.
Please read WHOIS warnings/licenses.

Mode supports a custom regex to convert a expiry string into the
Expiredate Datetime object.

=over 8

=item B<--domain>

Domain to check. Ony two levels supported

=item B<--whois_binary>

Binary to check the domain (Default: '/usr/bin/whois')

=item B<--timeout>

Threshold whois timeout (Default: 3)

=item B<--warning-days>

days to expire threshold (Default: '30:')

=item B<--critical-days>

days to expire threshold (Default: '10:')

=item B<--custom-date-regex>

Expression to match the expire regex on your whois provider.
Example: 
whois mydomain.TLD
...
domain expires: 2022/07/31 2pm
...
Would use aparameter like: 
'expires: (\d{4})\/(\d{2})\/(\d{2})' (Default: 'Expiry Date:\s+(\d{2})-(\d{2})-(\d{4})')


=item B<--custom-date-map>

How each regex group found on the custom-date-regex maps to a
perl datetime object constructor (year, month, day, hour, minute, second).
On our example, the first group would represent the year (Y)
second group represents the Mondh (M)
third group represents the day (D),
so you must pass a map like
'YMD'

supported fields:
YMDhms

(Default: DMY )

=back

=cut
