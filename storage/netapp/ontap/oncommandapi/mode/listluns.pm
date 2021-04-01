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

package storage::netapp::ontap::oncommandapi::mode::listluns;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get(path => '/luns');

    foreach my $lun (@{$result}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $lun->{path} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $lun->{path} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{luns}->{$lun->{key}} = {
            path => $lun->{path},
            is_online => $lun->{is_online},
            is_mapped => $lun->{is_mapped},
            lun_class => $lun->{lun_class},
            alignment  => $lun->{alignment},
            multi_protocol_type  => $lun->{multi_protocol_type},
            size => $lun->{size},
        }
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $lun (sort keys %{$self->{luns}}) { 
        $self->{output}->output_add(long_msg => sprintf("[path = %s] [is_online = %s] [is_mapped = %s] [lun_class = %s] [alignment = %s] [multi_protocol_type = %s] [size = %s]",
                                                         $self->{luns}->{$lun}->{path}, $self->{luns}->{$lun}->{is_online},
                                                         $self->{luns}->{$lun}->{is_mapped}, $self->{luns}->{$lun}->{lun_class},
                                                         $self->{luns}->{$lun}->{alignment}, $self->{luns}->{$lun}->{multi_protocol_type},
                                                         $self->{luns}->{$lun}->{size}));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List luns:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['path', 'is_online', 'is_mapped', 'lun_class', 'alignment',
                                                   'multi_protocol_type', 'size']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $lun (sort keys %{$self->{luns}}) {             
        $self->{output}->add_disco_entry(
            path => $self->{luns}->{$lun}->{path},
            is_online => $self->{luns}->{$lun}->{is_online},
            is_mapped => $self->{luns}->{$lun}->{is_mapped},
            lun_class => $self->{luns}->{$lun}->{lun_class},
            alignment => $self->{luns}->{$lun}->{alignment},
            multi_protocol_type => $self->{luns}->{$lun}->{multi_protocol_type},
            size => $self->{luns}->{$lun}->{size},
        );
    }
}

1;

__END__

=head1 MODE

List LUNs.

=over 8

=item B<--filter-name>

Filter lun name (can be a regexp).

=back

=cut
