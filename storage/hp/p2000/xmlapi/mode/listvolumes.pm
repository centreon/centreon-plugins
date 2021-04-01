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

package storage::hp::p2000::xmlapi::mode::listvolumes;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'name:s'        => { name => 'name' },
        'regexp'        => { name => 'use_regexp' },
        'filter-type:s' => { name => 'filter_type' },
    });

    $self->{volume_name_selected} = [];

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    ($self->{results}) = $self->{p2000}->get_infos(
        cmd => 'show volumes', 
        base_type => 'volumes',
        key => 'volume-name', 
        properties_name => '^volume-type$'
    );
    foreach my $name (keys %{$self->{results}}) {
        my $volume_type = $self->{results}->{$name}->{'volume-type'};
        
        if (defined($self->{option_results}->{filter_type}) && $volume_type !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "Skipping volume '" . $name . "': no matching filter type");
            next;
        }
        
        # Get all without a name
        if (!defined($self->{option_results}->{name})) {
            push @{$self->{volume_name_selected}}, $name; 
            next;
        }
        
        if (!defined($self->{option_results}->{use_regexp}) && $name eq $self->{option_results}->{name}) {
            push @{$self->{volume_name_selected}}, $name;
            next;
        }
        if (defined($self->{option_results}->{use_regexp}) && $name =~ /$self->{option_results}->{name}/) {
            push @{$self->{volume_name_selected}}, $name;
            next;
        }
        
        $self->{output}->output_add(long_msg => "Skipping volume '" . $name . "': no matching filter name");
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{p2000} = $options{custom};
    
    $self->{p2000}->login();
    $self->manage_selection();
    foreach my $name (sort @{$self->{volume_name_selected}}) { 
        $self->{output}->output_add(long_msg => "'" . $name . "' [type = " . $self->{results}->{$name}->{'volume-type'}  . "]");
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List volumes:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'type']);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{p2000} = $options{custom};
    
    $self->{p2000}->login();
    $self->manage_selection();
    foreach my $name (sort @{$self->{volume_name_selected}}) {               
        $self->{output}->add_disco_entry(name => $name, type => $self->{results}->{$name}->{'volume-type'});
    }
}

1;

__END__

=head1 MODE

List volumes.

=over 8

=item B<--name>

Set the volume name.

=item B<--regexp>

Allows to use regexp to filter volume name (with option --name).

=item B<--filter-type>

Filter volume type. Regexp can be used.
Available types are:
- 'standard',
- 'standard*',
- 'snap-pool',
- 'master volume',
- 'snapshot',
- 'replication source'

=back

=cut
    
