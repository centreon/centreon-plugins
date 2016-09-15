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

package centreon::common::cisco::standard::snmp::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"               => { name => 'warning' },
                                  "critical:s"              => { name => 'critical' },
                                  "filter-pool:s"           => { name => 'filter_pool' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub check_table_memory {
    my ($self, %options) = @_;

    my $checked = 0;
    foreach my $oid (keys %{$self->{results}->{$options{entry}}}) {
        next if ($oid !~ /^$options{poolName}/);
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;
        my $memory_name = $self->{results}->{$options{entry}}->{$oid};
        my $memory_used = $self->{results}->{$options{entry}}->{$options{poolUsed} . '.' . $instance};
        my $memory_free = $self->{results}->{$options{entry}}->{$options{poolFree} . '.' . $instance};
        
        next if ($memory_name eq '');
        if (defined($self->{option_results}->{filter_pool}) && $self->{option_results}->{filter_pool} ne '' &&
            $memory_name !~ /$self->{option_results}->{filter_pool}/) {
            $self->{output}->output_add(long_msg => "Skipping pool '" . $memory_name . "'.");	
            next;
        }

        $checked = 1;

        my $total_size = $memory_used + $memory_free;
        my $prct_used = $memory_used * 100 / $total_size;
        my $prct_free = 100 - $prct_used;

        my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_size);
        my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $memory_used);
        my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $memory_free);

        $self->{output}->output_add(long_msg => sprintf("Memory '%s' Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", $memory_name,
                                            $total_value . " " . $total_unit,
                                            $used_value . " " . $used_unit, $prct_used,
                                            $free_value . " " . $free_unit, $prct_free));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
             $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Memory '%s' Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", $memory_name,
                                            $total_value . " " . $total_unit,
                                            $used_value . " " . $used_unit, $prct_used,
                                            $free_value . " " . $free_unit, $prct_free));
        }

        $self->{output}->perfdata_add(label => "used_" . $memory_name, unit => 'B',
                                      value => $memory_used,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_size),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_size),
                                      min => 0, max => $total_size);
    }
    
    return $checked;
}

sub check_percent_memory {
    my ($self, %options) = @_;

    my $checked = 0;
    foreach my $oid (keys %{$self->{results}->{$options{entry}}}) {
        next if ($oid !~ /^$options{memUsage}/);
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;
        my $memory_usage = $self->{results}->{$options{entry}}->{$oid};

        next if ($memory_usage eq '');

        $checked = 1;

        my $exit = $self->{perfdata}->threshold_check(value => $memory_usage,
                               threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Memory used : %.2f%%", $memory_usage));
        }

        $self->{output}->perfdata_add(label => "utilization",
                                      value => $memory_usage,
                                      unit => "%",
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0, max => 100);
    }

    return $checked;
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_ciscoMemoryPoolEntry = '.1.3.6.1.4.1.9.9.48.1.1.1';
    my $oid_ciscoMemoryPoolName = '.1.3.6.1.4.1.9.9.48.1.1.1.2';
    my $oid_ciscoMemoryPoolUsed = '.1.3.6.1.4.1.9.9.48.1.1.1.5'; # in B
    my $oid_ciscoMemoryPoolFree = '.1.3.6.1.4.1.9.9.48.1.1.1.6'; # in B

    # OIDs for Nexus
    my $oid_cseSysMemoryEntry = '.1.3.6.1.4.1.9.9.305.1.1';
    my $oid_cseSysMemoryUtilization = '.1.3.6.1.4.1.9.9.305.1.1.2';

    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_ciscoMemoryPoolEntry,
                                                              start => $oid_ciscoMemoryPoolName, end => $oid_ciscoMemoryPoolFree
                                                            },
                                                            { oid => $oid_cseSysMemoryEntry,
                                                              start => $oid_cseSysMemoryUtilization, end => $oid_cseSysMemoryUtilization }],
                                                   nothing_quit => 1);
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'Memory is ok.');
    
    if (!$self->check_table_memory(entry => $oid_ciscoMemoryPoolEntry, poolName => $oid_ciscoMemoryPoolName, poolUsed => $oid_ciscoMemoryPoolUsed, poolFree => $oid_ciscoMemoryPoolFree)
        && !$self->check_percent_memory(entry => $oid_cseSysMemoryEntry, memUsage => $oid_cseSysMemoryUtilization)
        ) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => sprintf("Cannot find Memory informations."));
    }

    $self->{output}->display();
    $self->{output}->exit();
    
}

1;

__END__

=head1 MODE

Check memory usage (CISCO-MEMORY-POOL-MIB and CISCO-SYSTEM-EXT-MIB).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=item B<--filter-pool>

Filter pool to check (can use regexp).

=back

=cut
    
