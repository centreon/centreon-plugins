#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package hardware::devices::pexip::infinity::managementapi::mode::conferences;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::statefile;
use POSIX;
use Time::HiRes;
use Digest::MD5 qw(md5_hex);

sub prefix_quality_output {
    my ($self, %options) = @_;

    return 'Participants call quality ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'conferences', type => 0, skipped_code => { -10 => 1 } },
        { name => 'participants_quality', type => 0, cb_prefix_output => 'prefix_quality_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{conferences} = [
        { label => 'conferences-total', nlabel => 'conferences.total.count', set => {
                key_values => [ { name => 'total_conferences' } ],
                output_template => 'conferences total: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'participants-total', nlabel => 'participants.total.count', set => {
                key_values => [ { name => 'total_participants' } ],
                output_template => 'participants total: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
    ];

    $self->{maps_counters}->{participants_quality} = [];
    foreach (('good', 'ok', 'bad', 'terrible', 'unknown')) {
        push @{$self->{maps_counters}->{participants_quality}}, {
            label => 'participants-callquality-' . $_, nlabel => 'participants.callquality.' . $_ . '.count', set => {
                key_values => [ { name => $_ }, { name => 'total' } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        };
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
    });

    centreon::plugins::misc::mymodule_load(
        output => $self->{output},
        module => 'Date::Parse',
        error_msg => "Cannot load module 'Date::Parse'."
    );
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{statefile_cache}->check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{statefile_cache}->read(
        statefile => 'cache_pexip_'  . $options{custom}->{hostname}  . '_' . $self->{mode} . '_' .
            (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'))
    );
    my $last_conference_endtime = $self->{statefile_cache}->get(name => 'last_conference_endtime');
    if (!defined($last_conference_endtime)) {
        $last_conference_endtime = Time::HiRes::time();
    }

    my $date_end = POSIX::strftime('%Y-%m-%dT%H:%M:%S', gmtime($last_conference_endtime));
    $date_end .= sprintf('.%06d', ($last_conference_endtime - int($last_conference_endtime)) * 1000000);
    my $conferences = $options{custom}->request_api(
        endpoint => '/api/admin/history/v1/conference/',
        get_param => ['end_time__gt=' . $date_end]
    );

    $self->{conferences} = { total_participants => 0, total_conferences => 0 };
    $self->{participants_quality} = { total => 0, unknown => 0, ok => 0, good => 0, bad => 0, terrible => 0 };

    my $conference_ids = {};
    my ($conf_min_starttime, $conf_max_endtime) = (0, 0);
    foreach (@$conferences) {
        $self->{conferences}->{total_conferences}++;
        $conference_ids->{ $_->{id} } = 1;

        my $tmp_time = Date::Parse::str2time($_->{start_time});
        if (!defined($tmp_time)) {
            $self->{output}->output_add(
                severity => 'UNKNOWN',
                short_msg => "can't parse date '" . $_->{start_time} . "'"
            );
            next;
        }
        $conf_min_starttime = $tmp_time if ($conf_min_starttime == 0 || $conf_min_starttime > $tmp_time);

        $tmp_time = Date::Parse::str2time($_->{end_time});
        if (!defined($tmp_time)) {
            $self->{output}->output_add(
                severity => 'UNKNOWN',
                short_msg => "can't parse date '" . $_->{end_time} . "'"
            );
            next;
        }
        $conf_max_endtime = $tmp_time if ($conf_max_endtime < $tmp_time);
    }

    $self->{statefile_cache}->write(data => { last_conference_endtime => $last_conference_endtime });

    return if ($conf_min_starttime == 0);

    my $date_end2 = POSIX::strftime('%Y-%m-%dT%H:%M:%S', gmtime($conf_max_endtime + 1));
    $date_end2 .= sprintf('.%06d', ($conf_max_endtime - int($conf_max_endtime)) * 1000000);
    my $date_start2 = POSIX::strftime('%Y-%m-%dT%H:%M:%S', gmtime($conf_min_starttime - 1));
    $date_start2 .= sprintf('.%06d', ($conf_min_starttime - int($conf_min_starttime)) * 1000000);
    my $participants = $options{custom}->request_api(
        endpoint => '/api/admin/history/v1/participant/',
        get_param => ['start_time__gte=' . $date_start2, 'end_time__lte=' . $date_end2]
    );

    foreach (@$participants) {
        next if ($_->{conference} !~ /conference\/(.*?)\/$/ && !defined($conference_ids->{ $1 }));
        $self->{conferences}->{total_participants}++;
        $self->{participants_quality}->{total}++;
        my ($num, $label) = split(/_/, $_->{call_quality});
        if (defined($self->{participants_quality}->{ lc($label) })) {
            $self->{participants_quality}->{ lc($label) }++;
        }
    }
}

1;

__END__

=head1 MODE

Check conferences and participants.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'conferences-total', 'participants-total', 'participants-callquality-good',
'participants-callquality-ok', 'participants-callquality-bad', 'participants-callquality-terrible', 
'participants-callquality-unknown'.

=back

=cut
