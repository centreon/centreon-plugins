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

package storage::emc::DataDomain::mode::filesystem;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use storage::emc::DataDomain::lib::functions;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'fs', type => 1, cb_prefix_output => 'prefix_fs_output', message_multiple => 'All filesystems are ok.' },
    ];

    $self->{maps_counters}->{fs} = [
        { label => 'usage', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_used_calc'),
                closure_custom_output => $self->can('custom_used_output'),
                threshold_use => 'used_prct', output_error_template => '%s',
                perfdatas => [
                    { value => 'used', label => 'used', cast_int => 1,
                      unit => 'B', min => 0, max => 'total', threshold_total => 'total', 
                      label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_fs_output {
    my ($self, %options) = @_;

    return "Filesystem '" . $options{instance_value}->{display} . "' ";
}

sub custom_used_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_free'} + $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_free'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free_prct} =  $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{used_prct} =  $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub custom_used_output {
    my ($self, %options) = @_;

    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});

    return sprintf(
        "Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
        $total_value . " " . $total_unit,
        $used_value . " " . $used_unit, $self->{result_values}->{used_prct},
        $free_value . " " . $free_unit, $self->{result_values}->{free_prct}
    );
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'name'              => { name => 'use_name' },
        'filesystem:s'      => { name => 'filesystem' },
        'regexp'            => { name => 'use_regexp' },
        'regexp-isensitive' => { name => 'use_regexpi' }
    });

    return $self;
}

my $oid_fileSystemSpaceEntry = '.1.3.6.1.4.1.19746.1.3.2.1.1';
my $oid_sysDescr = '.1.3.6.1.2.1.1.1'; # 'Data Domain OS 5.4.1.1-411752'
my ($oid_fileSystemResourceName, $oid_fileSystemSpaceUsed, $oid_fileSystemSpaceAvail);

sub add_result {
    my ($self, %options) = @_;

    $self->{fs}->{$options{instance}} = {};
    $self->{fs}->{$options{instance}}->{display} = $self->{results}->{$oid_fileSystemSpaceEntry}->{$oid_fileSystemResourceName . '.' . $options{instance}};    
    $self->{fs}->{$options{instance}}->{free} = int($self->{results}->{$oid_fileSystemSpaceEntry}->{$oid_fileSystemSpaceAvail . '.' . $options{instance}} * 1024 * 1024 * 1024);
    $self->{fs}->{$options{instance}}->{used} = int($self->{results}->{$oid_fileSystemSpaceEntry}->{$oid_fileSystemSpaceUsed . '.' . $options{instance}} * 1024 * 1024 * 1024);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{results} = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_sysDescr },
            { oid => $oid_fileSystemSpaceEntry },
        ], 
        nothing_quit => 1
    );
    if (!($self->{os_version} = storage::emc::DataDomain::lib::functions::get_version(value => $self->{results}->{$oid_sysDescr}->{$oid_sysDescr . '.0'}))) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'Cannot get DataDomain OS version.'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }
    if (centreon::plugins::misc::minimal_version($self->{os_version}, '5.x')) {
        $oid_fileSystemResourceName = '.1.3.6.1.4.1.19746.1.3.2.1.1.3';
        $oid_fileSystemSpaceUsed = '.1.3.6.1.4.1.19746.1.3.2.1.1.5';
        $oid_fileSystemSpaceAvail = '.1.3.6.1.4.1.19746.1.3.2.1.1.6';
    } else {
        $oid_fileSystemResourceName = '.1.3.6.1.4.1.19746.1.3.2.1.1.2';
        $oid_fileSystemSpaceUsed = '.1.3.6.1.4.1.19746.1.3.2.1.1.4';
        $oid_fileSystemSpaceAvail = '.1.3.6.1.4.1.19746.1.3.2.1.1.5';
    }

    if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{filesystem})) {
        if (!defined($self->{results}->{$oid_fileSystemSpaceEntry}->{$oid_fileSystemResourceName . '.' . $self->{option_results}->{filesystem}})) {
            $self->{output}->add_option_msg(short_msg => "No filesystem found for id '" . $self->{option_results}->{filesystem} . "'.");
            $self->{output}->option_exit();
        }
        $self->add_result(instance => $self->{option_results}->{filesystem});
    } else {
        foreach my $oid (keys %{$self->{results}->{$oid_fileSystemSpaceEntry}}) {
            next if ($oid !~ /^$oid_fileSystemResourceName\.(\d+)$/);
            my $instance = $1;
            my $filter_name = $self->{results}->{$oid_fileSystemSpaceEntry}->{$oid_fileSystemResourceName . '.' . $instance}; 
            if (!defined($self->{option_results}->{filesystem})) {
                $self->add_result(instance => $instance);
                next;
            }
            if (defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{filesystem}/i) {
                $self->add_result(instance => $instance);
            }
            if (defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{filesystem}/) {
                $self->add_result(instance => $instance);
            }
            if (!defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name eq $self->{option_results}->{filesystem}) {
                $self->add_result(instance => $instance);
            }
        }    
    }

    if (scalar(keys %{$self->{fs}}) <= 0 && !defined($options{disco})) {
        if (defined($self->{option_results}->{device})) {
            $self->{output}->add_option_msg(short_msg => "No filesystem found '" . $self->{option_results}->{filesystem} . "'.");
        } else {
            $self->{output}->add_option_msg(short_msg => 'No filesystem found.');
        }
        $self->{output}->option_exit();
    }
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'deviceid']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->manage_selection(disco => 1);
    foreach (sort keys %{$self->{fs}}) {
        $self->{output}->add_disco_entry(
            name => $self->{fs}->{$_}->{display},
            deviceid => $_
        );
    }
}

1;

__END__

=head1 MODE

Check filesystem usages. 

=over 8

=item B<--warning-usage>

Threshold warning in percent.

=item B<--critical-usage>

Threshold critical in percent

=item B<--filesystem>

Set the filesystem (number expected) ex: 1, 2,... (empty means 'check all filesystems').

=item B<--name>

Allows to use filesystem name with option --filesystem instead of devoce oid index.

=item B<--regexp>

Allows to use regexp to filter filesystems (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive to filter filesystems (with option --name).

=back

=cut
