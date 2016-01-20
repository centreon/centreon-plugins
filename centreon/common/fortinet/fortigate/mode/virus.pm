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

package centreon::common::fortinet::fortigate::mode::virus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my $oid_fgVdEntName = '.1.3.6.1.4.1.12356.101.3.2.1.1.2';
my $oid_fgAvVirusDetected = '.1.3.6.1.4.1.12356.101.8.2.1.1.1';
my $oid_fgAvVirusBlocked = '.1.3.6.1.4.1.12356.101.8.2.1.1.2';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning-virus-detected:s"    => { name => 'warning_virus_detected' },
                                  "critical-virus-detected:s"   => { name => 'critical_virus_detected' },
                                  "warning-virus-blocked:s"     => { name => 'warning_virus_blocked' },
                                  "critical-virus-blocked:s"    => { name => 'critical_virus_blocked' },
                                  "name:s"                      => { name => 'name' },
                                  "regexp"                      => { name => 'use_regexp' },
                                });
    $self->{virtualdomain_id_selected} = [];
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (($self->{perfdata}->threshold_validate(label => 'warning-virus-detected', value => $self->{option_results}->{warning_virus_detected})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning 'virus-detected' threshold '" . $self->{option_results}->{warning_virus_detected} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-virus-detected', value => $self->{option_results}->{critical_virus_detected})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical 'virus-detected' threshold '" . $self->{option_results}->{critical_virus_detected} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-virus-blocked', value => $self->{option_results}->{warning_virus_blocked})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning 'virus-blocked' threshold '" . $self->{option_results}->{warning_virus_blocked} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-virus-blocked', value => $self->{option_results}->{critical_virus_blocked})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical 'virus-blocked' threshold '" . $self->{option_results}->{critical_virus_blocked} . "'.");
        $self->{output}->option_exit();
    }
    $self->{statefile_value}->check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{result_names} = $self->{snmp}->get_table(oid => $oid_fgVdEntName, nothing_quit => 1);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{result_names}})) {
        next if ($oid !~ /\.([0-9]+)$/);
        my $instance = $1;
        
        # Get all without a name
        if (!defined($self->{option_results}->{name})) {
            push @{$self->{virtualdomain_id_selected}}, $instance; 
            next;
        }
        
        if (!defined($self->{option_results}->{use_regexp}) && $self->{result_names}->{$oid} eq $self->{option_results}->{name}) {
            push @{$self->{virtualdomain_id_selected}}, $instance; 
        }
        if (defined($self->{option_results}->{use_regexp}) && $self->{result_names}->{$oid} =~ /$self->{option_results}->{name}/) {
            push @{$self->{virtualdomain_id_selected}}, $instance;
        }
    }

    if (scalar(@{$self->{virtualdomain_id_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No virtualdomains found for name '" . $self->{option_results}->{name} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    $self->manage_selection();
    $self->{snmp}->load(oids => [$oid_fgAvVirusDetected, $oid_fgAvVirusBlocked], instances => $self->{virtualdomain_id_selected});
    my $result = $self->{snmp}->get_leef();
    
    my $new_datas = {};
    $self->{statefile_value}->read(statefile => "cache_fortigate_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode} . '_' . (defined($self->{option_results}->{name}) ? md5_hex($self->{option_results}->{name}) : md5_hex('all')));
    $new_datas->{last_timestamp} = time();
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    
    if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All virtualdomains virus stats are ok.');
    }
    
    foreach my $instance (sort @{$self->{virtualdomain_id_selected}}) {
        my $name = $self->{result_names}->{$oid_fgVdEntName . '.' . $instance};
        my $virus_blocked = $result->{$oid_fgAvVirusBlocked . '.' . $instance};
        my $virus_detected = $result->{$oid_fgAvVirusDetected . '.' . $instance};
        
        $new_datas->{'virus_blocked_' . $instance} = $virus_blocked;
        $new_datas->{'virus_detected_' . $instance} = $virus_detected;
        
        my $old_virus_detected = $self->{statefile_value}->get(name => 'virus_detected_' . $instance);
        my $old_virus_blocked = $self->{statefile_value}->get(name => 'virus_blocked_' . $instance);
        if (!defined($old_timestamp) || !defined($old_virus_detected) || !defined($old_virus_blocked)) {
            next;
        }
        if ($new_datas->{'virus_blocked_' . $instance} < $old_virus_blocked) {
            # We set 0. Has reboot.
            $old_virus_blocked = 0;
        }
        if ($new_datas->{'virus_detected_' . $instance} < $old_virus_detected) {
            # We set 0. Has reboot.
            $old_virus_detected = 0;
        }
        
        my $time_delta = $new_datas->{last_timestamp} - $old_timestamp;
        if ($time_delta <= 0) {
            # At least one second. two fast calls ;)
            $time_delta = 1;
        }

        my $virus_detected_per_sec = ($new_datas->{'virus_detected_' . $instance} - $virus_detected) / $time_delta;
        my $virus_blocked_per_sec = ($new_datas->{'virus_blocked_' . $instance} - $virus_blocked) / $time_delta;
        my $total_virus_blocked = $new_datas->{'virus_blocked_' . $instance} - $virus_blocked;
        my $total_virus_detected = $new_datas->{'virus_detected_' . $instance} - $virus_detected;
       
        ###########
        # Manage Output
        ###########
        my $exit1 = $self->{perfdata}->threshold_check(value => $total_virus_detected, threshold => [ { label => 'critical-virus-detected', 'exit_litteral' => 'critical' }, { label => 'warning-virus-detected', exit_litteral => 'warning' } ]);
        my $exit2 = $self->{perfdata}->threshold_check(value => $total_virus_blocked, threshold => [ { label => 'critical-virus-blocked', 'exit_litteral' => 'critical' }, { label => 'warning-virus-blocked', exit_litteral => 'warning' } ]);

        my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
        $self->{output}->output_add(long_msg => sprintf("Virtualdomain '%s' Virus Blocked : %.2f/s (%d), Detected : %.2f/s (%d) ",
                                                        $name, $virus_blocked_per_sec, $total_virus_blocked,
                                                        $virus_detected_per_sec, $total_virus_detected));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Virtualdomain '%s' Virus Blocked : %.2f/s (%d), Detected : %.2f/s (%d) ",
                                                        $name, $virus_blocked_per_sec, $total_virus_blocked,
                                                        $virus_detected_per_sec, $total_virus_detected));
        }

        my $extra_label = '';
        $extra_label = '_' . $name if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp}));
        $self->{output}->perfdata_add(label => 'virus_blocked' . $extra_label,
                                      value => $total_virus_blocked,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-virus-blocked'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-virus-blocked'),
                                      min => 0);
        $self->{output}->perfdata_add(label => 'virus_detected' . $extra_label,
                                      value => $total_virus_detected,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-virus-detected'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-virus-detected'),
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

Check virus blocked and detected.

=over 8

=item B<--warning-virus-detected>

Threshold warning of total virus detected.

=item B<--critical-virus-detected>

Threshold critical of total virus detected.

=item B<--warning-virus-blocked>

Threshold warning of total virus blocked.

=item B<--critical-virus-blocked>

Threshold critical of total virus blocked.

=item B<--name>

Set the virtualdomains name.

=item B<--regexp>

Allows to use regexp to filter virtualdomains name (with option --name).

=back

=cut
    