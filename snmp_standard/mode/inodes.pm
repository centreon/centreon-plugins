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

package snmp_standard::mode::inodes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'disk', type => 1, cb_prefix_output => 'prefix_disk_output', message_multiple => 'All inode partitions are ok' }
    ];
    
    $self->{maps_counters}->{disk} = [
        { label => 'usage', nlabel => 'storage.inodes.usage.percentage', set => {
                key_values => [ { name => 'usage' }, { name => 'display' } ],
                output_template => 'Used: %s %%', output_error_template => "%s",
                perfdatas => [
                    { label => 'used', value => 'usage', template => '%d',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_disk_output {
    my ($self, %options) = @_;
    
    return "Inode partition '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'name'                    => { name => 'use_name' },
        'diskpath:s'              => { name => 'diskpath' },
        'regexp'                  => { name => 'use_regexp' },
        'regexp-isensitive'       => { name => 'use_regexpi' },
        'filter-device:s'         => { name => 'filter_device' },
        'filter-path:s'           => { name => 'filter_path' },
        'display-transform-src:s' => { name => 'display_transform_src' },
        'display-transform-dst:s' => { name => 'display_transform_dst' },
    });

    return $self;
}

my $mapping = {
    dskPath => { oid => '.1.3.6.1.4.1.2021.9.1.2' },
    dskDevice => { oid => '.1.3.6.1.4.1.2021.9.1.3' },
    dskPercentNode => { oid => '.1.3.6.1.4.1.2021.9.1.10' },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my $results = $options{snmp}->get_multiple_table(oids => [ { oid => $mapping->{dskPath}->{oid} }, 
                                                              { oid => $mapping->{dskDevice}->{oid} }, 
                                                              { oid => $mapping->{dskPercentNode}->{oid} } ],
                                                    return_type => 1, nothing_quit => 1);
    $self->{disk} = {};
    foreach my $oid ($options{snmp}->oid_lex_sort(keys %{$results})) {
        next if ($oid !~ /^$mapping->{dskPath}->{oid}\.(.*)/);
        my $instance = $1;
        
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);
        $result->{dskPath} = $self->get_display_value(value => $result->{dskPath});
        
        $self->{output}->output_add(long_msg => sprintf("disk path : '%s', device : '%s'", $result->{dskPath}, $result->{dskDevice}), debug => 1);
        
        if (!defined($result->{dskPercentNode})) {
            $self->{output}->output_add(long_msg => sprintf("skipping '%s' : no inode usage value", $result->{dskPath}), debug => 1);
            next;
        }
        if (defined($self->{disk}->{$result->{dskPath}})) {
             $self->{output}->output_add(long_msg => sprintf("skipping '%s' : duplicated entry", $result->{dskPath}), debug => 1);
            next;
        }
        if (defined($result->{dskDevice}) && defined($self->{option_results}->{filter_device}) && 
            $self->{option_results}->{filter_device} ne '' && $result->{dskDevice} !~ /$self->{option_results}->{filter_device}/) {
            $self->{output}->output_add(long_msg => sprintf("skipping '%s' : filter disk device", $result->{dskPath}), debug => 1);
            next;
        }
        if (defined($result->{dskPath}) && defined($self->{option_results}->{filter_path}) &&
            $self->{option_results}->{filter_path} ne '' && $result->{dskPath} !~ /$self->{option_results}->{filter_path}/) {
            $self->{output}->output_add(long_msg => sprintf("skipping '%s' : filter disk path", $result->{dskPath}), debug => 1);
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
        
        
        $self->{disk}->{$result->{dskPath}} = {
            display => $result->{dskPath}, 
            usage => $result->{dskPercentNode}
        };
    }
    
    if (scalar(keys %{$self->{disk}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No entry found.');
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

Filter devices by name (regexp).

=item B<--filter-path>

Filter devices by path (regexp).

=back

=cut
