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

package storage::fujitsu::eternus::dx::ssh::mode::physicaldisk;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $thresholds = {
    disk => [
        ['Available', 'OK'],
        ['Spare', 'OK'],
        ['Readying', 'OK'],
        ['Redundant Copy', 'OK'],
        ['Rebuild/Copyback', 'WARNING'],
        ['Available (Predictive Failure)', 'WARNING'],
        ['Present', 'OK'],
        ['Failed Usable', 'WARNING'],
        ['Formatting', 'WARNING'],
        ['Not Format', 'WARNING'],
        ['Not Supported', 'CRITICAL'],
        ['Not Available', 'CRITICAL'],
        ['Broken', 'CRITICAL'],
        ['Not Exist', 'CRITICAL'],
        ['Unknown', 'UNKNOWN']
    ]
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter:s@'             => { name => 'filter' },
        'threshold-overload:s@' => { name => 'threshold_overload' },
        'no-component:s'        => { name => 'no_component' }
    });

    $self->{no_components} = undef;
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
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }

    if (defined($self->{option_results}->{no_component})) {
        if ($self->{option_results}->{no_component} ne '') {
            $self->{no_components} = $self->{option_results}->{no_component};
        } else {
            $self->{no_components} = 'critical';
        }
    }
}

sub run {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'show',
        command_options => "disks\n",
        ssh_pipe => 1
    );

    #Location      Status                        Size    Type                Speed(rpm) Usage               Health(%)
    #------------- ----------------------------- ------- ------------------- ---------- ------------------- ---------
    #CE-Disk#0     Available                         4TB 3.5 SSD-H                 7200 System                    100
    #CE-Disk#1     Available                         4TB 3.5 SSD-M                 7200 System                      0
    #CE-Disk#2     Available                         4TB 3.5 SSD-L                 7200 System                      0
    #CE-Disk#3     Available                         4TB 3.5 Nearline SED          7200 System                      0
    
    my $total_components = 0;
    while ($stdout =~ /^(\S+)\s+(\S+)/msg) {
        my ($disk_name, $disk_status) = ($1, $2);
        next if ($disk_name =~ /Location|---/);
        next if ($disk_name !~ /Disk/i);

        next if ($self->check_filter(section => 'disk', instance => $disk_name));

        $total_components++;
        $self->{output}->output_add(long_msg => sprintf("Physical Disk '%s' status is '%s'", $disk_name, $disk_status));
        my $exit = $self->get_severity(section => 'disk', value => $disk_status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Physical Disk '%s' status is '%s'.", $disk_name, $disk_status)
            );
        }
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => sprintf("All %d physical disks are ok.", $total_components)
    );

    if (defined($self->{option_results}->{no_component}) && $total_components == 0) {
        $self->{output}->output_add(
            severity => $self->{no_components},
            short_msg => 'No components are checked.'
        );
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
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
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

Check Physical disks.

Command used: show disks

=over 8

=item B<--filter>

Exclude some parts (comma separated list)
You can also exclude items from specific instances: --filter=disk,CE-Disk#0

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,status,regexp).
Example: --threshold-overload='disk,CRITICAL,^(?!(Available|Spare)$)'

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=back

=cut
