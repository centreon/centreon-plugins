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

package os::windows::wsman::mode::listservices;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'name:s' => { name => 'name' },
        'regexp' => { name => 'use_regexp' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{result} = $self->{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
        wql_filter => 'Select Name, DisplayName, StartMode, State From Win32_Service',
        result_type => 'hash',
        hash_key => 'Name'
    );
    foreach my $name (sort(keys %{$self->{result}})) {
        # Get all without a name
        next if (!defined($self->{option_results}->{name}));
        
        next if (!defined($self->{option_results}->{use_regexp}) && $name eq $self->{option_results}->{name});
        next if (defined($self->{option_results}->{use_regexp}) && $name =~ /$self->{option_results}->{name}/);
        
        $self->{output}->output_add(long_msg => "Skipping service '" . $name . "': no matching filter name");
        delete $self->{result}->{$name};
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{wsman} = wsman object
    $self->{wsman} = $options{wsman};

    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {
        $self->{output}->output_add(
            long_msg => "'" . $name . "' [DisplayName = " . $self->{output}->decode($self->{result}->{$name}->{DisplayName}) . '] [' . 
                'StartMode = ' . $self->{result}->{$name}->{StartMode} . '] [' .
                'State = ' . $self->{result}->{$name}->{State} .
                ']'
            );
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List services:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'display_name', 'start_mode', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;
    # $options{wsman} = wsman object
    $self->{wsman} = $options{wsman};

    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {     
        $self->{output}->add_disco_entry(
            name => $name,
            display_name => $self->{output}->decode($self->{result}->{$name}->{DisplayName}),
            start_mode => $self->{result}->{$name}->{StartMode},
            state => $self->{result}->{$name}->{State}
        );
    }
}

1;

__END__

=head1 MODE

List Windows Services.

=over 8

=item B<--name>

Set the service name.

=item B<--regexp>

Allows to use regexp to filter service name (with option --name).

=back

=cut
