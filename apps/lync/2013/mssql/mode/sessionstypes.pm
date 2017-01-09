#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package apps::lync::2013::mssql::mode::sessionstypes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'instant_messaging', type => 0 },
        { name => 'file_transfer', type => 0 },
        { name => 'remote_assistance', type => 0 },
        { name => 'app_sharing', type => 0 },
        { name => 'audio', type => 0 },
        { name => 'video', type => 0 },
        { name => 'app_invite', type => 0 },
    ];

    $self->{maps_counters}->{instant_messaging} = [
        { label => 'instant-messaging', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'Instant Messaging : %d',
                perfdatas => [
                    { label => 'instant_messaging', value => 'value_absolute', template => '%d',
		       unit => 'sessions', min => 0, label_extra_instance => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{file_transfer} = [
        { label => 'file-transfer', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'File transfer : %d',
                perfdatas => [
                    { label => 'file_transfer', value => 'value_absolute', template => '%d',
                       unit => 'sessions', min => 0, label_extra_instance => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{remote_assistance} = [
        { label => 'remote-assistance', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'Remote assistance : %d',
                perfdatas => [
                    { label => 'remote_assistance', value => 'value_absolute', template => '%d',
                       unit => 'sessions', min => 0, label_extra_instance => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{app_sharing} = [
        { label => 'app-sharing', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'App Sharing : %d',
                perfdatas => [
                    { label => 'app_sharing', value => 'value_absolute', template => '%d',
                       unit => 'sessions', min => 0, label_extra_instance => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{audio} = [
        { label => 'audio', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'Audio : %d',
                perfdatas => [
                    { label => 'audio', value => 'value_absolute', template => '%d',
                       unit => 'sessions', min => 0, label_extra_instance => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{video} = [
        { label => 'video', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'Video : %d',
                perfdatas => [
                    { label => 'video', value => 'value_absolute', template => '%d', 
                      unit => 'sessions', min => 0, label_extra_instance => 0 },
                ],
            }
        },
    ];

}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
				'lookback:s' => { name => 'lookback', default => '5' }, 
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
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};
    $self->{sql}->connect();

    foreach my $bit (keys %mapping_types) {
        my $query = "SELECT count(*)
                     FROM [LcsCDR].[dbo].[SessionDetails] s
                     left outer join [LcsCDR].[dbo].[Users] u1 on s.User1Id = u1.UserId  left outer join [LcsCDR].[dbo].[Users] u2 on s.User2Id = u2.UserId
                     WHERE MediaTypes=".$bit."
                     AND s.SessionIdTime>=dateadd(minute,-".$self->{option_results}->{lookback}.",getdate())";
                     
        $self->{sql}->query(query => $query);
        my $value = $self->{sql}->fetchrow_array();
        $self->{$mapping_types{$bit}} = { value => $value };
    }

}

1;

__END__

=head1 MODE

Check number of sessions ordered by type during last X minutes

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).

=item B<--lookback>

Minutes to lookback (From you to UTC)

=item B<--warning-*>

Set warning threshold Can be : 'instant-messaging', 'app-sharing', 'audio', 'video', 'app-invite', 'remote-assistance'

=item B<--critical-*>

Set critical threshold for number of user. Can be : 'instant-messaging', 'app-sharing', 'audio', 'video', 'app-invite', 'remote-assistance'

=back

=cut
