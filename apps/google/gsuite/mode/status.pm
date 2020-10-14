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
#

package apps::google::gsuite::mode::status;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use JSON::XS;
use POSIX qw(strftime);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        " (%s): '%s' (since '%s')",
        $self->{result_values}->{status},
        $self->{result_values}->{message},
        $self->{result_values}->{time}
    );
}

sub prefix_gapps_output {
    my ($self, %options) = @_;

    return $options{instance_value}->{name} . " ";
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'gapps', type => 1, cb_prefix_output => 'prefix_gapps_output', display_long => 1, cb_long_output => 'long_output', message_multiple => 'All Google Apps are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'apps', nlabel => 'google.apps.current.count', set => {
                key_values => [ { name => 'apps' } ],
                output_template => '%s GApps',
                perfdatas => [
                    { template => '%s',
                      min => 0 },
                ],
            }
        }
    ];
    $self->{maps_counters}->{gapps} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'name' }, { name => 'message' }, { name => 'time' },],
                #closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s'        => { name => 'hostname', default => 'www.google.com' },
        'port:s'            => { name => 'port', default => '443'},
        'proto:s'           => { name => 'proto', default => 'https' },
        'urlpath:s'         => { name => 'url_path', default => '/appsstatus/json' },
        'language:s'        => { name => 'language', default => 'en' },
        'timeout:s'         => { name => 'timeout', default => '30' },
        'filter-app:s'      => { name => 'filter_app' },
        'display-extra'     => { name => 'display_extra'},
        'warning-status:s'  => { name => 'warning_status', default => '%{status} eq "DEGRADED"' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} eq "UNAVAILABLE"' },
    });

    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    $self->{option_results}->{url_path} .= "/" . $self->{option_results}->{language};
    $self->{http}->set_options(%{$self->{option_results}});

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

     my $content = $self->{http}->request(%options);
     $content =~ s/dashboard.jsonp\((.+)\)\;$/$1/g;

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }
    if (defined($decoded->{error_code})) {
        $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error}, debug => 1);
        $self->{output}->option_exit();
    }

    my %status_mapping = (
        1 => 'DEGRADED',
        2 => 'UNAVAILABLE',
        3 => 'RESOLVED',
        4 => 'CLOSED'
    );

    my $time_now = strftime('%Y-%m-%dT%H:%M:%S', gmtime());
    foreach my $mapping (@{$decoded->{services}}) {
        next if (
            defined($self->{option_results}->{filter_app})
            && $self->{option_results}->{filter_app} ne ''
            && $mapping->{name} !~ /(?i)$self->{option_results}->{filter_app}/
        );
        next if (
            (!defined($self->{option_results}->{display_extra}))
            && $mapping->{type} != '0'
        );
        $self->{gapps}->{$mapping->{id}} = {
            name    => $mapping->{name},
            type    => $mapping->{type},
            status  => 'OK',
            time    => $time_now,
            message => ''
        };
    };

    $self->{global}->{issues} = 0;
    foreach my $issue (@{$decoded->{messages}}) {
        next if (!defined($self->{gapps}->{$issue->{service}}));

        next if (
            (!defined($self->{option_results}->{display_extra}))
            && $self->{gapps}->{$issue->{service}} != '0'
        );

        next if $issue->{resolved};

        $self->{gapps}->{$issue->{service}} = {
            name => $self->{gapps}->{$issue->{service}}->{name},
            status => $status_mapping{$issue->{type}},
            time => strftime('%Y-%m-%dT%H:%M:%S', gmtime($issue->{time} / 1000)),
            message => $issue->{message},
            resolved => $issue->{resolved},
            type => $self->{gapps}->{$issue->{service}}->{type}
        };
    }
    $self->{global}->{apps} = scalar (keys %{$self->{gapps}});
}

1;

__END__

=head1 MODE

Check Google Gsuite Applications status

=over 8

=item B<--hostname>

IP Addr/FQDN of the Google Appstatus site (Default:'www.google.com')

=item B<--port>

Port used by Google's status website (Default: '443')

=item B<--proto>

Specify the HTTP protocol if needed (Default: 'https')

=item B<--urlpath>

URL path to get Google's status information (Default: '/appsstatus/json')

=item B<--language>

Set the language to be used in the response (Two letters, Default: 'en')

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=item B<--filter-app>

Only display the status for a specific app
(Example: --filter-app='gmail')

=item B<--display-extra>

Also display the status of the Google Apps not covered by G Suite Service Level Agreement

=item B<--warning-status>

Set warning threshold for the application status
(Default: '%{status} eq "DEGRADED"').

=item B<--critical-status>

Set warning threshold for the application status
(Default: '%{status} eq "UNAVALAIBLE"').

=back

=cut
