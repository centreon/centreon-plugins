#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package apps::lync::mode::sessionstype;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning-audio:s"               => { name => 'warning-audio', },
                                  "critical-audio:s"              => { name => 'critical-audio', },
                                  "warning-video:s"        => { name => 'warning_video', },
                                  "critical-video:s"       => { name => 'critical_video', },                                                                                                      
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning-audio', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-audio threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-audio', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-audio threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-video', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-video threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-video', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-video threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    
    $self->{sql}->query(query => q{SELECT count(*)
                                   FROM [LcsCDR].[dbo].[SessionDetails] s
                                    left outer join [LcsCDR].[dbo].[Users] u1 on s.User1Id = u1.UserId  left outer join [LcsCDR].[dbo].[Users] u2 on s.User2Id = u2.UserId
                                   WHERE (MediaTypes & 1)=16
                                   AND s.SessionIdTime>=dateadd(minute,-5,getdate())}
                        );
    
    
    my $audio = $self->{sql}->fetchrow_array();

    $self->{sql}->query(query => q{SELECT count(*)
                                   FROM [LcsCDR].[dbo].[SessionDetails] s
                                    left outer join [LcsCDR].[dbo].[Users] u1 on s.User1Id = u1.UserId  left outer join [LcsCDR].[dbo].[Users] u2 on s.User2Id = u2.UserId
                                   WHERE (MediaTypes & 1)=32
                                   AND s.SessionIdTime>=dateadd(minute,-5,getdate())}
                        );

    my $video = $self->{sql}->fetchrow_array();

    my $exit1 = $self->{perfdata}->threshold_check(value => $audio, threshold => [ { label => 'critical-audio', 'exit_litteral' => 'critical' }, { label => 'warning-audio', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $video, threshold => [ { label => 'critical-video', 'exit_litteral' => 'critical' }, { label => 'warning-video', exit_litteral => 'warning' } ]);
    my $exit_code = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]); 

    $self->{output}->output_add(severity => $exit_code,
                                  short_msg => sprintf("Lync sessions type : %i audio sessions and %i video sessions", $audio, $video));
    $self->{output}->perfdata_add(label => 'video_sessions',
                                  value => $video,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-video'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-video'),
                                  min => 0);
    $self->{output}->perfdata_add(label => 'audio_sessions',
                                  value => $audio,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-audio'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-audio'),
                                  min => 0);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Lync type of sessions (audio or video) during the last five minutes -- use with dyn-mode and mssql plugin

=over 8

=item B<--warning-audio>

Threshold warning on number of audio sessions during last five minutes

=item B<--critical-audio>

Threshold critical on number of audio sessions during last five minutes

=item B<--warning-video>

Threshold critical on number of video sessions during last five minutes

=item B<--critical-video>

Threshold critical on number of video sessions during last five minutes

=back

=cut
