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

package network::f5::bigip::mode::nodestatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $thresholds = {
    node => [
        ['none', 'CRITICAL'],
        ['green', 'OK'],
        ['yellow', 'WARNING'],
        ['red', 'CRITICAL'],
        ['blue', 'UNKNOWN'],
        ['gray', 'UNKNOWN'],
    ],
};
my $instance_mode;

my $maps_counters = {
    node => { 
        '000_status'   => { set => {
                        key_values => [ { name => 'AvailState' } ],
                        closure_custom_calc => \&custom_status_calc,
                        output_template => 'Status : %s', output_error_template => 'Status : %s',
                        output_use => 'AvailState',
                        closure_custom_perfdata => sub { return 0; },
                        closure_custom_threshold_check => \&custom_threshold_output,
                    }
               },
        },
};


sub custom_threshold_output {
    my ($self, %options) = @_;
    
    return $instance_mode->get_severity(section => 'node', value => $self->{result_values}->{AvailState});
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{AvailState} = $options{new_datas}->{$self->{instance} . '_AvailState'};
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
 
    foreach my $key (('node')) {
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
    
    foreach my $key (('node')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }
    
    $instance_mode = $self;
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{node}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All Nodes are ok');
    }
    
    foreach my $id (sort keys %{$self->{node}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$maps_counters->{node}}) {
            my $obj = $maps_counters->{node}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{node}->{$id});

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
            
            $maps_counters->{node}->{$_}->{obj}->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "Node '$self->{node}->{$id}->{Name}' $long_msg [Status Reason: $self->{node}->{$id}->{StatusReason}]");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Node '$self->{node}->{$id}->{Name}' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Node '$self->{node}->{$id}->{Name}' $long_msg");
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
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

my %map_node_status = (
    0 => 'none',
    1 => 'green',
    2 => 'yellow',
    3 => 'red',
    4 => 'blue', # unknown
    5 => 'gray',
);
my %map_node_enabled = (
    0 => 'none',
    1 => 'enabled',
    2 => 'disabled',
    3 => 'disabledbyparent',
);

# New OIDS
my $mapping = {
    new => {
        AvailState => { oid => '.1.3.6.1.4.1.3375.2.2.4.3.2.1.3', map => \%map_node_status },
        EnabledState => { oid => '.1.3.6.1.4.1.3375.2.2.4.3.2.1.4', map => \%map_node_enabled },
        StatusReason => { oid => '.1.3.6.1.4.1.3375.2.2.4.3.2.1.6' },
    },
    old => {
        AvailState => { oid => '.1.3.6.1.4.1.3375.2.2.4.1.2.1.13', map => \%map_node_status },
        EnabledState => { oid => '.1.3.6.1.4.1.3375.2.2.4.1.2.1.14', map => \%map_node_enabled },
        StatusReason => { oid => '.1.3.6.1.4.1.3375.2.2.4.1.2.1.16' },
    },
};
my $oid_ltmNodeAddrStatusEntry = '.1.3.6.1.4.1.3375.2.2.4.3.2.1'; # new
my $oid_ltmNodeAddrEntry = '.1.3.6.1.4.1.3375.2.2.4.1.2.1'; # old

sub manage_selection {
    my ($self, %options) = @_;

    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_ltmNodeAddrEntry, start => $mapping->{old}->{AvailState}->{oid} },
                                                            { oid => $oid_ltmNodeAddrStatusEntry, start => $mapping->{new}->{AvailState}->{oid} },
                                                         ],
                                                         , nothing_quit => 1);
    
    my ($branch, $map) = ($oid_ltmNodeAddrStatusEntry, 'new');
    if (!defined($self->{results}->{$oid_ltmNodeAddrStatusEntry}) || scalar(keys %{$self->{results}->{$oid_ltmNodeAddrStatusEntry}}) == 0)  {
        ($branch, $map) = ($oid_ltmNodeAddrEntry, 'old');
    }
    
    $self->{node} = {};
    foreach my $oid (keys %{$self->{results}->{$branch}}) {
        next if ($oid !~ /^$mapping->{$map}->{AvailState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping->{$map}, results => $self->{results}->{$branch}, instance => $instance);
        
        $result->{Name} = $instance;
        # prefix by '1.4'
        $result->{Name} =~ s/^1\.4\.//;
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{Name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{Name} . "': no matching filter name.");
            next;
        }
        if ($result->{EnabledState} !~ /enabled/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{Name} . "': state is '$result->{EnabledState}'.");
            next;
        }
        $result->{StatusReason} = '-' if (!defined($result->{StatusReason}) || $result->{StatusReason} eq '');
        
        $self->{node}->{$instance} = { %$result };
    }
    
    if (scalar(keys %{$self->{node}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Nodes status.

=over 8

=item B<--filter-name>

Filter by name (regexp can be used).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='node,CRITICAL,^(?!(green)$)'

=back

=cut
