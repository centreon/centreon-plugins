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

package apps::proxmox::mg::restapi::mode::mail;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub mails_long_output {
    my ($self, %options) = @_;

    return 'checking mail statistics';
}

sub prefix_mail_output {
    my ($self, %options) = @_;

    return 'number of mails ';
}

sub prefix_virus_output {
    my ($self, %options) = @_;

    return 'number of virus mails ';
}

sub prefix_spam_output {
    my ($self, %options) = @_;

    return 'number of spam mails ';
}

sub prefix_traffic_output {
    my ($self, %options) = @_;

    return 'traffic ';
}

sub set_counters {
    my ($self, %options) = @_;

     $self->{maps_counters_type} = [
        { name => 'mails', type => 3, cb_long_output => 'mails_long_output', indent_long_output => '    ',
            group => [
                { name => 'mail', type => 0, display_short => 0, cb_prefix_output => 'prefix_mail_output', skipped_code => { -10 => 1 } },
                { name => 'traffic', type => 0, display_short => 0, cb_prefix_output => 'prefix_traffic_output', skipped_code => { -10 => 1 } },
                { name => 'spam', type => 0, display_short => 0, cb_prefix_output => 'prefix_spam_output', skipped_code => { -10 => 1 } },
                { name => 'virus', type => 0, display_short => 0, cb_prefix_output => 'prefix_virus_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{mail} = [
        { label => 'mails-incoming', nlabel => 'mails.incoming.count', set => {
                key_values => [ { name => 'mail_in' } ],
                output_template => 'incoming: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'mails-outgoing', nlabel => 'mails.outgoing.count', set => {
                key_values => [ { name => 'mail_out' } ],
                output_template => 'outgoing: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{traffic} = [
        { label => 'traffic-in', nlabel => 'mails.traffic.in.bytespersecond', set => {
                key_values => [ { name => 'bytes_in_psec' } ],
                output_template => 'in: %.2f %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%.2f', unit => 'B/s', min => 0 }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'mails.traffic.out.bytespersecond', set => {
                key_values => [ { name => 'bytes_out_psec' } ],
                output_template => 'out: %.2f %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%.2f', unit => 'B/s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{spam} = [
        { label => 'spam-incoming', nlabel => 'mails.spam.incoming.count', set => {
                key_values => [ { name => 'spam_in' } ],
                output_template => 'incoming: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'spam-outgoing', nlabel => 'mails.spam.outgoing.count', set => {
                key_values => [ { name => 'spam_out' } ],
                output_template => 'outgoing: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{virus} = [
        { label => 'virus-incoming', nlabel => 'mails.virus.incoming.count', set => {
                key_values => [ { name => 'virus_in' } ],
                output_template => 'incoming: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'virus-outgoing', nlabel => 'mails.virus.outgoing.count', set => {
                key_values => [ { name => 'virus_out' } ],
                output_template => 'outgoing: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hours:s'    => { name => 'hours', default => 12 },
        'timespan:s' => { name => 'timespan', default => 1800 }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $datas = $options{custom}->request(
        endpoint => '/statistics/recent',
        get_param => [
            'hours=' . $self->{option_results}->{hours},
            'timespan=' . $self->{option_results}->{timespan}
        ]
    );

    my $result = { mail_in => 0, mail_out => 0, virus_in => 0, virus_out => 0, spam_in => 0, spam_out => 0, bytes_in => 0, bytes_out => 0 };
    foreach (@{$datas->{data}}) {
        $result->{mail_in} += $_->{count_in};
        $result->{mail_out} += $_->{count_out};
        $result->{spam_in} += $_->{spam_in};
        $result->{spam_out} += $_->{spam_out};
        $result->{virus_in} += $_->{virus_in};
        $result->{virus_out} += $_->{virus_out};
        $result->{bytes_in} += $_->{bytes_in};
        $result->{bytes_out} += $_->{bytes_out};
    }

    $self->{output}->output_add(short_msg => 'Mail statistics are ok');

    $self->{mails} = {
        global => {
            mail => {
                mail_in => $result->{mail_in},
                mail_out => $result->{mail_out}
            },
            spam => {
                spam_in => $result->{spam_in},
                spam_out => $result->{spam_out}
            },
            traffic => {
                bytes_in_psec => $result->{bytes_in} / ($self->{option_results}->{hours} * 3600),
                bytes_out_psec => $result->{bytes_out} / ($self->{option_results}->{hours} * 3600)
            },
            virus => {
                virus_in => $result->{virus_in},
                virus_out => $result->{virus_out}
            }
        }
    };
}

1;

__END__

=head1 MODE

Check mail statistics.

=over 8

=item B<--hours>

How many hours of statistics you want (Default: 12)

=item B<--timespan>

Timespan for datapoints in hours timeframe (Default: 1800)

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'virus-incoming', 'virus-outgoing', 'traffic-in', 'traffic-out',
'mails-incoming', 'mails-outgoing', 'spam-incoming', 'spam-outgoing'.

=back

=cut
