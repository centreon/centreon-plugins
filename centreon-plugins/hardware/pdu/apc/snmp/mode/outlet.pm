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

package hardware::pdu::apc::snmp::mode::outlet;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

my $thresholds = {
    outlet => [
        ['outletStatusOn', 'OK'],
        ['outletStatusOff', 'CRITICAL'],
    ],
};
my %map_status = (
    1 => 'outletStatusOn',
    2 => 'outletStatusOff',
);
my %map_phase = (
    1 => 'phase1',
    2 => 'phase2',
    3 => 'phase3',
    4 => 'phase1-2',
    5 => 'phase2-3',
    6 => 'phase3-1',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "filter:s@"               => { name => 'filter' },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                  "warning:s@"              => { name => 'warning' },
                                  "critical:s@"             => { name => 'critical' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    $self->{filter} = [];
    foreach my $val (@{$self->{option_results}->{filter}}) {
        next if (!defined($val) || $val eq '');
        my @values = split (/,/, $val);
        push @{$self->{filter}}, { filter => $values[0], instance => $values[1] }; 
    }
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        next if (!defined($val) || $val eq '');
        my @values = split (/,/, $val);
        if (scalar(@values) < 3) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $instance, $status, $filter);
        if (scalar(@values) == 3) {
            ($section, $status, $filter) = @values;
            $instance = '.*';
        } else {
             ($section, $instance, $status, $filter) = @values;
        }
        if ($section !~ /^outlet$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload section '" . $val . "'.");
            $self->{output}->option_exit();
        }
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status, instance => $instance };
    }
    
    $self->{numeric_threshold} = {};
    foreach my $option (('warning', 'critical')) {
        foreach my $val (@{$self->{option_results}->{$option}}) {
            next if (!defined($val) || $val eq '');
            if ($val !~ /^(.*?),(.*?),(.*)$/) {
                $self->{output}->add_option_msg(short_msg => "Wrong $option option '" . $val . "'.");
                $self->{output}->option_exit();
            }
            my ($section, $instance, $value) = ($1, $2, $3);
            if ($section !~ /^load$/) {
                $self->{output}->add_option_msg(short_msg => "Wrong $option option '" . $val . "'.");
                $self->{output}->option_exit();
            }
            my $position = 0;
            if (defined($self->{numeric_threshold}->{$section})) {
                $position = scalar(@{$self->{numeric_threshold}->{$section}});
            }
            if (($self->{perfdata}->threshold_validate(label => $option . '-' . $section . '-' . $position, value => $value)) == 0) {
                $self->{output}->add_option_msg(short_msg => "Wrong $option threshold '" . $value . "'.");
                $self->{output}->option_exit();
            }
            $self->{numeric_threshold}->{$section} = [] if (!defined($self->{numeric_threshold}->{$section}));
            push @{$self->{numeric_threshold}->{$section}}, { label => $option . '-' . $section . '-' . $position, threshold => $option, instance => $instance };
        }
    }
}

