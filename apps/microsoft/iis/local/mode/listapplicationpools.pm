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

package apps::microsoft::iis::local::mode::listapplicationpools;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Win32::OLE;

my %state_map = (
    0   => 'starting',
    1   => 'started',
    2   => 'stopping',
    3   => 'stopped',
    4   => 'unknown',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'name:s'         => { name => 'name' },
        'regexp'         => { name => 'use_regexp' },
        'filter-state:s' => { name => 'filter_state' }
    });

    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $wmi = Win32::OLE->GetObject('winmgmts:root\WebAdministration');
    if (!defined($wmi)) {
        $self->{output}->add_option_msg(short_msg => "Cant create server object:" . Win32::OLE->LastError());
        $self->{output}->option_exit();
    }
    my $query = 'SELECT Name, AutoStart FROM ApplicationPool';
    my $resultset = $wmi->ExecQuery($query);
    # AutoStart -> 1/0
	foreach my $obj (in $resultset) {
        my $name = $obj->{Name};
        my $auto_start = $obj->{AutoStart};
        my $state = $obj->GetState();
		
        if (defined($self->{option_results}->{filter_state}) && $state_map{$state} !~ /$self->{option_results}->{filter_state}/) {
            $self->{output}->output_add(long_msg => "Skipping application pool '" . $name . "': no matching filter state");
            next;
        }
		
        if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}) && $name ne $self->{option_results}->{name}) {
            $self->{output}->output_add(long_msg => "Skipping application pool '" . $name . "': no matching filter name");
            next;
        }
        if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && $name !~ /$self->{option_results}->{name}/) {
            $self->{output}->output_add(long_msg => "Skipping application pool '" . $name . "': no matching filter name (regexp)");
            next;
        }

        $self->{result}->{$name} = {AutoStart => $auto_start, State => $state};	
    }
}

sub run {
    my ($self, %options) = @_;
	
    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {
        $self->{output}->output_add(long_msg => 
            "'" . $name . "' .
            '[AutoStart = " . $self->{result}->{$name}->{AutoStart} . ']' .
            '[State = ' . $state_map{$self->{result}->{$name}->{State}} . ']'
        );
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List application pools:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'auto_start', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {     
        $self->{output}->add_disco_entry(
            name => $name,
            auto_start => $self->{result}->{$name}->{AutoStart},
            state => $state_map{$self->{result}->{$name}->{State}}
        );
    }
}

1;

__END__

=head1 MODE

List IIS Application Pools.

=over 8

=item B<--name>

Set the application pool name.

=item B<--regexp>

Allows to use regexp to filter application pool name (with option --name).

=item B<--filter-state>

Filter application pool state. Regexp can be used.
Available states are:
- 'started',
- 'starting',
- 'stopped',
- 'stopping'
- 'unknown'

=back

=cut
