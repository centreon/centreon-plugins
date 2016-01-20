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

package snmp_standard::mode::inodes;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    disk => {
        '000_usage'   => {
            set => {
                key_values => [ { name => 'usage' }, { name => 'display' } ],
                output_template => 'Used: %s %%', output_error_template => "%s",
                perfdatas => [
                    { label => 'used', value => 'usage_absolute', template => '%d',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            },
        },
    }
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "name"                    => { name => 'use_name' },
                                  "diskpath:s"              => { name => 'diskpath' },
                                  "regexp"                  => { name => 'use_regexp' },
                                  "regexp-isensitive"       => { name => 'use_regexpi' },
                                  "filter-device:s"         => { name => 'filter_device' },
                                  "display-transform-src:s" => { name => 'display_transform_src' },
                                  "display-transform-dst:s" => { name => 'display_transform_dst' },
                                });

    foreach my $key (('disk')) {
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
    
    foreach my $key (('disk')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{disk_selected}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All inode partitions are ok');
    }
    
    foreach my $id (sort keys %{$self->{disk_selected}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits;
        foreach (sort keys %{$maps_counters->{disk}}) {
            my $obj = $maps_counters->{disk}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{disk_selected}->{$id});

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
            
            $obj->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "Inode partition '" . $self->{disk_selected}->{$id}->{display} . "' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Inode partition '" . $self->{disk_selected}->{$id}->{display} . "' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Inode partition '" . $self->{disk_selected}->{$id}->{display} . "' $long_msg");
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

my $mapping = {
    dskPath => { oid => '.1.3.6.1.4.1.2021.9.1.2' },
    dskDevice => { oid => '.1.3.6.1.4.1.2021.9.1.3' },
    dskPercentNode => { oid => '.1.3.6.1.4.1.2021.9.1.10' },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my $results = $self->{snmp}->get_multiple_table(oids => [ { oid => $mapping->{dskPath}->{oid} }, 
                                                              { oid => $mapping->{dskDevice}->{oid} }, 
                                                              { oid => $mapping->{dskPercentNode}->{oid} } ],
                                                    return_type => 1, nothing_quit => 1);
    $self->{disk_selected} = {};
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$results})) {
        next if ($oid !~ /^$mapping->{dskPath}->{oid}\.(.*)/);
        my $instance = $1;
        
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);
        $result->{dskPath} = $self->get_display_value(value => $result->{dskPath});
        
        $self->{output}->output_add(long_msg => sprintf("disk path : '%s', device : '%s'", $result->{dskPath}, $result->{dskDevice}), debug => 1);
        
        if (!defined($result->{dskPercentNode})) {
            $self->{output}->output_add(long_msg => sprintf("skipping '%s' : no inode usage value", $result->{dskPath}), debug => 1);
            next;
        }
        if (defined($result->{dskDevice}) && defined($self->{option_results}->{filter_device}) && 
            $self->{option_results}->{filter_device} ne '' && $result->{dskDevice} !~ /$self->{option_results}->{filter_device}/) {
            $self->{output}->output_add(long_msg => sprintf("skipping '%s' : filter disk device", $result->{dskPath}), debug => 1);
            next;
        }   
        
        if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{diskpath})) {
            if ($self->{option_results}->{diskpath} !~ /(^|\s|,)$instance(\s*,|$)/) {
                $self->{output}->output_add(long_msg => sprintf("skipping '%s' : filter id disk path", $result->{dskPath}), debug => 1);
                next;
            }
        } elsif (defined($self->{option_results}->{diskpath}) && $self->{option_results}->{diskpath} ne '') {
            if (defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) && $result->{dskPath} !~ /$self->{option_results}->{diskpath}/i) {
                $self->{output}->output_add(long_msg => sprintf("skipping '%s' : filter disk path", $result->{dskPath}), debug => 1);
                next;
            }
            if (defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $result->{dskPath} !~ /$self->{option_results}->{diskpath}/) {
                $self->{output}->output_add(long_msg => sprintf("skipping '%s' : filter disk path", $result->{dskPath}), debug => 1);
                next;
            }
            if (!defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $result->{dskPath} ne $self->{option_results}->{diskpath}) {
                $self->{output}->output_add(long_msg => sprintf("skipping '%s' : filter disk path", $result->{dskPath}), debug => 1);
                next;
            }
        }
        
        $self->{disk_selected}->{$instance} = { display => $result->{dskPath}, 
                                                usage => $result->{dskPercentNode} };
    }
    
    if (scalar(keys %{$self->{disk_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

sub get_display_value {
    my ($self, %options) = @_;
    my $value = $options{value};

    if (defined($self->{option_results}->{display_transform_src})) {
        $self->{option_results}->{display_transform_dst} = '' if (!defined($self->{option_results}->{display_transform_dst}));
        eval "\$value =~ s{$self->{option_results}->{display_transform_src}}{$self->{option_results}->{display_transform_dst}}";
    }
    return $value;
}

1;

__END__

=head1 MODE

Check Inodes space usage on partitions.
Need to enable "includeAllDisks 10%" on snmpd.conf.

=over 8

=item B<--warning-usage>

Threshold warning in percent.

=item B<--critical-usage>

Threshold critical in percent.

=item B<--diskpath>

Set the disk path (number expected) ex: 1, 2,... (empty means 'check all disks path').

=item B<--name>

Allows to use disk path name with option --diskpath instead of disk path oid index.

=item B<--regexp>

Allows to use regexp to filter diskpath (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--display-transform-src>

Regexp src to transform display value. (security risk!!!)

=item B<--display-transform-dst>

Regexp dst to transform display value. (security risk!!!)

=item B<--filter-device>

Filter device name (Can be a regexp).

=back

=cut
