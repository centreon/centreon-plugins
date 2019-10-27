#
# Copyright 2019 Centreon (http://www.centreon.com/)
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
# Authors : Pedro Manuel Santos Delgado pedromanuelsant@yahoo.com

package network::cisco::catalyst::snmp::mode::cpu_load;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use Data::Dumper;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });
    $self->{version} = '0.1';
    return $self;
}

sub set_counters {
  my ($self, %options) = @_;

  $self->{maps_counters_type} = [
      { name => 'switch', type => 1, cb_prefix_output => 'prefix_switch_output', message_multiple => 'All Switches are ok' }
  ];

  $self->{maps_counters}->{switch} = [
      { label => 'load_1m',
      	set => {
                   key_values => [ { name => 'load_1m' }, { name => 'display' } ],
                   output_template => 'cpu load 1m: %s',
                   perfdatas => [
                      { label => 'load1m',
                      	value => 'load_1m_absolute',
                      	template => '%s',
                      	min => 0,
                      	label_extra_instance => 1,
                      	instance_use => 'display_absolute',
                      },
                   ],
               }
      },

      { label => 'load_5m', set => {
              key_values => [ { name => 'load_5m' }, { name => 'display' } ],
              output_template => 'cpu load 5m: %s',
              perfdatas => [
                  { label => 'load5m', value => 'load_5m_absolute', template => '%s',
                    min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
              ],
          }
      },
      { label => 'load_15m', set => {
              key_values => [ { name => 'load_15m' }, { name => 'display' } ],
              output_template => 'cpu load 15m: %s',
              perfdatas => [
                  { label => 'load15m', value => 'load_15m_absolute', template => '%s',
                    min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
              ],
          }
      },
  ];
}

sub prefix_switch_output {
  my ($self, %options) = @_;
  return $options{instance_value}->{display} . ' ';

}

sub manage_selection {
  my ($self, %options) = @_;

  my $ciscocata_names=".1.3.6.1.2.1.47.1.1.1.1.2"; #model of the physical devices, use same number from previous
  my $cpmCPUTotalEntry = '.1.3.6.1.4.1.9.9.109.1.1.1.1';
  my $mapping = {
  	  switch     => { oid => '.1.3.6.1.4.1.9.9.109.1.1.1.1.2'  },
      load1m     => { oid => '.1.3.6.1.4.1.9.9.109.1.1.1.1.24' },
      load5m     => { oid => '.1.3.6.1.4.1.9.9.109.1.1.1.1.25' },
      load15m    => { oid => '.1.3.6.1.4.1.9.9.109.1.1.1.1.26' },
  };

  $self->{switch} = {};
  my $result = $options{snmp}->get_table(oid => $cpmCPUTotalEntry, nothing_quit => 1);
  foreach my $oid (keys %$result) {
      next if ($oid !~ /^$mapping->{switch}->{oid}\.(\d+)$/);
      my $instance = $1;
      my $data = $options{snmp}->map_instance(mapping => $mapping, results => $result, instance => $instance);
      my $instance_label=$options{snmp}-> get_leef(oids => [$ciscocata_names . '.' . $data->{switch}]);
      $self->{switch}->{$instance} = {
      	  display => $$instance_label{$ciscocata_names . '.' . $data->{switch}} . "_" . $instance,
          load_1m => $data->{load1m},
          load_5m => $data->{load5m},
          load_15m => $data->{load15m},
      };
  }

}





1;

__END__

=head1 MODE

Reports CPU Load for  Cisco Catalyst (Catalyst L3 Switch Software (CAT9K_IOSXE), Version 16.6.4).

=over 8

=item B<--warning-*>

Threshold warning (load_1m,load_5min,load_15min).

=item B<--critical-*>

Threshold critical (load_1m,load_5min,load_15min).

=back

=cut
