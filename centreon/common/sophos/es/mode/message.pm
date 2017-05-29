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

package centreon::common::sophos::es::mode::message;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                # option name        => variable name
                                "warning:s"          => { name => 'warning', },
                                "critical:s"         => { name => 'critical', },
                                });


    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

  # Validate threshold options with threshold_validate method
  if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
     $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
     $self->{output}->option_exit();
  }
  if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
     $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
     $self->{output}->option_exit();
  }

  # Validate cache file options using check_options method of statefile library
  $self->{statefile_value}->check_options(%options);

}


sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};


# Get SNMP options
  $self->{snmp} = $options{snmp};
  $self->{hostname} = $self->{snmp}->get_hostname();
  $self->{snmp_port} = $self->{snmp}->get_port();


   my $oids = '.1.3.6.1.4.1.2604.1.1.1.4';
   $self->{result_names} = $self->{snmp}->get_table(oid => $oids,nothing_quit => 1);



#use Data::Dumper;
#print Dumper($self->{result_names});


my $oid_legit_in = $oids.".1.3.1";
my $oid_legit_out = $oids.".1.4.1";
my $legit_in = $self->{result_names}->{$oid_legit_in};
my $legit_out = $self->{result_names}->{$oid_legit_out};




# Read the cache file
  $self->{statefile_value}->read(statefile => 'es_' . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
  # Get cache file values
  my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
  my $old_legit_in = $self->{statefile_value}->get(name => 'legit_in');
  my $old_legit_out = $self->{statefile_value}->get(name => 'legit_out');

  # Create a hash table with new values that will be write to cache file
  my $new_datas = {};
  $new_datas->{last_timestamp} = time();
  $new_datas->{legit_in} = $legit_in;
  $new_datas->{legit_out} = $legit_out;

  # Write new values to cache file
  $self->{statefile_value}->write(data => $new_datas);

  # If cache file didn't have any values, create it and wait another check to calculate value
  if (!defined($old_timestamp) || !defined($old_legit_in)) {
      $self->{output}->output_add(severity => 'OK',
                                  short_msg => "Buffer creation...");
      $self->{output}->display();
      $self->{output}->exit();
  }

  # Fix when reboot (snmp counters initialize to 0)
  $old_legit_in = 0 if ($old_legit_in > $new_datas->{legit_in});
  $old_legit_out = 0 if ($old_legit_out > $new_datas->{legit_out});

  # Calculate time between 2 checks
  my $delta_time = $new_datas->{last_timestamp} - $old_timestamp;
  $delta_time = 1 if ($delta_time == 0);

  # Calculate value per second
  $legit_in = ($new_datas->{legit_in} - $old_legit_in) / $delta_time;
  $legit_out = ($new_datas->{legit_out} - $old_legit_out) / $delta_time;


    my $exit_code = $self->{perfdata}->threshold_check(value =>  $legit_in,
                                                     threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);


    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("IN: %.2f msg/s OUT: %.2f msg/s ", $legit_in, $legit_out));


    $self->{output}->perfdata_add(label => 'in', unit => 'msg/sec',
                                  value => sprintf("%.2f",  $legit_in),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    $self->{output}->perfdata_add(label => 'out', unit => 'msg/sec',
                                  value => sprintf("%.2f",  $legit_out),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);


    $self->{statefile_value}->write(data => $new_datas);
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
    }



    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check message par second.

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.


=back

=cut
