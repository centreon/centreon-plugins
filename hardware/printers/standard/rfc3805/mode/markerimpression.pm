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

package hardware::printers::standard::rfc3805::mode::markerimpression;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;

my %unit_managed = (
    7 => 'impressions',
    8 => 'sheets',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"   => { name => 'warning' },
                                  "critical:s"  => { name => 'critical' },
                                });
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
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
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();
    
    my $new_datas = {};
    $new_datas->{last_timestamp} = time();
    $self->{statefile_value}->read(statefile => "snmpstandard_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    
    my $oid_prtMarkerCounterUnit = '.1.3.6.1.2.1.43.10.2.1.3';
    my $oid_prtMarkerLifeCount = '.1.3.6.1.2.1.43.10.2.1.4';
    my $result = $self->{snmp}->get_table(oid => $oid_prtMarkerLifeCount, nothing_quit => 1);
    
    $self->{snmp}->load(oids => [$oid_prtMarkerCounterUnit],
                        instances => [keys %$result], instance_regexp => '(\d+\.\d+)$');
    
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "Marker impressions/sheets are ok.");
    
    my $perf_label = {};
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+).(\d+)$/;
        my ($hrDeviceIndex, $prtMarkerIndex) = ($1, $2);
        my $instance = $hrDeviceIndex . '.' . $prtMarkerIndex;
        my $counter_unit = $result2->{$oid_prtMarkerCounterUnit . '.' . $instance};
        $new_datas->{'lifecount_' . $instance} = $result->{$key};
        
        if (!defined($unit_managed{$counter_unit})) {
            $self->{output}->output_add(long_msg => "Skipping marker '" . $hrDeviceIndex . '#' . $prtMarkerIndex . "': unit not managed."); 
            next;
        }
        
        my $old_life_count = $self->{statefile_value}->get(name => 'lifecount_' . $instance);
        if (!defined($old_timestamp) || !defined($old_life_count)) {
            next;
        }
        
        if ($old_life_count > $new_datas->{'lifecount_' . $instance}) {
            $old_life_count = 0;
        }
        my $value = $new_datas->{'lifecount_' . $instance} - $old_life_count;
        
        my $exit = $self->{perfdata}->threshold_check(value => $value, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);        
        $self->{output}->output_add(long_msg => sprintf("Marker %s '%s': %s", $unit_managed{$counter_unit}, $hrDeviceIndex . '#' . $prtMarkerIndex, $value));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Marker %s '%s': %s", $unit_managed{$counter_unit}, $hrDeviceIndex . '#' . $prtMarkerIndex, $value));
        }
        
        my $label = $unit_managed{$counter_unit};
        if (defined($perf_label->{$label})) {
            $label .= '#' . $hrDeviceIndex . '#' . $prtMarkerIndex;
        }
        $perf_label->{$label} = 1;
        
        $self->{output}->perfdata_add(label => $label,
                                      value => $value,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
    }
    
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

Check marker impressions/sheets.

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=back

=cut
