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

package storage::panzura::snmp::mode::ratios;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    dedup   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'dedup' }, ],
                        output_template => 'Deduplication ratio : %.2f',
                        perfdatas => [
                            { value => 'dedup_absolute', template => '%.2f', min => 0 },
                        ],
                    }
               },
    comp   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'comp' }, ],
                        output_template => 'Compression ratio : %.2f',
                        perfdatas => [
                            { value => 'comp_absolute', template => '%.2f', min => 0 },
                        ],
                    }
               },
    save   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'save' }, ],
                        output_template => 'Save ratio : %.2f',
                        perfdatas => [
                            { value => 'save_absolute', template => '%.2f', min => 0 },
                        ],
                    }
               },
};

my $oid_dedupRatio = '.1.3.6.1.4.1.32853.1.3.1.5.1.0';
my $oid_compRatio = '.1.3.6.1.4.1.32853.1.3.1.6.1.0';
my $oid_saveRatio = '.1.3.6.1.4.1.32853.1.3.1.7.1.0';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    foreach (keys %{$maps_counters}) {
        $options{options}->add_options(arguments => {
                                                     'warning-' . $_ . ':s'    => { name => 'warning-' . $_ },
                                                     'critical-' . $_ . ':s'    => { name => 'critical-' . $_ },
                                      });
        my $class = $maps_counters->{$_}->{class};
        $maps_counters->{$_}->{obj} = $class->new(statefile => $self->{statefile_value},
                                                  output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $_);
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
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
  
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All ratios are ok');
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->set(instance => 'global');
    
        my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{global});

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
        
        $self->{output}->output_add(long_msg => $output);
        $maps_counters->{$_}->{obj}->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "$short_msg"
                                    );
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $request = [$oid_dedupRatio, $oid_compRatio, $oid_saveRatio];
    
    $self->{results} = $self->{snmp}->get_leef(oids => $request, nothing_quit => 1);
    
    $self->{global} = {};
    $self->{global}->{dedup} = defined($self->{results}->{$oid_dedupRatio}) ? $self->{results}->{$oid_dedupRatio} / 100 : 0;
    $self->{global}->{comp} = defined($self->{results}->{$oid_compRatio}) ? $self->{results}->{$oid_compRatio} / 100 : 0;
    $self->{global}->{save} = defined($self->{results}->{$oid_saveRatio}) ? $self->{results}->{$oid_saveRatio} / 100 : 0;
}

1;

__END__

=head1 MODE

Check deduplication, compression and save ratios (panzura-systemext).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'dedup', 'comp', 'save'.

=item B<--critical-*>

Threshold critical.
Can be: 'dedup', 'comp', 'save'.

=back

=cut
    