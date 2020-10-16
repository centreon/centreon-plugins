#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package storage::emc::vplex::restapi::mode::directors;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $thresholds = {
    director_health => [
        ['ok', 'OK'],
        ['.*', 'CRITICAL'],
    ],
    director_communication => [
        ['ok', 'OK'],
        ['.*', 'CRITICAL'],
    ],
    director_temperature => [
        ['false', 'OK'],
        ['.*', 'CRITICAL'],
    ],
    director_voltage => [
        ['false', 'OK'],
        ['.*', 'CRITICAL'],
    ],
    director_vplex_splitter => [
        ['ok', 'OK'],
        ['.*', 'CRITICAL'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
               {
                "engine:s"        => { name => 'engine' },
                "filter:s@"      => { name => 'filter' },
                "threshold-overload:s@"   => { name => 'threshold_overload' },
               });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    $self->{filter} = [];
    foreach my $val (@{$self->{option_results}->{filter}}) {
        next if (!defined($val) || $val eq '');
        my @values = split (/,/, $val);
        push @{$self->{filter}}, { filter => $values[0], instance => $values[1] }; 
    }

    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        next if (!defined($val) || $val eq '');
        my @values = split (/,/, $val);
        if (scalar(@values) < 3) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $instance, $status, $filter);
        if (scalar(@values) == 3) {
            ($section, $status, $filter) = @values;
            $instance = '.*';
        } else {
             ($section, $instance, $status, $filter) = @values;
        }
        if ($section !~ /^director/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload section '" . $val . "'.");
            $self->{output}->option_exit();
        }
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status, instance => $instance };
    }
}

sub run {
    my ($self, %options) = @_;
    my $vplex = $options{custom};

    my $items = $vplex->get_items(
        url => '/vplex/engines/',
        parent => 1,
        parent_filter => $self->{option_results}->{engine},
        parent_filter_prefix => 'engine-',
        parent_select => '/engines/(.*?)/',
        obj => 'directors'
    );

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All Directors are OK');
    foreach my $engine_name (sort keys %{$items}) {
        foreach my $director_name (sort keys %{$items->{$engine_name}}) {
            my $instance = $engine_name . '_' . $director_name;

            next if ($self->check_filter(section => 'director', instance => $instance));
            
            $self->{output}->output_add(long_msg => sprintf("Director '%s' health state is '%s' [communication status: %s, temperature threshold exceeded: %s, voltage threshold exceeded: %s, vplex splitter status: %s]", 
                                                            $instance, 
                                                            $items->{$engine_name}->{$director_name}->{'health-state'},
                                                            $items->{$engine_name}->{$director_name}->{'communication-status'},
                                                            $items->{$engine_name}->{$director_name}->{'temperature-threshold-exceeded'},
                                                            $items->{$engine_name}->{$director_name}->{'voltage-threshold-exceeded'},
                                                            defined($items->{$engine_name}->{$director_name}->{'vplex-splitter-status'}) ? $items->{$engine_name}->{$director_name}->{'vplex-splitter-status'} : '-'));

            my $exit = $self->get_severity(section => 'director_health', instance => $instance, value => $items->{$engine_name}->{$director_name}->{'health-state'});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Director '%s' health state is %s", 
                                                            $instance, $items->{$engine_name}->{$director_name}->{'health-state'}));
            }
            $exit = $self->get_severity(section => 'director_communication', value => $items->{$engine_name}->{$director_name}->{'communication-status'});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Director '%s' communication status is %s", 
                                                                 $instance, $items->{$engine_name}->{$director_name}->{'communication-status'}));
            }
            $exit = $self->get_severity(section => 'director_temperature', value => $items->{$engine_name}->{$director_name}->{'temperature-threshold-exceeded'});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Director '%s' temperature threshold exceeded is %s", 
                                                                 $instance, $items->{$engine_name}->{$director_name}->{'temperature-threshold-exceeded'}));
            }
            $exit = $self->get_severity(section => 'director_voltage', value => $items->{$engine_name}->{$director_name}->{'voltage-threshold-exceeded'});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Director '%s' voltage threshold exceeded is %s", 
                                                                 $instance, $items->{$engine_name}->{$director_name}->{'voltage-threshold-exceeded'}));
            }
            
            if (defined($items->{$engine_name}->{$director_name}->{'vplex-splitter-status'})) {
                $exit = $self->get_severity(section => 'director_vplex_splitter', value => $items->{$engine_name}->{$director_name}->{'vplex-splitter-status'});
                if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                    $self->{output}->output_add(severity => $exit,
                                                short_msg => sprintf("Director '%s' vplex splitter status is %s", 
                                                                 $instance, $items->{$engine_name}->{$director_name}->{'vplex-splitter-status'}));
                }
            }
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub check_filter {
    my ($self, %options) = @_;

    foreach (@{$self->{filter}}) {
        if ($options{section} =~ /$_->{filter}/) {
            if (!defined($options{instance}) && !defined($_->{instance})) {
                $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section."));
                return 1;
            } elsif (defined($options{instance}) && $options{instance} =~ /$_->{instance}/) {
                $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section $options{instance} instance."));
                return 1;
            }
        }
    }
    
    return 0;
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
           if ($options{value} =~ /$_->{filter}/i && 
                (!defined($options{instance}) || $options{instance} =~ /$_->{instance}/)) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    my $label = defined($options{label}) ? $options{label} : $options{section};
    foreach (@{$thresholds->{$label}}) {
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

1;

__END__

=head1 MODE

Check Directors state for VPlex

=over 8

=item B<--engine>

Specify the engine number to be checked (1-1 or 2-1 usually)

=item B<--filter>

Filter some parts (comma seperated list)
Can also exclude specific instance: --filter=director,engine-1-1_director-1-1-B

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='director_temperature,CRITICAL,^(?!(false)$)'

=back

=cut
