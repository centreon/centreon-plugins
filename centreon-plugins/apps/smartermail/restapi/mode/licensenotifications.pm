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

package apps::smartermail::restapi::mode::licensenotifications;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use JSON::XS;

sub custom_threshold_output {
    my ($self, %options) = @_;
    my $status = 'ok';

    if ($self->{result_values}->{isUpgradeProtectionExpired_absolute} =~ /Expired/) {
        $status = 'critical';
    }
    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Upgrade protection status is '%s'", $self->{result_values}->{isUpgradeProtectionExpired_absolute});
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'protectionStatus', type => 0, message_separator => ' - ' },
        { name => 'counters', type => 0, message_separator => ' - ' },
    ];
    $self->{maps_counters}->{counters} = [
        { label => 'daysUntilUpgradeProtectionExpires', set => {
            key_values      => [ { name => 'daysUntilUpgradeProtectionExpires' } ],
            output_template => 'expires in %d days',
            perfdatas       => [
                { label => 'daysUntilUpgradeProtectionExpires', value => 'daysUntilUpgradeProtectionExpires_absolute', template => '%d', min => 0 },
            ],
        }
        }
    ];

    $self->{maps_counters}->{protectionStatus} = [
        { label => 'isUpgradeProtectionExpired', threshold => 0, set => {
            key_values => [ { name => 'isUpgradeProtectionExpired' } ],
            closure_custom_output => $self->can('custom_status_output'),
            closure_custom_perfdata => sub { return 0; },
            closure_custom_threshold_check => $self->can('custom_threshold_output')
        }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;


    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $jsonResponse = $options{custom}->get_endpoint(api_path => '/settings/sysadmin/license-notifications');

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

    $self->{counters} = '';
    $self->{counters} = {
        daysUntilUpgradeProtectionExpires => $response->{daysUntilUpgradeProtectionExpires},
    };

    $self->{protectionStatus} = '';
    $self->{protectionStatus} = {
        isUpgradeProtectionExpired => $response->{isUpgradeProtectionExpired} ? "Expired" : "Licensed"
    };
}


1;

__END__

=head1 MODE

Check upgrade protection expire

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'daysUntilUpgradeProtectionExpires'.

=item B<--critical-*>

Threshold critical.
Can be: 'daysUntilUpgradeProtectionExpires'.

=back

=cut