my $mapping = {
    rPDUOutletStatusOutletName => { oid => '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.2' },
    rPDUOutletStatusOutletPhase => { oid => '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.3', map => \%map_phase },
    rPDUOutletStatusOutletState => { oid => '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.4', map => \%map_status },
    rPDUOutletStatusOutletBank => { oid => '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.6' },
    rPDUOutletStatusLoad => { oid => '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.7' },
};

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_rPDUOutletStatusEntry = '.1.3.6.1.4.1.318.1.1.12.3.5.1.1';

    $self->{results} = $self->{snmp}->get_table(oid => $oid_rPDUOutletStatusEntry, nothing_quit => 1);
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All outlets are ok');
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}})) {
        next if ($oid !~ /^$mapping->{rPDUOutletStatusOutletState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);
        
        next if ($self->check_filter(section => 'outlet', instance => $instance));

        $self->{output}->output_add(long_msg => sprintf("Outlet '%s' state is '%s' [instance: %s, bank : %s, phase : %s, load: %s]", 
                                    $result->{rPDUOutletStatusOutletName}, $result->{rPDUOutletStatusOutletState}, 
                                    $instance, $result->{rPDUOutletStatusOutletBank}, $result->{rPDUOutletStatusOutletPhase}, $result->{rPDUOutletStatusLoad}));
        my $exit = $self->get_severity(section => 'outlet', instance => $instance, value => $result->{rPDUOutletStatusOutletState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Outlet '%s' state is '%s' [bank : %s, phase : %s]", 
                                                             $result->{rPDUOutletStatusOutletName}, $result->{rPDUOutletStatusOutletState},
                                                             $result->{rPDUOutletStatusOutletBank}, $result->{rPDUOutletStatusOutletPhase}));
        }
        
        if (defined($result->{rPDUOutletStatusLoad}) && $result->{rPDUOutletStatusLoad} =~ /[0-9]/ && $result->{rPDUOutletStatusLoad} != 0) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'load', instance => $instance, value => $result->{rPDUOutletStatusLoad});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Outlet '%s' load is %s A [bank : %s, phase : %s]", 
                                                                 $result->{rPDUOutletStatusOutletName}, $result->{rPDUOutletStatusLoad}, 
                                                                 $result->{rPDUOutletStatusOutletBank}, $result->{rPDUOutletStatusOutletPhase}));
            }
            $self->{output}->perfdata_add(label => 'load_' . $result->{rPDUOutletStatusOutletName} . '_bank_' . $result->{rPDUOutletStatusOutletBank} . '_' . $result->{rPDUOutletStatusOutletPhase} . '_' . $instance, 
                                          unit => 'A',
                                          value => $result->{rPDUOutletStatusLoad},
                                          warning => $warn,
                                          critical => $crit,
                                          min => 0);
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub check_filter {
    my ($self, %options) = @_;

    foreach (@{$self->{filter}}) {
        if ($options{section} =~ /$_->{filter}/) {
            if (!defined($options{instance}) && !defined($_->{instance})) {
                $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section."));
                return 1;
            } elsif (defined($options{instance}) && $options{instance} =~ /$_->{instance}/) {
                $self->{components}->{$options{section}}->{skip}++ if (defined($self->{components}->{$options{section}}));
                $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section $options{instance} instance."));
                return 1;
            }
        }
    }
    
    return 0;
}

sub get_severity_numeric {
    my ($self, %options) = @_;
    my $status = 'OK'; # default
    my $thresholds = { warning => undef, critical => undef };
    my $checked = 0;
    
    if (defined($self->{numeric_threshold}->{$options{section}})) {
        my $exits = [];
        foreach (@{$self->{numeric_threshold}->{$options{section}}}) {
            if ($options{instance} =~ /$_->{instance}/) {
                push @{$exits}, $self->{perfdata}->threshold_check(value => $options{value}, threshold => [ { label => $_->{label}, exit_litteral => $_->{threshold} } ]);
                $thresholds->{$_->{threshold}} = $self->{perfdata}->get_perfdata_for_output(label => $_->{label});
                $checked = 1;
            }
        }
        $status = $self->{output}->get_most_critical(status => $exits) if (scalar(@{$exits}) > 0);
    }
    
    return ($status, $thresholds->{warning}, $thresholds->{critical}, $checked);
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i && 
                (!defined($options{instance}) || $options{instance} =~ /$_->{instance}/)) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    my $label = defined($options{label}) ? $options{label} : $options{section};
    foreach (@{$thresholds->{$label}}) {
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

1;

__END__

=head1 MODE

Check outlet state.

=over 8

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter=outlet,1

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='outlet,WARNING,^(?!(outletStatusOn)$)'

=item B<--warning>

Set warning threshold for temperatures (syntax: type,instance,threshold)
Example: --warning='load,.*,30'

=item B<--critical>

Set critical threshold for temperatures (syntax: type,instance,threshold)
Example: --critical='load,.*,40'
=back

=cut