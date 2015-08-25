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

my $maps_counters = {
    '0_status' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                       { name => 'opstatus' }, { name => 'admstatus' },
                                      ],
                        threshold => 0,
                        closure_custom_calc => \&custom_status_calc,
                        closure_custom_output => \&custom_status_output,
                        closure_custom_perfdata => sub { return 0; },
                        closure_custom_threshold_check => \&custom_threshold_output,
                    }
               },
};
my $thresholds = {
    ap => [
        ['associated', 'OK'],
        ['disassociating', 'CRITICAL'],
        ['downloading', 'WARNING'],
    ],
};
my $overload_th;

sub get_severity {
    my (%options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($overload_th->{$options{section}})) {
        foreach (@{$overload_th->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

sub custom_threshold_output {
    my ($self, %options) = @_;
    
    if ($self->{result_values}->{admstatus} eq 'disabled') {
        return 'ok';
    }
    return get_severity(section => 'ap', value => $self->{result_values}->{opstatus});
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
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                });                         
     
    foreach (keys %{$maps_counters}) {
        my ($id, $name) = split /_/;
        if (!defined($maps_counters->{$_}->{threshold}) || $maps_counters->{$_}->{threshold} != 0) {
            $options{options}->add_options(arguments => {
                                                        'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                        'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                           });
        }
        my $class = $maps_counters->{$_}->{class};
        $maps_counters->{$_}->{obj} = $class->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $name);
        $maps_counters->{$_}->{obj}->set(%{$maps_counters->{$_}->{set}});
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach (keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }
    $overload_th = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ('ap', $1, $2);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $overload_th->{$section} = [] if (!defined($overload_th->{$section}));
        push @{$overload_th->{$section}}, {filter => $filter, status => $status};
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{ap_selected}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All AP status are ok');
    }
    
    foreach my $id ($self->{snmp}->oid_lex_sort(keys %{$self->{ap_selected}})) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits;
        foreach (sort keys %{$maps_counters}) {
            $maps_counters->{$_}->{obj}->set(instance => $id);
        
            my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{ap_selected}->{$id});

            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $maps_counters->{$_}->{obj}->output_error();
                $long_msg_append = ', ';
                next;
            }
            my $exit2 = $maps_counters->{$_}->{obj}->threshold_check();
            push @exits, $exit2;

            my $output = $maps_counters->{$_}->{obj}->output();
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = ', ';
            
            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = ', ';
            }
            
            $maps_counters->{$_}->{obj}->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "AP '" . $self->{ap_selected}->{$id}->{display} . "' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "AP '" . $self->{ap_selected}->{$id}->{display} . "' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "AP '" . $self->{ap_selected}->{$id}->{display} . "' $long_msg");
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
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

sub manage_selection {
    my ($self, %options) = @_;

    $self->{ap_selected} = {};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [ { oid => $mapping->{bsnAPName}->{oid} },
                                                                   { oid => $mapping2->{bsnAPOperationStatus}->{oid} },
                                                                   { oid => $mapping3->{bsnAPAdminStatus}->{oid} },
                                                                 ],
                                                         nothing_quit => 1);
    foreach my $oid (keys %{$self->{results}->{ $mapping->{bsnAPName}->{oid} }}) {
        $oid =~ /^$mapping->{bsnAPName}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $mapping->{bsnAPName}->{oid} }, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{ $mapping2->{bsnAPOperationStatus}->{oid} }, instance => $instance);
        my $result3 = $self->{snmp}->map_instance(mapping => $mapping3, results => $self->{results}->{ $mapping3->{bsnAPAdminStatus}->{oid} }, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{bsnAPName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{bsnAPName} . "': no matching filter.");
            next;
        }
        
        $self->{ap_selected}->{$instance} = { display => $result->{bsnAPName}, 
                                              opstatus => $result2->{bsnAPOperationStatus}, admstatus => $result3->{bsnAPAdminStatus}};
    }
    
    if (scalar(keys %{$self->{ap_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check AP status.

=over 8

=item B<--filter-name>

Filter AP name (can be a regexp).

=item B<--threshold-overload>

Set to overload default ap threshold values (syntax: status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='CRITICAL,^(?!(associated)$)'

=back

=cut
