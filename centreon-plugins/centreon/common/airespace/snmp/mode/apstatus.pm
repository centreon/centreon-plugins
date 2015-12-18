#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package centreon::common::airespace::snmp::mode::apstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $instance_mode;

my $maps_counters = {
    ap => {
        '000_status' => { threshold => 0, 
            set => {
                key_values => [ { name => 'opstatus' }, { name => 'admstatus' }, { name => 'display' } ],
                threshold => 0,
                closure_custom_calc => \&custom_status_calc,
                closure_custom_output => \&custom_status_output,
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&custom_threshold_output,
            }
        },
    },
    global => {
        '000_total'   => { set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total ap : %s',
                perfdatas => [
                    { label => 'total', value => 'total_absolute', template => '%s', 
                      min => 0 },
                ],
            }
        },
        '001_total-associated'   => { set => {
                key_values => [ { name => 'associated' } ],
                output_template => 'Total ap associated : %s',
                perfdatas => [
                    { label => 'total_associated', value => 'associated_absolute', template => '%s', 
                      min => 0 },
                ],
            }
        },
        '002_total-disassociating'   => { set => {
                key_values => [ { name => 'disassociating' } ],
                output_template => 'Total ap disassociating : %s',
                perfdatas => [
                    { label => 'total_disassociating', value => 'disassociating_absolute', template => '%s', 
                      min => 0 },
                ],
            }
        },
    }
};

sub custom_threshold_output {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg;
    
    if ($self->{result_values}->{admstatus} eq 'disabled') {
        $msg = ' is disabled';
    } else {
        $msg = 'Status : ' . $self->{result_values}->{opstatus};
    }

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{opstatus} = $options{new_datas}->{$self->{instance} . '_opstatus'};
    $self->{result_values}->{admstatus} = $options{new_datas}->{$self->{instance} . '_admstatus'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-name:s"           => { name => 'filter_name' },
                                  "warning-status:s"        => { name => 'warning_status', default => '' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{admstatus} eq "enable" and %{opstatus} !~ /associated|downloading/' },
                                });                         
     
    foreach my $key (('global', 'ap')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                            'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                            'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                      label => $name);
            $maps_counters->{$key}->{$_}->{obj}->set(%{$maps_counters->{$key}->{$_}->{set}});
        }
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach my $key (('global', 'ap')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }

    $instance_mode = $self;
    $self->change_macros();
}

sub run_instance {
    my ($self, %options) = @_;
    
    if ($self->{multiple} == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All AP status are ok');
    }
    
    foreach my $id (sort keys %{$self->{ap_selected}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$maps_counters->{ap}}) {
            my $obj = $maps_counters->{ap}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{ap_selected}->{$id});

            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $obj->output_error();
                $long_msg_append = ', ';
                next;
            }
            my $exit2 = $obj->threshold_check();
            push @exits, $exit2;

            my $output = $obj->output();
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = ', ';
            
            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = ', ';
            }
            
            $obj->perfdata(extra_instance => $self->{multiple});
        }

        $self->{output}->output_add(long_msg => "AP '" . $self->{ap_selected}->{$id}->{display} . "' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "AP '" . $self->{ap_selected}->{$id}->{display} . "' $short_msg"
                                        );
        }
        
        if ($self->{multiple} == 0) {
            $self->{output}->output_add(short_msg => "AP '" . $self->{ap_selected}->{$id}->{display} . "' $long_msg");
        }
    }
}

sub run_global {
    my ($self, %options) = @_;
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters->{global}}) {
        my $obj = $maps_counters->{global}->{$_}->{obj};
                
        $obj->set(instance => 'global');
    
        my ($value_check) = $obj->execute(values => $self->{global});

        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $obj->output_error();
            $long_msg_append = ', ';
            next;
        }
        my $exit2 = $obj->threshold_check();
        push @exits, $exit2;

        my $output = $obj->output();
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = ', ';
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = ', ';
        }
        
        $obj->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "$short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "$long_msg");
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    
    if ($self->{multiple} == 1) {
        $self->run_global();
    }
    
    $self->run_instance();
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

my %map_admin_status = (
    1 => 'enable',
    2 => 'disable',
);
my %map_operation_status = (
    1 => 'associated',
    2 => 'disassociating',
    3 => 'downloading',
);
my $mapping = {
    bsnAPName        => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.3' },
};
my $mapping2 = {
    bsnAPOperationStatus    => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.6', map => \%map_operation_status },
};
my $mapping3 = {
    bsnAPAdminStatus        => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.37', map => \%map_admin_status },
};
my $oid_agentInventoryMachineModel = '.1.3.6.1.4.1.14179.1.1.1.3';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{ap_selected} = {};
    $self->{global} = { total => 0, associated => 0, disassociating => 0, downloading => 0 };
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [ { oid => $oid_agentInventoryMachineModel },
                                                                   { oid => $mapping->{bsnAPName}->{oid} },
                                                                   { oid => $mapping2->{bsnAPOperationStatus}->{oid} },
                                                                   { oid => $mapping3->{bsnAPAdminStatus}->{oid} },
                                                                 ],
                                                         nothing_quit => 1);
    $self->{output}->output_add(long_msg => "Model: " . $self->{results}->{$oid_agentInventoryMachineModel}->{$oid_agentInventoryMachineModel . '.0'});
    foreach my $oid (keys %{$self->{results}->{ $mapping->{bsnAPName}->{oid} }}) {
        $oid =~ /^$mapping->{bsnAPName}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $mapping->{bsnAPName}->{oid} }, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{ $mapping2->{bsnAPOperationStatus}->{oid} }, instance => $instance);
        my $result3 = $self->{snmp}->map_instance(mapping => $mapping3, results => $self->{results}->{ $mapping3->{bsnAPAdminStatus}->{oid} }, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{bsnAPName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{bsnAPName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{global}->{total}++;
        $self->{global}->{$result2->{bsnAPOperationStatus}}++;
        
        $self->{ap_selected}->{$instance} = { display => $result->{bsnAPName}, 
                                              opstatus => $result2->{bsnAPOperationStatus}, admstatus => $result3->{bsnAPAdminStatus}};
    }
    
    if (scalar(keys %{$self->{ap_selected}}) <= 0) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'No AP associated (can be: slave wireless controller or your filter)');
    }
    
    $self->{multiple} = 1;
    if (scalar(keys %{$self->{ap_selected}}) <= 1) {
        $self->{multiple} = 0;
    }
}

1;

__END__

=head1 MODE

Check AP status.

=over 8

=item B<--filter-name>

Filter AP name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admstatus} eq "enable" and %{opstatus} !~ /associated|downloading/').
Can used special variables like: %{admstatus}, %{opstatus}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'total-associated', 'total-disassociating'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'total-associated', 'total-disassociating'.

=back

=cut
