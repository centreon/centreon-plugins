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

package apps::microsoft::iis::local::mode::webservicestatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Win32::OLE;
use Digest::MD5 qw(md5_hex);

sub prefix_site_output {
    my ($self, %options) = @_;

    return "Site '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'sites', type => 1, cb_prefix_output => 'prefix_site_output', message_multiple => 'All sites are ok' }
    ];

    $self->{maps_counters}->{sites} = [
        { label => 'connections-attempt', nlabel => 'site.connections.attempt.persecond', set => {
                key_values => [ { name => 'connections_attempt', per_second => 1 } ],
                output_template => 'connections attempt: %.2f/s',
                perfdatas => [
                    { template => '%.2f', unit => '/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'users-anonymous', nlabel => 'site.users.anonymous.persecond', display_ok => 0, set => {
                key_values => [ { name => 'anonymous_users', per_second => 1 } ],
                output_template => 'anonymous users: %.2f/s',
                perfdatas => [
                    { template => '%.2f', unit => '/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'requests-post', nlabel => 'site.requests.post.persecond', set => {
                key_values => [ { name => 'requests_post', per_second => 1 } ],
                output_template => 'requests post: %.2f/s',
                perfdatas => [
                    { template => '%.2f', unit => '/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'requests-get', nlabel => 'site.requests.get.persecond', set => {
                key_values => [ { name => 'requests_get', per_second => 1 } ],
                output_template => 'requests get: %.2f/s',
                perfdatas => [
                    { template => '%.2f', unit => '/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'traffic-in', nlabel => 'site.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 } ],
                output_template => 'traffic in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%d', unit => 'b/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'site.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 } ],
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%d', unit => 'b/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'files-received', nlabel => 'site.files.received.count', display_ok => 0, set => {
                key_values => [ { name => 'files_received', diff => 1 } ],
                output_template => 'files received: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'files-sent', nlabel => 'site.files.sent.count', display_ok => 0, set => {
                key_values => [ { name => 'files_sent', diff => 1 } ],
                output_template => 'files sent: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s'     => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $wmi = Win32::OLE->GetObject('winmgmts:root\cimv2');
    if (!defined($wmi)) {
        $self->{output}->add_option_msg(short_msg => "Cant create server object:" . Win32::OLE->LastError());
        $self->{output}->option_exit();
    }
    my $query = 'Select * From Win32_PerfRawData_W3SVC_WebService';
    my $resultset = $wmi->ExecQuery($query);
    $self->{sites} = {};
    foreach my $obj (in $resultset) {
        my $name = $obj->{Name};

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping site '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{sites}->{$name} = {
            name => $name,
            anonymous_users => $obj->{TotalAnonymousUsers},
            connections_attempt => $obj->{TotalConnectionAttemptsAllInstances},
            requests_get => $obj->{TotalGetRequests},
            requests_post => $obj->{TotalPostRequests},
            traffic_in => $obj->{TotalBytesReceived},
            traffic_out => $obj->{TotalBytesSent},
            files_received => $obj->{TotalFilesReceived},
            files_sent => $obj->{TotalFilesSent}
        };
    }

    if (scalar(keys %{$self->{sites}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No site found');
        $self->{output}->option_exit();
    }

    $self->{cache_name} = 'iis_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check IIS site statistics.

=over 8

=item B<--filter-name>

Filter site name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'connections-attempt', 'users-anonymous', 
'requests-post', 'requests-get', 'traffic-in', 'traffic-out'.
'files-received', 'files-sent'.

=back

=cut
