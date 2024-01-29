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

package os::linux::local::mode::listsystemdservices;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'         => { name => 'filter_name' },
        'filter-description:s'  => { name => 'filter_description' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    # check systemctl version to convert no-legend in legend=false (change in versions >= 248)
    my $legend_format= ' --no-legend';
    my ($stdout_version) = $options{custom}->execute_command(
        command         => 'systemctl',
        command_options => '--version'
    );
    $stdout_version =~ /^systemd\s(\d+)\s/;
    my $systemctl_version=$1;
    if($systemctl_version >= 248){
        $legend_format = ' --legend=false';
    }

    my $command_options_1 = '-a --no-pager --plain';
    my ($stdout)  = $options{custom}->execute_command(
        command         => 'systemctl',
        command_options => $command_options_1.$legend_format
    );

    my $results = {};

    #auditd.service                                                        loaded    active   running Security Auditing Service
    #avahi-daemon.service                                                  loaded    active   running Avahi mDNS/DNS-SD Stack
    #brandbot.service                                                      loaded    inactive dead    Flexible Branding Service
    while ($stdout =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+)/mig) {
        my ($name, $load, $active, $sub, $desc) = ($1, $2, $3, $4, $5);
        $desc =~ s/\s+$//;

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_description}) && $self->{option_results}->{filter_description} ne '' &&
            $desc !~ /$self->{option_results}->{filter_description}/);

        $results->{$name} = { load => $load, active => $active, sub => $sub, desc => $desc };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;
	
    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $name (sort(keys %$results)) {
        $self->{output}->output_add(long_msg => "'" . $name . "' [desc = " . $results->{$name}->{desc} . '] [load = ' . $results->{$name}->{load} . '] [active = ' . $results->{$name}->{active} . '] [sub = ' . $results->{$name}->{sub} . ']');
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List systemd services:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'description', 'load', 'active', 'sub']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $name (sort(keys %$results)) {     
        $self->{output}->add_disco_entry(
            name => $name,
            description => $results->{$name}->{desc},
            load => $results->{$name}->{load},
            active => $results->{$name}->{active},
            sub => $results->{$name}->{sub}
        );
    }
}

1;

__END__

=head1 MODE

List systemd services.

Command used: systemctl -a --no-pager --no-legend --plain
Command change for systemctl version >= 248 : --no-legend is converted in legend=false

=over 8

=item B<--filter-name>

Filter services name (regexp can be used).

=item B<--filter-description>

Filter services description (regexp can be used).

=back

=cut
