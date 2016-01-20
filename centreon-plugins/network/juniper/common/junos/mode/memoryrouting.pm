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

package network::juniper::common::junos::mode::memoryrouting;

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
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
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

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    my $oid_jnxOperatingDescr = '.1.3.6.1.4.1.2636.3.1.13.1.5';
    my $oid_jnxOperatingBuffer = '.1.3.6.1.4.1.2636.3.1.13.1.11';
    my $oid_jnxOperatingMemory = '.1.3.6.1.4.1.2636.3.1.13.1.15'; # MB
    
    my $result = $self->{snmp}->get_table(oid => $oid_jnxOperatingDescr, nothing_quit => 1);
    my $routing_engine_find = 0;
    my @oids_routing_engine = ();
    foreach my $oid (keys %$result) {        
        if ($result->{$oid} =~ /routing/i) {
            $routing_engine_find = 1;
            push @oids_routing_engine, $oid;
        }
    }
    
    if ($routing_engine_find == 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot find operating with 'routing' in description.");
        $self->{output}->option_exit();
    }
    
    my $multiple = 0;
    if (scalar(@oids_routing_engine) > 1) {
        $multiple = 1;
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf("All memory usages are ok"));
    }
    
    $self->{snmp}->load(oids => [$oid_jnxOperatingBuffer, $oid_jnxOperatingMemory],
                        instances => \@oids_routing_engine,
                        instance_regexp => "^" . $oid_jnxOperatingDescr . '\.(.+)');
    my $result2 = $self->{snmp}->get_leef();
    
    foreach my $oid_routing_engine (@oids_routing_engine) {
        $oid_routing_engine =~ /^$oid_jnxOperatingDescr\.(.+)/;
        my $instance = $1;
        my $description = $result->{$oid_jnxOperatingDescr . '.' . $instance};
        my $total_size = $result2->{$oid_jnxOperatingMemory . '.' . $instance} * 1024 * 1024;
        my $prct_used = $result2->{$oid_jnxOperatingBuffer . '.' . $instance};
        my $prct_free = 100 - $prct_used;
        my $memory_used = $total_size * $prct_used / 100;
        my $memory_free = $total_size - $memory_used;
            
        my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_size);
        my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $memory_used);
        my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $memory_free);
        
        $self->{output}->output_add(long_msg => sprintf("Memory '%s' Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                                            $description, $total_value . " " . $total_unit,
                                            $used_value . " " . $used_unit, $prct_used,
                                            $free_value . " " . $free_unit, $prct_free));
        if ($multiple == 0 || !$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Memory '%s' Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                                            $description, $total_value . " " . $total_unit,
                                            $used_value . " " . $used_unit, $prct_used,
                                            $free_value . " " . $free_unit, $prct_free));
        }
        
        my $extra_label = '';
        $extra_label = '_' . $description if ($multiple == 1);
        $self->{output}->perfdata_add(label => "used" . $extra_label, unit => 'B',
                                      value => $memory_used,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_size),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_size),
                                      min => 0, max => $total_size);
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Memory Usage of routing engine.

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
