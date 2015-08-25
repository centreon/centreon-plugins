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

package storage::emc::vplex::restapi::mode::directors;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.1';
    $options{options}->add_options(arguments =>
                                {
                                 "engine:s"        => { name => 'engine', default => '1-1' },
                                 "filter-name:s"   => { name => 'filter_name'},
                                 "detailed:s"      => { name => 'detailed'},
               });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{engine})) {
        $self->{output}->add_option_msg(short_msg => "You need to specify engine number.");
        $self->{output}->option_exit();
    }

}

sub run {
    my ($self, %options) = @_;
    my $vplex = $options{custom};
    
    my $urlbase = '/vplex/engines/engine-';

   $vplex->connect();

    my @items = $vplex->get_items(url => $urlbase,
                                  engine => $self->{option_results}->{engine},
                                  obj => 'directors');

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All Directors are OK');

    if (defined($self->{option_results}->{detailed})) {

        foreach my $item (@items) {

            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $item !~ /$self->{option_results}->{filter_name}/) {
                $self->{output}->output_add(long_msg => sprintf("Skipping storage '%s'.", $item));
                next;
            }

            my $details = $vplex->get_infos(url => $urlbase,
                                             obj => 'directors',
                                             engine => $self->{option_results}->{engine},
                                             item => $item);

            $self->{output}->output_add(long_msg => sprintf("Director '%s': communication-status -> '%s' health-state -> '%s' temp thresold exceeded -> '%s' voltage thresold exceeded -> '%s'", 
                                                            $item, 
                                                            $details->{context}->[0]->{attributes}->[5]->{value},
                                                            $details->{context}->[0]->{attributes}->[15]->{value},
                                                            $details->{context}->[0]->{attributes}->[28]->{value},
                                                            $details->{context}->[0]->{attributes}->[29]->{value}
                                                           ));

            if (($details->{context}->[0]->{attributes}->[15]->{value} ne 'ok') || ($details->{context}->[0]->{attributes}->[5]->{value} ne 'ok')) {
                $self->{output}->output_add(severity => 'CRITICAL',
                                            short_msg => sprintf("Director '%s' communication-status is '%s' (health='%s')",
                                                                 $item,
                                                                 $details->{context}->[0]->{attributes}->[5]->{value},
                                                                 $details->{context}->[0]->{attributes}->[15]->{value}->[0]));
            } elsif (($details->{context}->[0]->{attributes}->[28]->{value} ne 'false') || ($details->{context}->[0]->{attributes}->[29]->{value}  ne 'false')) {
                $self->{output}->output_add(severity => 'CRITICAL',
                                            short_msg => sprintf("Director '%s' temp threshold is '%s' and voltage threshold is '%s'",
                                                                 $details->{context}->[0]->{attributes}->[28]->{value},
                                                                 $details->{context}->[0]->{attributes}->[29]->{value}));                                                                
            }

        }

    } else {

       foreach my $item (@items) {

            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $item !~ /$self->{option_results}->{filter_name}/) {
                $self->{output}->output_add(long_msg => sprintf("Skipping storage '%s'.", $item));
                next;
            }

            my $details = $vplex->get_param(url => $urlbase,
                                            obj => 'directors',
                                            engine => $self->{option_results}->{engine},
                                            param => 'health-state',
                                            item => $item);

            $self->{output}->output_add(long_msg => sprintf("Director '%s' health-state -> '%s'",
                                                            $item, $details->{context}->[0]->{attributes}->[0]->{value}));
 
            if ($details->{context}->[0]->{attributes}->[0]->{value} ne 'ok') {
                $self->{output}->output_add(severity => 'CRITICAL',
                                            short_msg => sprintf("Director '%s' health is '%s'",
                                                                  $item,
                                                                  $details->{context}->[0]->{attributes}->[0]->{value}));
            }
       }
   }

     $self->{output}->display();
     $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Directors state for VPlex

=over 8

=item B<--engine>

Specify the engine number to be checked (1-1 or 2-1 usually)

=item B<--detailed>

Not mandatory, if used, display details about temp and voltage, otherwise only global health-state

=item B<--filter-name>

Filter some elements by name (can be a regexp)

=back

=cut
