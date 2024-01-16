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

package apps::microsoft::iis::wsman::mode::listapplicationpools;

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

my $state_map = {
    1 => 'started',
    2 => 'starting',
    3 => 'stopped',
    4 => 'stopping'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/MicrosoftIISv2/*',
        wql_filter => 'Select AppPoolState, AppPoolAutoStart, Name From IIsApplicationPoolSetting',
        result_type => 'hash',
        hash_key => 'Name'
    );

    foreach my $name (keys %$results) {
        $results->{$name}->{AppPoolState} = $state_map->{ $results->{$name}->{AppPoolState} };
        $results->{$name}->{AppPoolAutoStart} = $results->{$name}->{AppPoolAutoStart} =~ /^(?:1|true)$/i ? 'on' : 'off';
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(wsman => $options{wsman});
    foreach my $name (sort(keys %$results)) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[name: %s][auto_start: %s][state: %s]',
                $name,
                $results->{$name}->{AppPoolAutoStart},
                $results->{$name}->{AppPoolState}
            )
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

    my $results = $self->manage_selection(wsman => $options{wsman});
    foreach my $name (sort(keys %$results)) {
        $self->{output}->add_disco_entry(
            name => $name,
            auto_start => $results->{$name}->{AppPoolAutoStart},
            state => $results->{$name}->{AppPoolState}
        );
    }
}

1;

__END__

=head1 MODE

List IIS Application Pools.
Need to install IIS WMI provider by installing the IIS Management Scripts and Tools component (compatibility IIS 6.0).

=over 8

=back

=cut
