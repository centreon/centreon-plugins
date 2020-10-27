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

package apps::smartermail::restapi::mode::services;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use JSON::XS;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'service', type => 1, cb_prefix_output => 'prefix_service_output',
            message_multiple => 'All services are ok' },
    ];

    $self->{maps_counters}->{service} = [
        { label => 'status', threshold => 0, set => {
            key_values      => [ { name => 'state' }, { name => 'display' }],
            closure_custom_perfdata => sub { return 0; },
            closure_custom_output => $self->can('custom_status_output'),
            closure_custom_threshold_check => \&catalog_status_threshold,
        }
        },
    ];
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg .= 'state is ' . $self->{result_values}->{state};
    return $msg;
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return "Service '" . $options{instance_value}->{display} ."' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
        {
            "filter-service:s" => { name => 'filter_service' },
            'unknown-status:s'  => { name => 'unknown_status', default => '' },
            'warning-status:s'  => { name => 'warning_status', default => '' },
            'critical-status:s' => { name => 'critical_status', default => '%{state} !~ /running/' },
        });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'warning_status', 'critical_status', 'unknown_status',
    ]);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $jsonResponse = $options{custom}->get_endpoint(api_path => '/settings/sysadmin/services');
   
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

    my $jsonServiceStates = $response->{services};
    my @services = ('spool', 'smtp', 'pop', 'xmpp', 'imap', 'ldap', 'popretrieval', 'imapretrieval', 'indexing');

    $self->{service} = {};
    foreach (@services) {
        if (defined($self->{option_results}->{filter_service}) && $self->{option_results}->{filter_service} ne '' &&
            $_ !~ /$self->{option_results}->{filter_service}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $_  . "': no matching filter.", debug => 1);
            next;
        }

        $self->{service}->{$_} = {
            display => $_,
            state => $jsonServiceStates->{$_} ? "running" : "inactive",
        };
    }
}


1;

__END__

=head1 MODE

Check service states

=over 8

=item B<--filter-service>

Only display some counters (regexp can be used).
(Example: --filter-service='spool|smtp|pop')

=item B<--unknown-status>

unknown status.
default: ''.

=item B<--warning-status>

warning status.
default: ''.

=item B<--critical-status>

critical status.
default: '%{state} !~ /running/'.

=back

=cut
