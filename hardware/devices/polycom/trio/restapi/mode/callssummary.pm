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

package hardware::devices::polycom::trio::restapi::mode::callssummary;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'total calls ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'calls.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: d',
                perfdatas => [
                    { value => 'total', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'placed', nlabel => 'calls.placed.count', set => {
                key_values => [ { name => 'placed' } ],
                output_template => 'placed: %d',
                perfdatas => [
                    { value => 'placed', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'missed', nlabel => 'calls.missed.count', set => {
                key_values => [ { name => 'missed' } ],
                output_template => 'missed: %d',
                perfdatas => [
                    { value => 'missed', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'received', nlabel => 'calls.received.count', set => {
                key_values => [ { name => 'received' } ],
                output_template => 'received: %d',
                perfdatas => [
                    { value => 'received', template => '%d', min => 0 },
                ],
            }
        },
    ];
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
        statefile => 'polycom_trio_' . $options{custom}->{hostname}  . '_' . $self->{mode} . '_' .
            (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'))
    );
    my $last_times = $self->{statefile_cache}->get(name => 'last_times');
    $last_times = { placed => 0, missed => 0, received => 0 }  if (!defined($last_times));

    my $result = $options{custom}->request_api(url_path => '/api/v1/mgmt/callLogs');
    if (!defined($result->{data}->{Placed})) {
        $self->{output}->add_option_msg(short_msg => "cannot find callLogs information.");
        $self->{output}->option_exit();
    }

    $self->{global} = { total => 0, placed => 0, missed => 0, received => 0 };

    my $new_last_times = { placed => 0, missed => 0, received => 0 };
    foreach (('placed', 'missed', 'received')) {
        foreach my $entry (@{$result->{data}->{ucfirst($_)}}) {
            my $start_time = Date::Parse::str2time($entry->{StartTime});
            if (!defined($start_time)) {
                $self->{output}->output_add(
                    severity => 'UNKNOWN',
                    short_msg => "can't parse date '" . $entry->{StartTime} . "'"
                );
                next;
            }
            $new_last_times->{$_} = $start_time if ($new_last_times->{$_} < $start_time);
            next if ($start_time <= $last_times->{$_});

            $self->{global}->{total}++;
            $self->{global}->{$_}++;
        }
    }

    $self->{statefile_cache}->write(data => { last_times => $new_last_times });
}

1;

__END__

=head1 MODE

Check call history.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total', 'placed', 'missed', 'received'.

=back

=cut
