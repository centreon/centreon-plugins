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

package centreon::common::microsoft::skype::mssql::mode::sessionstypes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'instant-messaging', set => {
                key_values => [ { name => 'instant_messaging' } ],
                output_template => 'Instant Messaging: %d',
                perfdatas => [
                    { label => 'instant_messaging', value => 'instant_messaging', template => '%d',
		              unit => 'sessions', min => 0 },
                ],
            }
        },
        { label => 'audio', set => {
                key_values => [ { name => 'audio' } ],
                output_template => 'Audio: %d',
                perfdatas => [
                    { label => 'audio', value => 'audio', template => '%d',
                      unit => 'sessions', min => 0 },
                ],
            }
        },
        { label => 'video', set => {
                key_values => [ { name => 'video' } ],
                output_template => 'Video: %d',
                perfdatas => [
                    { label => 'video', value => 'video', template => '%d', 
                     unit => 'sessions', min => 0 },
                ],
            }
        },
        { label => 'file-transfer', set => {
                key_values => [ { name => 'file_transfer' } ],
                output_template => 'File Transfer: %d',
                perfdatas => [
                    { label => 'file_transfer', value => 'file_transfer', template => '%d',
                      unit => 'sessions', min => 0 },
                ],
            }
        },
        { label => 'remote-assistance', set => {
                key_values => [ { name => 'remote_assistance' } ],
                output_template => 'Remote Assistance: %d',
                perfdatas => [
                    { label => 'remote_assistance', value => 'remote_assistance', template => '%d',
                      unit => 'sessions', min => 0 },
                ],
            }
        },
        { label => 'app-sharing', set => {
                key_values => [ { name => 'app_sharing' } ],
                output_template => 'App Sharing: %d',
                perfdatas => [
                    { label => 'app_sharing', value => 'app_sharing', template => '%d',
                      unit => 'sessions', min => 0 },
                ],
            }
        },
        { label => 'app-invite', set => {
                key_values => [ { name => 'app_invite' } ],
                output_template => 'App Invite: %d',
                perfdatas => [
                    { label => 'app_invite', value => 'app_invite', template => '%d', 
                     unit => 'sessions', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
				                    "lookback:s"            => { name => 'lookback', default => '5' }, # not used
                                    "timeframe:s"           => { name => 'timeframe', default => '900' },
                                    "filter-counters:s"     => { name => 'filter_counters', default => '' },
                                });
    return $self;
}

my %mapping_types = (
    1 => 'instant_messaging',
    2 => 'file_transfer',
    4 => 'remote_assistance',
    8 => 'app_sharing',
    16 => 'audio',
    32 => 'video',
    64 => 'app_invite',
);

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{sql} = $options{sql};
    $self->{sql}->connect();
    
    $self->{global} = { instant_messaging => 0, file_transfer => 0, remote_assistance => 0,
                        app_sharing => 0, app_sharing => 0, video => 0, app_invite => 0 };

    my $query = "SELECT *
                FROM [LcsCDR].[dbo].[SessionDetails] s
                    LEFT OUTER JOIN [LcsCDR].[dbo].[Users] u1 ON s.User1Id = u1.UserId
                    LEFT OUTER JOIN [LcsCDR].[dbo].[Users] u2 ON s.User2Id = u2.UserId
                WHERE s.SessionIdTime > (DATEADD(SECOND,-" . $self->{option_results}->{timeframe} . ",SYSUTCDATETIME()))
                AND s.SessionIdTime < SYSUTCDATETIME()";
                     
    $self->{sql}->query(query => $query);

    while (my $row = $self->{sql}->fetchrow_hashref()) {
        next if (!defined($mapping_types{$row->{MediaTypes}}));
        $self->{global}->{$mapping_types{$row->{MediaTypes}}}++;
    }
}

1;

__END__

=head1 MODE

Check number of sessions ordered by type.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).

=item B<--timeframe>

Set the timeframe to query in seconds (Default: 900)

=item B<--warning-*>

Set warning threshold.
Can be : 'instant-messaging', 'app-sharing', 'audio',
'video', 'app-invite', 'remote-assistance'

=item B<--critical-*>

Set critical threshold.
Can be : 'instant-messaging', 'app-sharing', 'audio',
'video', 'app-invite', 'remote-assistance'

=back

=cut
