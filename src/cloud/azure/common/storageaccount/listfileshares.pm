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

package cloud::azure::common::storageaccount::listfileshares;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                    "resource-group:s"         => { name => 'resource_group' },
                                    "storage-account:s"        => { name => 'storage_account' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{api_version} = '2022-05-01';
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{fileshares} = $options{custom}->azure_list_file_shares(
        api_version => $self->{api_version},
        storage_account => $self->{option_results}->{storage_account},
        resource_group => $self->{option_results}->{resource_group}
    );
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $fileshare (@{$self->{fileshares}}) {

        $self->{output}->output_add(long_msg => sprintf("[fileshare = %s][resourcegroup = %s][storageaccount = %s]",
            $fileshare->{name},
            $self->{option_results}->{resource_group},
            $self->{option_results}->{storage_account}
        ));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List fileshares:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['fileshare', 'resourcegroup', 'storageaccount']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $fileshare (@{$self->{fileshares}}) {

        $self->{output}->add_disco_entry(
            fileshare => $fileshare->{name},
            resourcegroup => $self->{option_results}->{resource_group},
            storageaccount => $self->{option_results}->{storage_account}
        );
    }
}

1;

__END__

=head1 MODE

List fileshares belonging to a given storage account.

=over 8

=item B<--resource-group>

Set resource group.

=item B<--storage-account>

Set storage account.

=back

=cut
