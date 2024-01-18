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

package apps::backup::quadstor::local::mode::listvtl;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

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

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);

    foreach (sort keys %{$self->{vtl}}) {        
        $self->{output}->output_add(long_msg => "'" . $_ . "' [type = " . $self->{vtl}->{$_}->{type}  . "]");
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List VTL:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'type']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (sort keys %{$self->{vtl}}) {
        $self->{output}->add_disco_entry(
            name => $_,
            active => $self->{vtl}->{$_}->{type}
        );
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'vtconfig',
        command_options => '-l',
        command_path => '/quadstorvtl/bin'
    );

    #Name                           DevType  Type
    #BV00002                        VTL      IBM IBM System Storage TS3100
    $self->{vtl} = {};
    my @lines = split /\n/, $stdout;
    shift @lines;
    foreach (@lines) {
        next if (! /^(\S+)\s+(\S+)/);

        my ($name, $type) = ($1, $2);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' && 
            $name !~ /$self->{option_results}->{filter_name}/i) {
            $self->{output}->output_add(long_msg => "skipping vtl '" . $name . "':  no matching filter");
            next;
        }
        
        $self->{vtl}->{$name} = { type => $type };
    }
}

1;

__END__

=head1 MODE

List VTL.

Command used: '/quadstorvtl/bin/vtconfig -l'

=over 8

=item B<--filter-name>

Filter vtl name (can be a regexp).

=back

=cut
