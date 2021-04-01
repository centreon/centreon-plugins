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

package storage::emc::xtremio::restapi::mode::ssdendurance;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
                                "filter:s@"     => { name => 'filter' },
                                "warning:s"     => { name => 'warning' },
                                "critical:s"    => { name => 'critical' },
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

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    my $xtremio = $options{custom};
        
    my $urlbase = '/api/json/types/';
    my @items = $xtremio->get_items(url => $urlbase,
                                    obj => 'ssds');

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All SSDs Endurance are OK');

    foreach my $item (@items) {
        next if ($self->check_filter(section => 'ssds', instance => $item));
        my $details = $xtremio->get_details(url  => $urlbase,
                                            obj  => 'ssds',
                                            name => $item);

        $self->{output}->output_add(long_msg => sprintf("SSD '%s' endurance remaining is %i%%",
                                                        $item, $details->{'percent-endurance-remaining'}));


        my $exit = $self->{perfdata}->threshold_check(value => $details->{'percent-endurance-remaining'},
                                                      threshold => [ { label => 'warning', exit_litteral => 'warning' }, { label => 'critical', exit_litteral => 'critical' } ]);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("SSD '%s' endurance is %i%%",
                                                             $item, $details->{'percent-endurance-remaining'}));
        }
        $self->{output}->perfdata_add(label => $item . "_endurance", unit => '%',
                                      value => $details->{'percent-endurance-remaining'},
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0, max => 100);
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
                $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section $options{instance} instance."));
                return 1;
            }
        }
    }
    
    return 0;
}

1;

__END__

=head1 MODE

Check SSDs endurance level (100% is the best value)

=over 8

=item B<--filter>

Filter some parts (comma seperated list)
Can also exclude specific instance: --filter=ssds,SSD-NAME-NUMBER

=item B<--warning>

Warning trigger for SSD endurance

=item B<--critical>

Critical trigger for SSD endurance

=back

=cut
