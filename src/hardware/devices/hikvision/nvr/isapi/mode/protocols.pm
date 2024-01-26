#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package hardware::devices::hikvision::nvr::isapi::mode::protocols;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_protocol_output {
    my ($self, %options) = @_;

    return sprintf(
        "protocol '%s' ",
        $options{instance}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'protocols', type => 1, cb_prefix_output => 'prefix_protocol_output', message_multiple => 'All protocols are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{protocols} = [
        {
            label => 'status',
            type => 2,
            set => {
                key_values => [ { name => 'enabled' }, { name => 'name' } ],
                output_template => 'enabled: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(endpoint => '/ISAPI/Security/adminAccesses/capabilities', force_array => ['AdminAccessProtocol']);
    if (!defined($result->{AdminAccessProtocol})) {
        $self->{output}->add_option_msg(short_msg => "Cannot find protocol informations");
        $self->{output}->option_exit();
    }

    $self->{protocols} = {};
    foreach (@{$result->{AdminAccessProtocol}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{protocol}->{content} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping protocol '" . $_->{protocol}->{content} . "'.", debug => 1);
            next;
        }

        $self->{protocols}->{ $_->{protocol}->{content} } = {
            name => $_->{protocol}->{content},
            enabled => $_->{enabled}->{content}
        };
    }
}

1;

__END__

=head1 MODE

Check protocols.

=over 8

=item B<--filter-name>

Filter protocols by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{enabled}, %{name}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{enabled}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{enabled}, %{name}
=back

=cut
