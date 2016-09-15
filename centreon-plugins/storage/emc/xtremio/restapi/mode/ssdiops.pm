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

package storage::emc::xtremio::restapi::mode::ssdiops;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    ssd => {
        '000_global'   => { set => {
                key_values => [ { name => 'global_iops' }, { name => 'display' }, ],
                output_template => 'Global IOPs : %s',
                perfdatas => [
                    { label => 'global_iops', value => 'global_iops_absolute', template => '%s',
                      min => 0, unit => 'iops', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        '001_read'   => { set => {
                key_values => [ { name => 'read_iops' }, { name => 'display' }, ],
                output_template => 'Read IOPs : %s',
                perfdatas => [
                    { label => 'read_iops', value => 'read_iops_absolute', template => '%s',
                      min => 0, unit => 'iops', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        '002_write'   => { set => {
                key_values => [ { name => 'write_iops' }, { name => 'display' }, ],
                output_template => 'Write IOPs : %s',
                perfdatas => [
                    { label => 'write_iops', value => 'write_iops_absolute', template => '%s',
                      min => 0, unit => 'iops', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    },
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"           => { name => 'filter_name' },
                                });

    foreach my $key (('ssd')) {
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
    
    foreach my $key (('ssd')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }    
}

sub run {
    my ($self, %options) = @_;
    $self->{xtremio} = $options{custom};
    
    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{ssd}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All SSDs usages are ok');
    }
    
    foreach my $id (sort keys %{$self->{ssd}}) {
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$maps_counters->{ssd}}) {
            my $obj = $maps_counters->{ssd}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{ssd}->{$id});

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

        $self->{output}->output_add(long_msg => "SSD '" . $self->{ssd}->{$id}->{display} . "' Usage $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "SSD '" . $self->{ssd}->{$id}->{display} . "' Usage $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "SSD '" . $self->{ssd}->{$id}->{display} . "' Usage $long_msg");
        }
    }
     
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{ssd} = {};
    my $urlbase = '/api/json/types/';
    my @items = $self->{xtremio}->get_items(url => $urlbase,
                                            obj => 'ssds');
    foreach my $item (@items) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $item !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $item . "': no matching name.", debug => 1);
            next;
        }
        
        my $details = $self->{xtremio}->get_details(url  => $urlbase,
                                                    obj  => 'ssds',
                                                    name => $item);
        
        $self->{ssd}->{$item} = { display => $item, global_iops => $details->{iops},
                                  read_iops => $details->{'rd-iops'}, write_iops => $details->{'wr-iops'} };
    }
    
    if (scalar(keys %{$self->{ssd}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check IOPS (Global, Read, Write) on each SSDs.

=over 8

=item B<--warning-*>

Threshold warning (number of iops)
Can be: 'global', 'read', 'write'.

=item B<--critical-*>
Threshold critical (number of iops)
Can be: 'global', 'read', 'write'.

=item B<--filter-name>

Filter SSD name (can be a regexp). (e.g --filter-name '.*' for all SSDs)

=back

=cut
