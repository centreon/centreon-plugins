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

package cloud::azure::management::insightsmetrics::mode::listlogicaldisks;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'computer:s' => { name => 'computer' },
        'workspace-id:s'    => { name => 'workspace_id' }
    });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{computer}) || $self->{option_results}->{computer} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --computer option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

   my $query = 'InsightsMetrics | where Namespace == "LogicalDisk" | distinct Tags, Computer | where Computer == "' . $self->{option_results}->{computer} . '"';

    my ($analytics_results) = $options{custom}->azure_get_log_analytics(
        workspace_id => $self->{option_results}->{workspace_id},
        query => $query,
        timespan => $self->{option_results}->{timespan}
    );

    foreach (@{$analytics_results->{tables}}) {
        my ($i, $j) = (0, 0);
        foreach my $entry (@{$_->{columns}}) {
            $self->{raw_results}->{index}->{$entry->{name}} = $i;
            $i++;
        }

        foreach (@{$_->{rows}}) {
            $self->{raw_results}->{data}->{$j}->{tags} = @$_[$self->{raw_results}->{index}->{Tags}];
            $self->{raw_results}->{data}->{$j}->{computer} = @$_[$self->{raw_results}->{index}->{Computer}];
            $j++;
        }
    }
    my $status_mapping = {
        0 => 'NOT OK',
        1 => 'OK'
    };

    my $decoded_tag;
    foreach my $entry (keys %{$self->{raw_results}->{data}}) {
        $decoded_tag = $options{custom}->json_decode(content => $self->{raw_results}->{data}->{$entry}->{tags});

        $self->{logicaldisk}->{$decoded_tag->{"vm.azm.ms/mountId"}}->{name} = $decoded_tag->{"vm.azm.ms/mountId"};
    }
    #use Data::Dumper;print Dumper($self->{logicaldisk}); exit 0;
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $mount (sort keys %{$self->{logicaldisk}}) { 
        $self->{output}->output_add(long_msg => '[name = ' . $mount . ']' );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List mounts:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $mount (sort keys %{$self->{logicaldisk}}) {
        $self->{output}->add_disco_entry(name => $self->{logicaldisk}->{$mount}->{name});
    }
}

1;

__END__

=head1 MODE

List Azure Computer logical disks.

=over 8

=back

=cut
    
