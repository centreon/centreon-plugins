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

package apps::microsoft::mscs::local::mode::listresources;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Win32::OLE;

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

my %map_state = (
    -1 => 'unknown',
    0 => 'inherited',
    1 => 'initializing',
    2 => 'online',
    3 => 'offline',
    4 => 'failed',
    128 => 'pending',
    129 => 'online pending',
    130 => 'offline pending',
);

my %map_class = (
    0 => 'unknown',
    1 => 'storage',
    2 => 'network',
    32768 => 'user',
);

sub manage_selection {
    my ($self, %options) = @_;

    # winmgmts:{impersonationLevel=impersonate,authenticationLevel=pktPrivacy}!\\.\root\mscluster
    my $wmi = Win32::OLE->GetObject('winmgmts:root\mscluster');
    if (!defined($wmi)) {
        $self->{output}->add_option_msg(short_msg => "Cant create server object:" . Win32::OLE->LastError());
        $self->{output}->option_exit();
    }
    
    $self->{resources} = {};
    my $query = "Select * from MSCluster_Resource";
    my $resultset = $wmi->ExecQuery($query);
    foreach my $obj (in $resultset) {
        my $name = $obj->{Name};
        my $state = $map_state{$obj->{State}};
        my $class = defined($obj->{ResourceClass}) ? $map_class{$obj->{ResourceClass}} : '-';
        my $id = defined($obj->{Id}) ? $obj->{Id} : $name;
        my $owner_node = defined($obj->{OwnerNode}) ? $obj->{OwnerNode} : '-';
    
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }
    
        $self->{resources}->{$id} = { name => $name, state => $state, owner_node => $owner_node,
                                      class =>  $class };
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection();
    foreach my $id (sort keys %{$self->{resources}}) {
        $self->{output}->output_add(long_msg => "'" . $self->{resources}->{$id}->{name} . 
            "' [state = " . $self->{resources}->{$id}->{state} . "]" . 
            "[owner node = " . $self->{resources}->{$id}->{owner_node} . "]" . 
            "[class = " . $self->{resources}->{$id}->{class} . "]");
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List Resources:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'state', 'id', 'owner_node', 'class']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(disco => 1);
    foreach my $id (sort keys %{$self->{resources}}) {     
        $self->{output}->add_disco_entry(name => $self->{resources}->{$id}->{name}, 
                                         state => $self->{resources}->{$id}->{state},
                                         id => $id,
                                         owner_node => $self->{resources}->{$id}->{owner_node},
                                         class => $self->{resources}->{$id}->{class});
    }
}

1;

__END__

=head1 MODE

List resources.

=over 8

=item B<--filter-name>

Filter resource name (can be a regexp).

=back

=cut
    
