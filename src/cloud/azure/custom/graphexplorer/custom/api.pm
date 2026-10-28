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

package cloud::azure::management::graphexplorer::custom::api;

use strict;
use warnings;
use base qw(cloud::azure::custom::api);

# Override check_options to make --subscription optional.
# Azure Resource Graph can query at tenant scope without a subscription.
sub check_options {
    my ($self, %options) = @_;

    $self->{timeout}            = (defined($self->{option_results}->{timeout}))            ? $self->{option_results}->{timeout}            : 10;
    $self->{subscription}       = (defined($self->{option_results}->{subscription}))       ? $self->{option_results}->{subscription}       : undef;
    $self->{tenant}             = (defined($self->{option_results}->{tenant}))             ? $self->{option_results}->{tenant}             : undef;
    $self->{client_id}          = (defined($self->{option_results}->{client_id}))          ? $self->{option_results}->{client_id}          : undef;
    $self->{client_secret}      = (defined($self->{option_results}->{client_secret}))      ? $self->{option_results}->{client_secret}      : undef;
    $self->{login_endpoint}     = (defined($self->{option_results}->{login_endpoint}))     ? $self->{option_results}->{login_endpoint}     : 'https://login.microsoftonline.com';
    $self->{management_endpoint} = (defined($self->{option_results}->{management_endpoint})) ? $self->{option_results}->{management_endpoint} : 'https://management.azure.com';
    $self->{api_version}        = (defined($self->{option_results}->{api_version}))        ? $self->{option_results}->{api_version}        : undef;

    # --subscription is optional for Resource Graph (tenant-scope queries are allowed)
    if (!defined($self->{tenant}) || $self->{tenant} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --tenant option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{client_id}) || $self->{client_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --client-id option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{client_secret}) || $self->{client_secret} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --client-secret option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{api_version}) || $self->{api_version} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-version option.");
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

1;

__END__

=head1 DESCRIPTION

B<custom>. Azure Resource Graph custom API mode.
Extends cloud::azure::custom::api with --subscription made optional,
allowing tenant-scoped Resource Graph queries.

=cut
