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

package apps::backup::commvault::commserve::restapi::mode::liststoragepolicies;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-policy-name:s'  => { name => 'filter_policy_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $policies = $options{custom}->request(
        endpoint => '/V2/StoragePolicy'
    );

    my $results = [];
    foreach (@{$policies->{policies}}) {
        next if (defined($self->{option_results}->{filter_policy_name}) && $self->{option_results}->{filter_policy_name} ne '' &&
            $_->{storagePolicy}->{storagePolicyName} !~ /$self->{option_results}->{filter_policy_name}/);
        push @$results, $_;
    }
    return $results;
}

sub run {
    my ($self, %options) = @_;
  
    my $results = $self->manage_selection(%options);
    foreach (@$results) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[id = %s][name = %s]',
                $_->{storagePolicy}->{storagePolicyId},
                $_->{storagePolicy}->{storagePolicyName}
            )
        );
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List storage policies:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['id', 'name']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (@$results) {
        $self->{output}->add_disco_entry(
            id => $_->{storagePolicy}->{storagePolicyId},
            name => $_->{storagePolicy}->{storagePolicyName}
        );
    }
}

1;

__END__

=head1 MODE

List storage policies.

=over 8

=item B<--filter-policy-name>

Filter policies by name (can be a regexp).

=back

=cut
    
