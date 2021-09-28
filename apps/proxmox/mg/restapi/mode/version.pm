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

package apps::proxmox::mg::restapi::mode::version;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_version_output {
    my ($self, %options) = @_;
    
    return sprintf(
        'pmg version: %s [release: %s][repoid: %s]',
        $self->{result_values}->{version},
        $self->{result_values}->{release},
        $self->{result_values}->{repoid}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'version', type => 0 }
    ];
    
    $self->{maps_counters}->{version} = [
        { label => 'version', type => 2, set => {
                key_values => [ { name => 'version' }, { name => 'repoid' }, { name => 'release' } ],
                closure_custom_output => $self->can('custom_version_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{version} = $options{custom}->request(endpoint => '/version');
}

1;

__END__

=head1 MODE

Check version.

=over 8

=item B<--warning-version>

Set warning threshold for version.
Can used special variables like: %{version}, %{repoid}, %{release}

=item B<--critical-version>

Set critical threshold for version.
Can used special variables like: %{version}, %{repoid}, %{release}

=back

=cut
