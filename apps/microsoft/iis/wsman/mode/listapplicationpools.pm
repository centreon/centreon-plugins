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

package apps::microsoft::iis::wsman::mode::listapplicationpools;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %state_map = (
    1   => 'started',
    2   => 'starting',
    3   => 'stopped',
    4   => 'stopping'
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "name:s"          => { name => 'name' },
                                  "regexp"          => { name => 'use_regexp' },
                                  "filter-state:s"  => { name => 'filter_state' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{result} = $self->{wsman}->request(uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/MicrosoftIISv2/*',
                                              wql_filter => 'Select AppPoolState, AppPoolAutoStart, Name From IIsApplicationPoolSetting',
                                              result_type => 'hash',
                                              hash_key => 'Name');
    # AppPoolAutoStart -> true/false
    # AppPoolState -> 1=started, 2=starting, 3 = stopped, 4=stopping
    foreach my $name (sort(keys %{$self->{result}})) {
        if (defined($self->{option_results}->{filter_state}) && $state_map{$self->{result}->{$name}->{AppPoolState}} !~ /$self->{option_results}->{filter_state}/) {
            $self->{output}->output_add(long_msg => "Skipping application pool '" . $name . "': no matching filter state");
            delete $self->{result}->{$name};
            next;
        }
    
        # Get all without a name
        next if (!defined($self->{option_results}->{name}));
        
        next if (!defined($self->{option_results}->{use_regexp}) && $name eq $self->{option_results}->{name});
        next if (defined($self->{option_results}->{use_regexp}) && $name =~ /$self->{option_results}->{name}/);
        
        $self->{output}->output_add(long_msg => "Skipping application pool '" . $name . "': no matching filter name");
        delete $self->{result}->{$name};
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{wsman} = wsman object
    $self->{wsman} = $options{wsman};

    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {
        $self->{output}->output_add(long_msg => "'" . $name . "' [AutoStart = " . $self->{result}->{$name}->{AppPoolAutoStart} . '] [' . 
                                    'State = ' . $state_map{$self->{result}->{$name}->{AppPoolState}} .
                                    ']');
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List application pools:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'auto_start', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;
    # $options{wsman} = wsman object
    $self->{wsman} = $options{wsman};

    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {     
        $self->{output}->add_disco_entry(name => $name,
                                         auto_start => $self->{result}->{$name}->{AppPoolAutoStart},
                                         state => $state_map{$self->{result}->{$name}->{AppPoolState}}
                                         );
    }
}

1;

__END__

=head1 MODE

List IIS Application Pools.
Need to install IIS WMI provider by installing the IIS Management Scripts and Tools component (compatibility IIS 6.0).

=over 8

=item B<--name>

Set the application pool name.

=item B<--regexp>

Allows to use regexp to filter application pool name (with option --name).

=item B<--filter-state>

Filter application pool state. Regexp can be used.

=back

=cut
