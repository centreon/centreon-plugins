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

package network::securactive::mode::bcn;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_spvBCNName = '.1.3.6.1.4.1.36773.3.2.2.1.1.1';
my $oid_spvBCNGlobalStatus = '.1.3.6.1.4.1.36773.3.2.2.1.1.4';

my %bcn_status = (
    1 => ['ok', 'OK'], 
    2 => ['warning', 'WARNING'], 
    3 => ['alert', 'WARNING'], 
    4 => ['not available', 'UNKNOWN'],
    5 => ['not data at all', 'UNKNOWN'],
    6 => ['not enough samples for computation', 'UNKNOWN'],
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "bcn:s"                   => { name => 'bcn' },
                                  "name"                    => { name => 'use_name' },
                                  "regexp"                  => { name => 'use_regexp' },
                                  "display-transform-src:s" => { name => 'display_transform_src' },
                                  "display-transform-dst:s" => { name => 'display_transform_dst' },
                                });
    $self->{bcn_id_selected} = [];

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{result_names} = $self->{snmp}->get_table(oid => $oid_spvBCNName, nothing_quit => 1);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{result_names}})) {
        next if ($oid !~ /\.([0-9]+)$/);
        my $instance = $1;
        
        # Get all without a name
        if (!defined($self->{option_results}->{bcn})) {
            push @{$self->{bcn_id_selected}}, $instance; 
            next;
        }
        
        # By ID
        if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{bcn})) {
            if ($instance == $self->{option_results}->{bcn}) {
                push @{$self->{bcn_id_selected}}, $instance; 
            }
            next;
        }
        
        $self->{result_names}->{$oid} = $self->{output}->decode($self->{result_names}->{$oid});
        if (!defined($self->{option_results}->{use_regexp}) && $self->{result_names}->{$oid} eq $self->{option_results}->{bcn}) {
            push @{$self->{bcn_id_selected}}, $instance; 
        }
        if (defined($self->{option_results}->{use_regexp}) && $self->{result_names}->{$oid} =~ /$self->{option_results}->{bcn}/) {
            push @{$self->{bcn_id_selected}}, $instance;
        }
    }

    if (scalar(@{$self->{bcn_id_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No bcn found for name '" . $self->{option_results}->{bcn} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    $self->manage_selection();
    $self->{snmp}->load(oids => [$oid_spvBCNGlobalStatus], 
                        instances => $self->{bcn_id_selected});
    my $result = $self->{snmp}->get_leef();
    
    if (!defined($self->{option_results}->{bcn}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All BCN are ok.');
    }
    
    foreach my $instance (sort @{$self->{bcn_id_selected}}) {
        my $name = $self->{result_names}->{$oid_spvBCNName . '.' . $instance};
        $name = $self->get_display_value(value => $name);
        my $status = $result->{$oid_spvBCNGlobalStatus . '.' . $instance};
        my $exit_from_snmp = ${$bcn_status{$status}}[1];
        
        $self->{output}->output_add(long_msg => sprintf("BCN '%s' global status is '%s'", 
                                                        $name, ${$bcn_status{$status}}[0]));
        if (!$self->{output}->is_status(value => $exit_from_snmp, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{bcn}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit_from_snmp,
                                        short_msg => sprintf("BCN '%s' global status is '%s'", $name, ${$bcn_status{$status}}[0]));
        }
        
        my $extra_label = '';
        $extra_label = '_' . $name if (!defined($self->{option_results}->{bcn}) || defined($self->{option_results}->{use_regexp}));
        #$self->{output}->perfdata_add(label => 'eurt' . $extra_label,
        #                              value => $eurt,
        #                              warning => $warnth,
        #                              critical => $critth,
        #                              min => 0);
    }
    
    $self->{output}->display();
    $self->{output}->exit();
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

Check BCN status.

=over 8

=item B<--bcn>

Set the bcn (number expected) ex: 1, 2,... (empty means 'check all bcn').

=item B<--name>

Allows to use bcn name with option --bcn instead of bcn oid index.

=item B<--regexp>

Allows to use regexp to filter bcn (with option --name).

=item B<--display-transform-src>

Regexp src to transform display value. (security risk!!!)

=item B<--display-transform-dst>

Regexp dst to transform display value. (security risk!!!)

=back

=cut
    
