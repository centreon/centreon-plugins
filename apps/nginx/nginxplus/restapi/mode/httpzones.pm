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

package apps::nginx::nginxplus::restapi::mode::httpzones;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub prefix_server_zone_output {
    my ($self, %options) = @_;

    return "Server zone '" . $options{instance_value}->{display} . "' ";
}

sub prefix_location_zone_output {
    my ($self, %options) = @_;

    return "Location zone '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'server_zones', type => 1, cb_prefix_output => 'prefix_server_zone_output', message_multiple => 'All server zones are ok', skipped_code => { -10 => 1 } },
        { name => 'location_zones', type => 1, cb_prefix_output => 'prefix_location_zone_output', message_multiple => 'All location zones are ok', skipped_code => { -10 => 1 } }
    ];

    foreach my $name (('server', 'location')) {
        $self->{maps_counters}->{$name . '_zones'} = [
            { label => $name . 'zone-requests', nlabel => 'http.' . $name . 'zone.requests.persecond', set => {
                    key_values => [ { name => 'requests', per_second => 1 } ],
                    output_template => 'requests: %.2f/s',
                    perfdatas => [
                        { template => '%.2f', min => 0, unit => '/s', label_extra_instance => 1 }
                    ]
                }
            },
            { label => $name . 'zone-requests-discarded', nlabel => 'http.' . $name . 'zone.requests.discarded.count', set => {
                    key_values => [ { name => 'discarded' } ],
                    output_template => 'discarded: %s',
                    perfdatas => [
                        { template => '%s', min => 0, label_extra_instance => 1 }
                    ]
                }
            },
            { label => $name . 'zone-traffic-in', nlabel => 'http.' . $name . 'zone.traffic.in.bitspersecond', set => {
                    key_values => [ { name => 'received', per_second => 1 } ],
                    output_template => 'traffic in: %s %s/s',
                    output_change_bytes => 2,
                    perfdatas => [
                        { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1 }
                    ]
                }
            },
            { label => $name . 'zone-traffic-out', nlabel => 'http.' . $name . 'zone.traffic.out.bitspersecond', set => {
                    key_values => [ { name => 'sent', per_second => 1 } ],
                    output_template => 'traffic out: %s %s/s',
                    output_change_bytes => 2,
                    perfdatas => [
                        { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1 }
                    ]
                }
            },
            { label => $name . 'zone-responses-total', nlabel => 'http.' . $name . 'zone.responses.total.count', set => {
                    key_values => [ { name => 'responses_total', diff => 1 } ],
                    output_template => 'responses total: %s',
                    perfdatas => [
                        { template => '%s', min => 0, label_extra_instance => 1 }
                    ]
                }
            }
        ];

        foreach (('1xx', '2xx', '3xx', '4xx', '5xx')) {
            push @{$self->{maps_counters}->{$name . '_zones'}}, {
                    label => $name . 'zone-responses-' . $_, nlabel => 'http.' . $name . 'zone.responses.' . $_ . '.count', display_ok => 0, set => {
                    key_values => [ { name => 'responses_' . $_, diff => 1 } ],
                    output_template => 'responses ' . $_ . ': %s',
                    perfdatas => [
                        { template => '%s', min => 0, label_extra_instance => 1 }
                    ]
                }
            };
        }
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-server-name:s'   => { name => 'filter_server_name' },
        'filter-location-name:s' => { name => 'filter_location_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    foreach my $name (('server', 'location')) {
        my $results = $options{custom}->request_api(
            endpoint => '/http/' . $name . '_zones/'
        );

        $self->{$name . '_zones'} = {};
        foreach (keys %$results) {
            if (defined($self->{option_results}->{'filter_' . $name . '_name'}) && $self->{option_results}->{'filter_' . $name . '_name'} ne '' &&
                $_ !~ /$self->{option_results}->{'filter_' . $name . '_name'}/) {
                $self->{output}->output_add(long_msg => "skipping $name zone '" . $_ . "': no matching filter.", debug => 1);
                next;
            }

            $self->{$name . '_zones'}->{$_} = {
                display => $_,
                discarded => $results->{ $_ }->{discarded},
                requests => $results->{ $_ }->{requests},
                received => $results->{ $_ }->{received} * 8,
                sent => $results->{ $_ }->{sent} * 8,
                responses_total => $results->{ $_ }->{responses}->{total},
                responses_1xx => $results->{ $_ }->{responses}->{'1xx'},
                responses_2xx => $results->{ $_ }->{responses}->{'2xx'},
                responses_3xx => $results->{ $_ }->{responses}->{'3xx'},
                responses_4xx => $results->{ $_ }->{responses}->{'4xx'},
                responses_5xx => $results->{ $_ }->{responses}->{'5xx'}
            };
        }
    }

    $self->{cache_name} = 'nginx_nginxplus_' . $options{custom}->get_hostname()  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_server_name}) ? md5_hex($self->{option_results}->{filter_server_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check http zones.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='serverzone'

=item B<--filter-server-name>

Filter server zone name (can be a regexp).

=item B<--filter-location-name>

Filter location zone name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'serverzone-requests', 'serverzone-requests-discarded', 'serverzone-traffic-in', 'serverzone-traffic-out',
'serverzone-responses-total', 'serverzone-responses-1xx', 'serverzone-responses-2xx', 'serverzone-responses-3xx', 
'serverzone-responses-4xx', 'serverzone-responses-5xx',
'locationzone-requests', 'locationzone-requests-discarded', 'locationzone-traffic-in', 'locationzone-traffic-out', 
'locationzone-responses-total', 'locationzone-responses-1xx', 'locationzone-responses-2xx', 'locationzone-responses-3xx',
'locationzone-responses-4xx', 'locationzone-responses-5xx'.

=back

=cut
