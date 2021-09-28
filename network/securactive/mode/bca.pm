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

package network::securactive::mode::bca;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_spvBCAName = '.1.3.6.1.4.1.36773.3.2.1.1.1.1';
my $oid_spvBCAStatus = '.1.3.6.1.4.1.36773.3.2.1.1.1.2';
my $oid_spvBCAEURT = '.1.3.6.1.4.1.36773.3.2.1.1.1.3';
my $oid_spvBCASRT = '.1.3.6.1.4.1.36773.3.2.1.1.1.4';
my $oid_spvBCARTTClient = '.1.3.6.1.4.1.36773.3.2.1.1.1.7';
my $oid_spvBCARTTServer = '.1.3.6.1.4.1.36773.3.2.1.1.1.8';
my $oid_spvBCADTTClient = '.1.3.6.1.4.1.36773.3.2.1.1.1.9';
my $oid_spvBCADTTServer = '.1.3.6.1.4.1.36773.3.2.1.1.1.10';
my $oid_spvBCAThresholdWarning = '.1.3.6.1.4.1.36773.3.2.1.1.1.16';
my $oid_spvBCAThresholdAlert = '.1.3.6.1.4.1.36773.3.2.1.1.1.17';

my %bca_status = (
    1 => ['ok', 'OK'], 
    2 => ['warning', 'WARNING'], 
    3 => ['alert', 'WARNING'], 
    4 => ['not available', 'UNKNOWN'],
    5 => ['not data at all', 'UNKNOWN'],
    6 => ['not enough samples for computation', 'UNKNOWN'],
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"             => { name => 'warning' },
                                  "critical:s"            => { name => 'critical' },
                                  "name:s"                => { name => 'name' },
                                  "regexp"                => { name => 'use_regexp' },
                                });
    $self->{bca_id_selected} = [];

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

sub manage_selection {
    my ($self, %options) = @_;

    $self->{result_names} = $self->{snmp}->get_table(oid => $oid_spvBCAName, nothing_quit => 1);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{result_names}})) {
        next if ($oid !~ /\.([0-9]+)$/);
        my $instance = $1;
        
        # Get all without a name
        if (!defined($self->{option_results}->{name})) {
            push @{$self->{bca_id_selected}}, $instance; 
            next;
        }
        
        $self->{result_names}->{$oid} = $self->{output}->decode($self->{result_names}->{$oid});
        if (!defined($self->{option_results}->{use_regexp}) && $self->{result_names}->{$oid} eq $self->{option_results}->{name}) {
            push @{$self->{bca_id_selected}}, $instance; 
        }
        if (defined($self->{option_results}->{use_regexp}) && $self->{result_names}->{$oid} =~ /$self->{option_results}->{name}/) {
            push @{$self->{bca_id_selected}}, $instance;
        }
    }

    if (scalar(@{$self->{bca_id_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No bca found for name '" . $self->{option_results}->{name} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    $self->manage_selection();
    $self->{snmp}->load(
        oids => [
            $oid_spvBCAStatus, $oid_spvBCAEURT, $oid_spvBCASRT, 
            $oid_spvBCARTTClient, $oid_spvBCARTTServer,
            $oid_spvBCADTTClient, $oid_spvBCADTTServer,
            $oid_spvBCAThresholdWarning, $oid_spvBCAThresholdAlert
        ],
        instances => $self->{bca_id_selected}
    );
    my $result = $self->{snmp}->get_leef();
    
    if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All BCA are ok.');
    }
    
    foreach my $instance (sort @{$self->{bca_id_selected}}) {
        my $name = $self->{result_names}->{$oid_spvBCAName . '.' . $instance};
        my $status = $result->{$oid_spvBCAStatus . '.' . $instance};
        my $eurt = $result->{$oid_spvBCAEURT . '.' . $instance};
        my $warnth = defined($self->{option_results}->{warning}) ? $self->{option_results}->{warning} : $result->{$oid_spvBCAThresholdWarning . '.' . $instance};
        my $critth = defined($self->{option_results}->{critical}) ? $self->{option_results}->{critical} : $result->{$oid_spvBCAThresholdAlert . '.' . $instance};
        
        my $exit_from_snmp = ${$bca_status{$status}}[1];
        my $exit_from_threshold = $self->{perfdata}->threshold_check(value => $eurt, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        
        $self->{output}->output_add(long_msg => sprintf("BCA '%s' status is '%s'", 
                                                        $name, ${$bca_status{$status}}[0]));
        if (!$self->{output}->is_status(value => $exit_from_snmp, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit_from_snmp,
                                        short_msg => sprintf("BCA '%s' status is '%s'", $name, ${$bca_status{$status}}[0]));
        }
        if (!$self->{output}->is_status(value => $exit_from_threshold, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit_from_threshold,
                                        short_msg => sprintf("BCA '%s' EURT exceed option threshold", $name));
        }
        
        my $extra_label = '';
        $extra_label = '_' . $name if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp}));
        $self->{output}->perfdata_add(label => 'eurt' . $extra_label,
                                      value => $eurt,
                                      warning => $warnth,
                                      critical => $critth,
                                      min => 0);
        $self->{output}->perfdata_add(label => 'srt' . $extra_label,
                                      value => $result->{$oid_spvBCASRT . '.' . $instance},
                                      min => 0);
        $self->{output}->perfdata_add(label => 'rttclient' . $extra_label,
                                      value => $result->{$oid_spvBCARTTClient . '.' . $instance},
                                      min => 0);
        $self->{output}->perfdata_add(label => 'rttserver' . $extra_label,
                                      value => $result->{$oid_spvBCARTTServer . '.' . $instance},
                                      min => 0);
        $self->{output}->perfdata_add(label => 'dttclient' . $extra_label,
                                      value => $result->{$oid_spvBCADTTClient . '.' . $instance},
                                      min => 0);
        $self->{output}->perfdata_add(label => 'dttserver' . $extra_label,
                                      value => $result->{$oid_spvBCADTTServer . '.' . $instance},
                                      min => 0);
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check BCA status.

=over 8

=item B<--warning>

Threshold warning on EURT (End User Response Time).
Permits to add another threshold than snmp.

=item B<--critical>

Threshold critical on EURT (End User Response Time).
Permits to add another threshold than snmp.

=item B<--name>

Set the filesystem name.

=item B<--regexp>

Allows to use regexp to filter filesystem name (with option --name).

=back

=cut
    
