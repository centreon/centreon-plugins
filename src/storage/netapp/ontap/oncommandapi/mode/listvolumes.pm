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

package storage::netapp::ontap::oncommandapi::mode::listvolumes;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $svms = $options{custom}->get(path => '/storage-vms');
    my $volumes = $options{custom}->get(path => '/volumes');

    my $results = [];
    foreach my $volume (@$volumes) {
        my $svm_name = $options{custom}->get_record_attr(records => $svms, key => 'key', value => $volume->{storage_vm_key}, attr => 'name');
        $svm_name = 'root' if (!defined($svm_name));

        push @$results, {
            key => $volume->{key},
            name => $volume->{name},
            svm => $svm_name,
            state => defined($volume->{state}) ? $volume->{state} : 'none',
            vol_type => $volume->{vol_type},
            style  => $volume->{style},
            is_replica_volume  => $volume->{is_replica_volume},
            size_total => $volume->{size_total}
        }
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;
  
    my $results = $self->manage_selection(%options);
    foreach (@$results) {
        $self->{output}->output_add(
            long_msg => sprintf(
                "[key: %s] [name: %s] [svm: %s] [state: %s] [vol_type: %s] [style: %s] [is_replica_volume: %s] [size_total: %s]",
                $_->{key},
                $_->{name},
                $_->{svm},
                $_->{state},
                $_->{vol_type},
                $_->{style},
                $_->{is_replica_volume},
                $_->{size_total}
            )
        );
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List volumes:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;  
    
    $self->{output}->add_disco_format(
        elements => [
            'key', 'name', 'svm', 'state', 'vol_type', 'style',
            'is_replica_volume', 'size_total'
        ]
    );
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (@$results) {          
        $self->{output}->add_disco_entry(%$_);
    }
}

1;

__END__

=head1 MODE

List volumes.

=over 8

=back

=cut
