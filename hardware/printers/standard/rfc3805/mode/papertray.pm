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

package hardware::printers::standard::rfc3805::mode::papertray;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

my %unit_managed = (
    8 => 1,     # sheets(8)
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"       => { name => 'warning' },
                                  "critical:s"      => { name => 'critical' },
                                  "filter-tray:s"   => { name => 'filter_tray' },
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
    
    my $oid_prtInputCurrentLevel = '.1.3.6.1.2.1.43.8.2.1.10';
    my $oid_prtInputMaxCapacity = '.1.3.6.1.2.1.43.8.2.1.9';
    my $oid_prtInputCapacityUnit = '.1.3.6.1.2.1.43.8.2.1.8';
    my $oid_prtInputDescription = '.1.3.6.1.2.1.43.8.2.1.18';
    my $result = $self->{snmp}->get_table(oid => $oid_prtInputCurrentLevel, nothing_quit => 1);
    
    $self->{snmp}->load(oids => [$oid_prtInputMaxCapacity, $oid_prtInputCapacityUnit,
                                 $oid_prtInputDescription],
                        instances => [keys %$result], instance_regexp => '(\d+\.\d+)$');
    
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "Paper tray usages are ok.");
    
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+).(\d+)$/;
        my ($hrDeviceIndex, $prtInputIndex) = ($1, $2);
        my $instance = $hrDeviceIndex . '.' . $prtInputIndex;
        my $unit = $result2->{$oid_prtInputCapacityUnit . '.' . $instance};
        my $descr = centreon::plugins::misc::trim($result2->{$oid_prtInputDescription . '.' . $instance});
        my $current_value = $result->{$key};
        my $max_value = $result2->{$oid_prtInputMaxCapacity . '.' . $instance};
        
        if (!defined($descr) || $descr eq '') {
            $descr = $hrDeviceIndex . '#' . $prtInputIndex;
        }
        
        if (defined($self->{option_results}->{filter_tray}) && $self->{option_results}->{filter_tray} ne '' &&
            $descr !~ /$self->{option_results}->{filter_tray}/) {
            $self->{output}->output_add(long_msg => "Skipping tray '$descr': not matching filter."); 
            next;
        }

        if (!defined($unit_managed{$unit})) {
            $self->{output}->output_add(long_msg => "Skipping input '$descr': unit not managed."); 
            next;
        }
        if ($current_value == -1) {
            $self->{output}->output_add(long_msg => "Skipping tray '$descr': no level."); 
            next;
        } elsif ($current_value == -2) {
            $self->{output}->output_add(long_msg => "Skippinp tray '$descr': level unknown."); 
            next;
        } elsif ($current_value == -3) {
            $self->{output}->output_add(long_msg => "Tray '$descr': no level but some space remaining."); 
            next;
        }
        
        my $prct_value = $current_value * 100 / $max_value;
        
        my $exit = $self->{perfdata}->threshold_check(value => $prct_value, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);        
        $self->{output}->output_add(long_msg => sprintf("Paper tray '%s': %.2f %%", $descr, $prct_value));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Paper tray '%s': %.2f %%", $descr, $prct_value));
        }
        
        my $label = 'tray_' . $descr;
        
        $self->{output}->perfdata_add(label => $label, unit => '%',
                                      value => sprintf("%.2f", $prct_value),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0, max => 100);
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check paper trays usages.

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=item B<--filter-tray>

Filter tray to check (can use a regexp).

=back

=cut
