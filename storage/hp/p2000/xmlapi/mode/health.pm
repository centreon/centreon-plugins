#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package storage::hp::p2000::xmlapi::mode::health;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use storage::hp::p2000::xmlapi::mode::components::disk;
use storage::hp::p2000::xmlapi::mode::components::vdisk;
use storage::hp::p2000::xmlapi::mode::components::sensors;
use storage::hp::p2000::xmlapi::mode::components::fru;
use storage::hp::p2000::xmlapi::mode::components::enclosure;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "exclude:s"        => { name => 'exclude' },
                                  "component:s"      => { name => 'component', default => 'all' },
                                  "no-component:s"   => { name => 'no_component' },
                                });

    $self->{components} = {};
    $self->{no_components} = undef;
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (defined($self->{option_results}->{no_component})) {
        if ($self->{option_results}->{no_component} ne '') {
            $self->{no_components} = $self->{option_results}->{no_component};
        } else {
            $self->{no_components} = 'critical';
        }
    }
}

sub component {
    my ($self, %options) = @_;
    
    if ($self->{option_results}->{component} eq 'all') {
        storage::hp::p2000::xmlapi::mode::components::disk::check($self);
        storage::hp::p2000::xmlapi::mode::components::vdisk::check($self);
        storage::hp::p2000::xmlapi::mode::components::sensors::check($self);
        storage::hp::p2000::xmlapi::mode::components::fru::check($self);
        storage::hp::p2000::xmlapi::mode::components::enclosure::check($self);
    } elsif ($self->{option_results}->{component} eq 'disk') {
        storage::hp::p2000::xmlapi::mode::components::disk::check($self);
    } elsif ($self->{option_results}->{component} eq 'vdisk') {
        storage::hp::p2000::xmlapi::mode::components::vdisk::check($self);
    } elsif ($self->{option_results}->{component} eq 'sensor') {
        storage::hp::p2000::xmlapi::mode::components::sensors::check($self);
    } elsif ($self->{option_results}->{component} eq 'fru') {
        storage::hp::p2000::xmlapi::mode::components::fru::check($self);
    } elsif ($self->{option_results}->{component} eq 'enclosure') {
        storage::hp::p2000::xmlapi::mode::components::enclosure::check($self);
    } else {
        $self->{output}->add_option_msg(short_msg => "Wrong option. Cannot find component '" . $self->{option_results}->{component} . "'.");
        $self->{output}->option_exit();
    }
    
    my $total_components = 0;
    my $display_by_component = '';
    my $display_by_component_append = '';
    foreach my $comp (sort(keys %{$self->{components}})) {
        # Skipping short msg when no components
        next if ($self->{components}->{$comp}->{total} == 0 && $self->{components}->{$comp}->{skip} == 0);
        $total_components += $self->{components}->{$comp}->{total} + $self->{components}->{$comp}->{skip};
        $display_by_component .= $display_by_component_append . $self->{components}->{$comp}->{total} . '/' . $self->{components}->{$comp}->{skip} . ' ' . $self->{components}->{$comp}->{name};
        $display_by_component_append = ', ';
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %s components [%s] are ok.", 
                                                     $total_components,
                                                     $display_by_component)
                                );

    if (defined($self->{option_results}->{no_component}) && $total_components == 0) {
        $self->{output}->output_add(severity => $self->{no_components},
                                    short_msg => 'No components are checked.');
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{p2000} = $options{custom};
    
    $self->{p2000}->login();
    $self->component();

    $self->{output}->display();
    $self->{output}->exit();
}

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($options{instance})) {
        if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)${options{section}}[^,]*#\Q$options{instance}\E#/) {
            $self->{components}->{$options{section}}->{skip}++;
            $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section $options{instance} instance."));
            return 1;
        }
    } elsif (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)$options{section}(\s|,|$)/) {
        $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section."));
        return 1;
    }
    return 0;
}

1;

__END__

=head1 MODE

Check health status of storage.

=over 8

=item B<--component>

Which component to check (Default: 'all').
Can be: 'disk', 'vdisk', 'sensor', 'enclosure', 'fru'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=fru)
Can also exclude specific instance: --exclude=disk#disk_1.4#,sensor#Temperature Loc: lower-IOM B#

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=back

=cut