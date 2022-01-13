#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package os::windows::wmi::mode::folderdate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use DateTime;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'warning:s'       => { name => 'warning' },
        'critical:s'      => { name => 'critical' },
        'filter-plugin:s' => { name => 'filter_plugin' },
        'folder:s'        => { name => 'folder' },
        'drive:s'        => { name => 'drive' }
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
    if (!defined($self->{option_results}->{folder}) || $self->{option_results}->{folder} eq '') {
       $self->{output}->add_option_msg(short_msg => "Need to specify file option.");
       $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{drive}) || $self->{option_results}->{drive} eq '') {
       $self->{output}->add_option_msg(short_msg => "Need to specify file option.");
       $self->{output}->option_exit();
    }

    #### Create file path
    $self->{option_results}->{folder} =~ s/\//\\\\/g;
}

sub wmi_to_seconds {
    # pass in a WMI Timestamp like 20100528105127.000000+600
    my ($wmi_timestamp)=@_;
    my $sec='';
    my $age_sec=''; 
    my $current_dt='';
    my $current_sec='';
    my $tz='';
    my $timezone_direction='+';
    my $timezone_offset=0;
    #                        1      2      3      4      5      6      7     8        9
    if ($wmi_timestamp=~/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2}).(\d*)([+\-])+(.{3,3})$/) {
        # now convert that fileage to seconds
        # firstly look at the time zone offset value
        # as per https://docs.microsoft.com/en-us/windows/win32/wmisdk/cim-datetime
        # it would normally be a 3 digit number which is a number of minutes
        # however it can also be *** which means that there is no time zone and the local time zone (of the windows box) should be used
        # best we can do at this point is use the time zone of the system that this script is running on instead until we find something better
        $tz=$8 . sprintf("%02d%02d",$9/60,$9%60);
        my %ts_info=(
            year       => $1,
            month      => $2,
            day        => $3,
            hour       => $4,
            minute     => $5,
            second     => $6,
            nanosecond => $7,
            time_zone  => '', # set later
        );
        $timezone_direction=$8;
        $timezone_offset=$9;
        
        # now check the timezone offset
        if ($timezone_offset=~/\d{3,3}/) {
           # all good with a 3 digit offset
           # use the timezone of the queried system - convert the WMI timezone (number of minutes) to HHMM for use with DateTime
           $ts_info{'time_zone'}=$timezone_direction . sprintf("%02d%02d",$timezone_offset/60,$timezone_offset%60);
        } else {
           # offset could be '***' or something else, in either case use this system local timezone as a best guess
           $ts_info{'time_zone'}='local';
        }
        
        my $dt = DateTime->new(%ts_info);
        
        $sec=$dt->epoch();
        # force the current time into the same timezone as the queried system
        $current_dt=DateTime->now( time_zone => $dt->time_zone() );
        $current_sec=$current_dt->epoch();
        $age_sec=$current_sec-$sec;
    }
    return $sec,$age_sec;
}

sub run {
    my ($self, %options) = @_;
    my $total_size = 0;
    my $current_time = time();

    my $WQL = 'Select name,lastmodified from CIM_DataFile where drive = "' . $self->{option_results}->{drive} . '" AND path = "' . $self->{option_results}->{folder} . '"';

    my ($result, $exit_code) = $options{custom}->execute_command(
        query => $WQL,
        no_quit => 1
    );
    $result =~ s/\|/;/g;

    #
    #$VAR1 = 'CLASS: CIM_DataFile
    #LastModified;Name
    #20211224000036.262291+000;C:\\Users\\Administrator\\NTUSER.DAT';
    #
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'All file/directory times are ok.'
    );

    if(!defined($result) || $result eq '') {
        $self->{output}->output_add(
        severity => 'UNKNOWN',
        short_msg => 'No file found.'
        );
    }

    while ($result =~ /^(\d+.*?);(.*?)$/msg) {
        my ($last_modified, $name) = ($1, centreon::plugins::misc::trim($2));
        my ($time,$diff_time)= wmi_to_seconds($last_modified);
        
        next if (defined($self->{option_results}->{filter_plugin}) && $self->{option_results}->{filter_plugin} ne '' &&
                 $name !~ /$self->{option_results}->{filter_plugin}/);
        
        my $exit_code = $self->{perfdata}->threshold_check(
            value => $diff_time, 
            threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]
        );
        $self->{output}->output_add(long_msg => sprintf("%s: %s seconds (time: %s)", $name, $diff_time, scalar(localtime($time))));
        if (!$self->{output}->is_status(litteral => 1, value => $exit_code, compare => 'ok')) {
            $self->{output}->output_add(
                severity => $exit_code,
                short_msg => sprintf('%s: %s seconds (time: %s)', $name, $diff_time, scalar(localtime($time)))
            );
        }
        $self->{output}->perfdata_add(
            label => $name, unit => 's',
            value => $diff_time,
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical')
        );
    }
      
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check file age.

=over 8

=item B<--folder>

Folder to check. (No WQL wildcard allowed)
Ex: '/Users/Administrator/'.

=item B<--drive>

Location of the folder.
ex: 'C:'.

=item B<--warning>

Threshold warning in seconds for each files/directories (diff time).

=item B<--critical>

Threshold critical in seconds for each files/directories (diff time).

=item B<--filter-plugin>

Filter file in the plugin. Values from exclude file are counted in parent directories!!!
Perl Regexp can be used.

=back

=cut
