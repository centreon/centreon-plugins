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

package storage::netapp::snmp::mode::snapmirrorlag;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_snapmirrorOn = '.1.3.6.1.4.1.789.1.9.1.0';
my $oid_snapmirrorSrc = '.1.3.6.1.4.1.789.1.9.20.1.2';
my $oid_snapmirrorLag = '.1.3.6.1.4.1.789.1.9.20.1.6'; # hundreth of seconds

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"             => { name => 'warning' },
                                  "critical:s"            => { name => 'critical' },
                                  "name:s"                => { name => 'name' },
                                  "regexp"                => { name => 'use_regexp' },
                                });
    $self->{snapmirrors_id_selected} = [];

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

    my $result = $self->{snmp}->get_leef(oids => [$oid_snapmirrorOn]);
    if (!defined($result->{$oid_snapmirrorOn}) || $result->{$oid_snapmirrorOn} != 2) {
        $self->{output}->add_option_msg(short_msg => "Snapmirror is not turned on.");
        $self->{output}->option_exit();
    }
    
    $self->{result_names} = $self->{snmp}->get_table(oid => $oid_snapmirrorSrc, nothing_quit => 1);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{result_names}})) {
        next if ($oid !~ /\.([0-9]+)$/);
        my $instance = $1;
        
        # Get all without a name
        if (!defined($self->{option_results}->{name})) {
            push @{$self->{snapmirrors_id_selected}}, $instance; 
            next;
        }
        
        if (!defined($self->{option_results}->{use_regexp}) && $self->{result_names}->{$oid} eq $self->{option_results}->{name}) {
            push @{$self->{snapmirrors_id_selected}}, $instance; 
        }
        if (defined($self->{option_results}->{use_regexp}) && $self->{result_names}->{$oid} =~ /$self->{option_results}->{name}/) {
            push @{$self->{snapmirrors_id_selected}}, $instance;
        }
    }

    if (scalar(@{$self->{snapmirrors_id_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No snapmirrors found for name '" . $self->{option_results}->{name} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    $self->{snmp}->load(oids => [$oid_snapmirrorLag], instances => $self->{snapmirrors_id_selected});
    my $result = $self->{snmp}->get_leef(nothing_quit => 1);
    
    if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All snapmirrors lags are ok.');
    }

    foreach my $instance (sort @{$self->{snapmirrors_id_selected}}) {
        my $name = $self->{result_names}->{$oid_snapmirrorSrc . '.' . $instance};
        my $lag = int($result->{$oid_snapmirrorLag . '.' . $instance} / 100);
        
        my $exit = $self->{perfdata}->threshold_check(value => $lag, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        
        $self->{output}->output_add(long_msg => sprintf("Snapmirror '%s' lag: %s secondes", $name, $lag));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Snapmirror '%s' lag: %s secondes", $name, $lag));
        }

        my $extra_label = '';
        $extra_label = '_' . $name if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp}));
        my %total_options = ();
        $self->{output}->perfdata_add(label => 'lag' . $extra_label, unit => 's',
                                      value => $lag,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check snapmirrors lag.

=over 8

=item B<--warning>

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=item B<--name>

Set the snapmirror name.

=item B<--regexp>

Allows to use regexp to filter snampmirror name (with option --name).

=back

=cut
    