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

package apps::microsoft::mscs::local::mode::listnodes;

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
    0 => 'up',
    1 => 'down',
    2 => 'paused',
    3 => 'joining',
);

sub manage_selection {
    my ($self, %options) = @_;

    # winmgmts:{impersonationLevel=impersonate,authenticationLevel=pktPrivacy}!\\.\root\mscluster
    my $wmi = Win32::OLE->GetObject('winmgmts:root\mscluster');
    if (!defined($wmi)) {
        $self->{output}->add_option_msg(short_msg => "Cant create server object:" . Win32::OLE->LastError());
        $self->{output}->option_exit();
    }
    
    $self->{nodes} = {};
    my $query = "Select * from MSCluster_Node";
    my $resultset = $wmi->ExecQuery($query);
    foreach my $obj (in $resultset) {
        my $name = $obj->{Name};
        my $state = $map_state{$obj->{State}};
    
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }
    
        $self->{nodes}->{$name} = { name => $name, state => $state };
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection();
    foreach my $name (sort keys %{$self->{nodes}}) {
        $self->{output}->output_add(long_msg => "'" . $name . "' [state = " . $self->{nodes}->{$name}->{state} . "]");
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List Nodes:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(disco => 1);
    foreach my $name (sort keys %{$self->{nodes}}) {     
        $self->{output}->add_disco_entry(name => $name, state => $self->{nodes}->{$name}->{state});
    }
}

1;

__END__

=head1 MODE

List nodes.

=over 8

=item B<--filter-name>

Filter node name (can be a regexp).

=back

=cut
    
