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

package snmp_standard::mode::inodes;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;

my $oid_dskPath = '.1.3.6.1.4.1.2021.9.1.2';
my $oid_dskPercentNode = '.1.3.6.1.4.1.2021.9.1.10';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning' },
                                  "critical:s"              => { name => 'critical' },
                                  "reload-cache-time:s"     => { name => 'reload_cache_time', default => 180 },
                                  "name"                    => { name => 'use_name' },
                                  "diskpath:s"              => { name => 'diskpath' },
                                  "regexp"                  => { name => 'use_regexp' },
                                  "regexp-isensitive"       => { name => 'use_regexpi' },
                                  "display-transform-src:s" => { name => 'display_transform_src' },
                                  "display-transform-dst:s" => { name => 'display_transform_dst' },
                                  "show-cache"              => { name => 'show_cache' },
                                });

    $self->{diskpath_id_selected} = [];
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    
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
    
    $self->{statefile_cache}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    $self->manage_selection();

    $self->{snmp}->load(oids => [$oid_dskPercentNode], instances => $self->{diskpath_id_selected});
    my $result = $self->{snmp}->get_leef(nothing_quit => 1);

    if (!defined($self->{option_results}->{diskpath}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All inode partitions are ok.');
    }

    foreach (sort @{$self->{diskpath_id_selected}}) {
        my $name_diskpath = $self->get_display_value(id => $_);

        if (!defined($result->{$oid_dskPercentNode . '.' . $_})) {
            $self->{output}->output_add(long_msg => "Cannot usage for '" . $name_diskpath . "'", debug => 1);
            next;
        }
        
        my $prct_used = $result->{$oid_dskPercentNode . '.' . $_};
        my $prct_free = 100 - $prct_used;

        my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

        $self->{output}->output_add(long_msg => sprintf("Inodes partition '%s' Used: %s %%  Free: %s %%", 
                                            $name_diskpath, $prct_used, $prct_free));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{diskpath}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Inodes partition '%s' Used: %s %%  Free: %s %%", 
                                            $name_diskpath, $prct_used, $prct_free));
        }    

        my $label = 'used';
        my $extra_label = '';
        $extra_label = '_' . $name_diskpath if (!defined($self->{option_results}->{diskpath}) || defined($self->{option_results}->{use_regexp}));
        $self->{output}->perfdata_add(label => $label . $extra_label, unit => '%',
                                      value => $prct_used,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0, max => 100);
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub reload_cache {
    my ($self) = @_;
    my $datas = {};

    my $result = $self->{snmp}->get_table(oid => $oid_dskPath);
    $datas->{last_timestamp} = time();
    $datas->{all_ids} = [];
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /\.([0-9]+)$/);
        push @{$datas->{all_ids}}, $1;
        $datas->{'dskPath_' . $1} = $self->{output}->to_utf8($result->{$key});
    }
    
    if (scalar(@{$datas->{all_ids}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't construct cache...");
        $self->{output}->option_exit();
    }

    $self->{statefile_cache}->write(data => $datas);
}

sub manage_selection {
    my ($self, %options) = @_;

    # init cache file
    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_snmpstandard_' . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    if (defined($self->{option_results}->{show_cache})) {
        $self->{output}->add_option_msg(long_msg => $self->{statefile_cache}->get_string_content());
        $self->{output}->option_exit();
    }

    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || 
        ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {
            $self->reload_cache();
            $self->{statefile_cache}->read();
    }

    my $all_ids = $self->{statefile_cache}->get(name => 'all_ids');
    if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{diskpath})) {
        # get by ID
        push @{$self->{diskpath_id_selected}}, $self->{option_results}->{diskpath}; 
        my $name = $self->{statefile_cache}->get(name => 'dskPath_' . $self->{option_results}->{diskpath});
        if (!defined($name)) {
            $self->{output}->add_option_msg(short_msg => "No disk path found for id '" . $self->{option_results}->{diskpath} . "'.");
            $self->{output}->option_exit();
        }
    } else {
        foreach my $i (@{$all_ids}) {
            my $filter_name = $self->{statefile_cache}->get(name => 'dskPath_' . $i);
            next if (!defined($filter_name));
            if (!defined($self->{option_results}->{diskpath})) {
                push @{$self->{diskpath_id_selected}}, $i; 
                next;
            }
            if (defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{diskpath}/i) {
                push @{$self->{diskpath_id_selected}}, $i; 
            }
            if (defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{diskpath}/) {
                push @{$self->{diskpath_id_selected}}, $i; 
            }
            if (!defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name eq $self->{option_results}->{diskpath}) {
                push @{$self->{diskpath_id_selected}}, $i; 
            }
        }
        
        if (scalar(@{$self->{diskpath_id_selected}}) <= 0) {
            if (defined($self->{option_results}->{diskpath})) {
                $self->{output}->add_option_msg(short_msg => "No disk path found for name '" . $self->{option_results}->{diskpath} . "' (maybe you should reload cache file).");
            } else {
                $self->{output}->add_option_msg(short_msg => "No disk path found (maybe you should reload cache file).");
            }
            $self->{output}->option_exit();
        }
    }
}

sub get_display_value {
    my ($self, %options) = @_;
    my $value = $self->{statefile_cache}->get(name => 'dskPath_' . $options{id});

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

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=item B<--diskpath>

Set the disk path (number expected) ex: 1, 2,... (empty means 'check all disks path').

=item B<--name>

Allows to use disk path name with option --diskpath instead of disk path oid index.

=item B<--regexp>

Allows to use regexp to filter diskpath (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--reload-cache-time>

Time in seconds before reloading cache file (default: 180).

=item B<--display-transform-src>

Regexp src to transform display value. (security risk!!!)

=item B<--display-transform-dst>

Regexp dst to transform display value. (security risk!!!)

=item B<--show-cache>

Display cache storage datas.

=back

=cut
