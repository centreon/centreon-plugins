#
# Copyright 2020 Centreon (http://www.centreon.com/)
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
# Authors : Roman Morandell - ivertix
#

package apps::smartermail::restapi::mode::spoolmessagecount;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use JSON::XS;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'default', set => {
            key_values      => [ { name => 'default' } ],
            output_template => 'Default count: %d',
            perfdatas       => [
                { label => 'default', value => 'default_absolute', template => '%d', min => 0 },
            ],
        }
        },
        { label => 'waiting', set => {
            key_values      => [ { name => 'waiting' } ],
            output_template => 'Waiting : %d',
            perfdatas       => [
                { label => 'waiting', value => 'waiting_absolute', template => '%d', min => 0 },
            ],
            }
        },
        { label => 'spam', set => {
            key_values      => [ { name => 'spam' } ],
            output_template => 'Spam : %d',
            perfdatas       => [
                { label => 'spam', value => 'spam_absolute', template => '%d', min => 0 },
            ],
        }
        },
        { label => 'virus', set => {
            key_values      => [ { name => 'virus' } ],
            output_template => 'Virus : %d',
            perfdatas       => [
                { label => 'virus', value => 'virus_absolute', template => '%d', min => 0 },
            ],
        }
        },
        { label => 'throttledUsers', set => {
            key_values      => [ { name => 'throttledUsers' } ],
            output_template => 'ThrottledUsers : %d',
            perfdatas       => [
                { label => 'throttledUsers', value => 'throttledUsers_absolute', template => '%d', min => 0 },
            ],
        }
        },
        { label => 'throttledMailingLists', set => {
            key_values      => [ { name => 'throttledMailingLists' } ],
            output_template => 'ThrottledMailingLists : %d',
            perfdatas       => [
                { label => 'throttledMailingLists', value => 'throttledMailingLists_absolute', template => '%d', min => 0 },
            ],
        }
        },
        { label => 'throttledDomains', set => {
            key_values      => [ { name => 'throttledDomains' } ],
            output_template => 'ThrottledDomains : %d',
            perfdatas       => [
                { label => 'throttledDomains', value => 'throttledDomains_absolute', template => '%d', min => 0 },
            ],
        }
        },
        { label => 'spool_limit', set => {
            key_values      => [ { name => 'spool_limit' } ],
            output_template => 'Spool_limit : %d',
            perfdatas       => [
                { label => 'spool_limit', value => 'spool_limit_absolute', template => '%d', min => 0 },
            ],
        }
        },
        { label => 'quarantine_limit', set => {
            key_values      => [ { name => 'quarantine_limit' } ],
            output_template => 'Quarantine_limit : %d',
            perfdatas       => [
                { label => 'quarantine_limit', value => 'quarantine_limit_absolute', template => '%d', min => 0 },
            ],
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
        {
            "filter-counter:s" => { name => 'filter_counters' },
        });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $jsonResponse = $options{custom}->get_endpoint(api_path => '/settings/sysadmin/spool-message-counts');
    # my $jsonResponse = '{"counts":{"default":6,"waiting":31,"virus":0,"spam":0,"throttledUsers":1,"throttledMailingLists":0,"throttledDomains":0,"spool_limit":50000,"quarantine_limit":5000},"success":true,"message":""}';

    my $response;
    eval {
        $response = decode_json($jsonResponse);
    };
    # the response was checked on "get_endpoint" if contains 'success=true'
    if ($@) {
        $self->{output}->output_add(long_msg => $jsonResponse, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    my $counts = $response->{counts};

    $self->{global} = '';
    $self->{global} = {
        default => $counts->{default},
        waiting               => $counts->{waiting},
        spam                  => $counts->{spam},
        virus                 => $counts->{virus},
        throttledUsers        => $counts->{throttledUsers},
        throttledMailingLists => $counts->{throttledMailingLists},
        throttledDomains      => $counts->{throttledDomains},
        spool_limit           => $counts->{spool_limit},
        quarantine_limit      => $counts->{quarantine_limit},
    };
}


1;

__END__

=head1 MODE

Check spool message counters.

=over 8

=item B<--filter>

Only display some counters (regexp can be used).
(Example: --filter-counter='active')

=item B<--warning-*>

Threshold warning.
Can be: 'default', 'waiting', 'spam', 'virus', 'throttledUsers', 'throttledMailingLists', 'throttledDomains'.

=item B<--critical-*>

Threshold critical.
Can be: 'default', 'waiting', 'spam', 'virus', 'throttledUsers', 'throttledMailingLists', 'throttledDomains'.

=back

=cut
