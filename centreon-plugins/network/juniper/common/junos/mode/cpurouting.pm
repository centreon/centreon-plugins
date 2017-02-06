#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package network::juniper::common::junos::mode::cpurouting;

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
    $self->{snmp} = $options{snmp};
    
    my $oid_jnxOperatingDescr = '.1.3.6.1.4.1.2636.3.1.13.1.5';
    my $oid_jnxOperatingCPU = '.1.3.6.1.4.1.2636.3.1.13.1.8';
    my $oid_jnxOperating1MinLoadAvg = '.1.3.6.1.4.1.2636.3.1.13.1.20';
    my $oid_jnxOperating5MinLoadAvg = '.1.3.6.1.4.1.2636.3.1.13.1.21';
    my $oid_jnxOperating15MinLoadAvg = '.1.3.6.1.4.1.2636.3.1.13.1.22';
    
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
                                    short_msg => sprintf("All CPU(s) average usages are ok"));
    }
    
    $self->{snmp}->load(oids => [$oid_jnxOperatingCPU, $oid_jnxOperating1MinLoadAvg, $oid_jnxOperating5MinLoadAvg, $oid_jnxOperating15MinLoadAvg],
                        instances => \@oids_routing_engine,
                        instance_regexp => "^" . $oid_jnxOperatingDescr . '\.(.+)');
    my $result2 = $self->{snmp}->get_leef();
    
    foreach my $oid_routing_engine (@oids_routing_engine) {
        $oid_routing_engine =~ /^$oid_jnxOperatingDescr\.(.+)/;
        my $instance = $1;
        my $description = $result->{$oid_jnxOperatingDescr . '.' . $instance};
        my $cpu_usage = $result2->{$oid_jnxOperatingCPU . '.' . $instance};
        my $cpu_load1 = $result2->{$oid_jnxOperating1MinLoadAvg . '.' . $instance};
        my $cpu_load5 = $result2->{$oid_jnxOperating5MinLoadAvg . '.' . $instance};
        my $cpu_load15 = $result2->{$oid_jnxOperating15MinLoadAvg . '.' . $instance};
        
        my $exit_code = $self->{perfdata}->threshold_check(value => $cpu_usage, 
                                   threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{output}->output_add(long_msg => sprintf("CPU(s) '%s' average usage is: %s%%", $description, $cpu_usage));
        if ($multiple == 0 || !$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("CPU(s) '%s' average usage is: %s%%", $description, $cpu_usage));
        }
        my $extra_label = '';
        $extra_label = '_' . $description if ($multiple == 1);
        $self->{output}->perfdata_add(label => 'cpu' . $extra_label, unit => '%',
                                      value => $cpu_usage,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0, max => 100);
        $self->{output}->perfdata_add(label => 'load1' . $extra_label,
                                      value => $cpu_load1,
                                      min => 0);
        $self->{output}->perfdata_add(label => 'load5' . $extra_label,
                                      value => $cpu_load5,
                                      min => 0);
        $self->{output}->perfdata_add(label => 'load15' . $extra_label,
                                      value => $cpu_load15,
                                      min => 0);
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check CPU Usage of routing engine.

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
