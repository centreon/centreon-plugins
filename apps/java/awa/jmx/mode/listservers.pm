#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package apps::java::awa::jmx::mode::listservers;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"   => { name => 'filter_name' },
                                  "filter-type:s"   => { name => 'filter_type' },
                                });
    $self->{servers} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{request} = [
         { mbean => 'Automic:name=*,side=Servers,type=*',
          attributes => [ { name => 'NetArea' }, { name => 'IpAddress' }, 
                          { name => 'Active' }, { name => 'Name' } ] },
    ];
    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 1);

    foreach my $mbean (keys %{$result}) {
        $mbean =~ /name=(.*?)(,|$)/i;
        my $name = $1;
        $mbean =~ /type=(.*?)(,|$)/i;
        my $type = $1;
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $type !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{servers}->{$name . '.' . $type} = { 
            name => $name, type => $type,
            ipaddress => $result->{$mbean}->{IpAddress},
            active => $result->{$mbean}->{Active} ? 'yes' : 'no',
            netarea => $result->{$mbean}->{NetArea},
        };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{servers}}) { 
        $self->{output}->output_add(long_msg => '[name = ' . $self->{servers}->{$instance}->{name} . "]" .
            " [type = '" . $self->{servers}->{$instance}->{type} . "']" .
            " [ipaddress = '" . $self->{servers}->{$instance}->{ipaddress} . "']" .
            " [active = '" . $self->{servers}->{$instance}->{active} . "']" .
            " [netarea = '" . $self->{servers}->{$instance}->{netarea} . "']"
        );
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List servers:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'type', 'ipaddress', 'active', 'netarea']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{servers}}) {             
        $self->{output}->add_disco_entry(
            %{$self->{servers}->{$instance}}
        );
    }
}

1;

__END__

=head1 MODE

List servers.

=over 8

=item B<--filter-name>

Filter by server name (can be a regexp).

=item B<--filter-type>

Filter by type (can be a regexp).

=back

=cut
    
