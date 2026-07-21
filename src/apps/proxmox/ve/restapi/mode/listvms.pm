#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::proxmox::ve::restapi::mode::listvms;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw(is_excluded);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-name:s' => { name => 'include_name', default => '' },
        'filter-name:s'  => { redirect => 'include_name' },
        'exclude-name:s' => { name => 'exclude_name', default => '' },
        'include-tags:s'  => { name => 'include_tags', default => '' },
        'exclude-tags:s' => { name => 'exclude_tags', default => '' },
        'node-name:s'    => { name => 'node_name', default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $all_vms  = $options{custom}->api_list_vms();
    $self->{vms} = {};

    foreach my $vm_id (keys %{$all_vms}) {
        my $vm = $all_vms->{$vm_id};

        next if is_excluded($vm->{Name}, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});
        next if is_excluded($vm->{Tags}, $self->{option_results}->{include_tags}, $self->{option_results}->{exclude_tags}, output => $self->{output});
        next if is_excluded($vm->{Node}, $self->{option_results}->{node_name}, undef, output => $self->{output});

        $self->{vms}->{$vm_id} = $vm;
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $vm_id (sort keys %{$self->{vms}}) {
        $self->{output}->output_add(long_msg => '[id = ' . $vm_id . "][name = '" . $self->{vms}->{$vm_id}->{Name} . "']" .
            "[node = '" . $self->{vms}->{$vm_id}->{Node} . "']" .
            "[state = '" . $self->{vms}->{$vm_id}->{State} . "']" .
            "[vmid = '" . $self->{vms}->{$vm_id}->{Vmid} . "']" .
            "[type = '" . $self->{vms}->{$vm_id}->{Type} . "']" .
            "[tags = '" . ($self->{vms}->{$vm_id}->{Tags} // '') . "']"
        );
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List VMs:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

      $self->{output}->add_disco_format(elements => ['id', 'name', 'node' ,'state','type','vmid','tags']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $vm_id (sort keys %{$self->{vms}}) {
        $self->{output}->add_disco_entry(
            name => $self->{vms}->{$vm_id}->{Name},
            node => $self->{vms}->{$vm_id}->{Node},
            state => $self->{vms}->{$vm_id}->{State},
            id => $vm_id,
            type => $self->{vms}->{$vm_id}->{Type},
            vmid =>$self->{vms}->{$vm_id}->{Vmid},
            tags => $self->{vms}->{$vm_id}->{Tags},
        );
    }
}

1;

__END__

=head1 MODE

List VMs

=over 8

=back

=cut
