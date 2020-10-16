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

package storage::emc::vplex::restapi::mode::distributeddevices;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $thresholds = {
    device_health => [
        ['ok', 'OK'],
        ['.*', 'CRITICAL'],
    ],
    device_opstatus => [
        ['ok', 'OK'],
        ['.*', 'CRITICAL'],
    ],
    device_service => [
        ['running', 'OK'],
        ['.*', 'CRITICAL'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
               {
               "filter:s@"               => { name => 'filter' },
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
        if ($section !~ /^device/) {
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

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All Distributed devices are OK');

    my $items = $vplex->get_items(url => '/vplex/distributed-storage/distributed-devices/');
    foreach my $name (sort keys %{$items}) {
        my $instance = $name;

        next if ($self->check_filter(section => 'device', instance => $instance));
        
        $self->{output}->output_add(long_msg => sprintf("Distributed device '%s' health state is '%s' [service status: %s, operational status: %s]", 
                                                        $instance, 
                                                        $items->{$name}->{'health-state'}, 
                                                        $items->{$name}->{'service-status'},
                                                        $items->{$name}->{'operational-status'},
                                                        ));

        my $exit = $self->get_severity(section => 'device_health', instance => $instance, value => $items->{$name}->{'health-state'});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Distributed device '%s' health state is %s", 
                                                        $instance, $items->{$name}->{'health-state'}));
        }
        $exit = $self->get_severity(section => 'device_service', value => $items->{$name}->{'service-status'});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Distributed device '%s' service status is %s", 
                                                             $instance, $items->{$name}->{'service-status'}));
        }
        $exit = $self->get_severity(section => 'device_opstatus', value => $items->{$name}->{'operational-status'});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Distributed device '%s' operational status is %s", 
                                                             $instance, $items->{$name}->{'operational-status'}));
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

Check distributed devices for VPlex

=over 8

=item B<--filter>

Filter some parts (comma seperated list)
Can also exclude specific instance: --filter=component,cluster-1

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='component_opstatus,CRITICAL,^(?!(in-contact|cluster-in-contact)$)'

=back

=cut
