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

package apps::pacemaker::local::mode::constraints;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'resource:s' => { name => 'resource' },
        'warning'    => { name => 'warning' }
    });

    $self->{threshold} = 'CRITICAL';
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{resource}) || $self->{option_results}->{resource} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please set the resource name with --resource option");
        $self->{output}->option_exit();
    }

    $self->{threshold} = 'WARNING' if (defined $self->{option_results}->{warning});
}

sub parse_output {
    my ($self, %options) = @_;

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => sprintf("Resource '%s' constraint location is OK", $self->{option_results}->{resource})
    );

    if ($options{output} =~ /Connection to cluster failed\:(.*)/i ) {
        $self->{output}->output_add(
            severity => 'CRITICAL',
            short_msg => "Connection to cluster FAILED: $1"
        );
        return ;
    }

    my @lines = split /\n/, $options{output};
    foreach my $line (@lines) {
        next if $line !~ /^\s+:\sNode/;
        if ($line =~ /^\s+:\sNode/) {
            $self->{output}->output_add(long_msg => sprintf('Processed %s', $line), debug => 1);
            $line =~ /^\s+:\sNode\s([a-zA-Z0-9-_]+)\s+\(score=([a-zA-Z0-9-_]+),\sid=([a-zA-Z0-9-_]+)/;
            my ($node, $score, $rule) = ($1, $2, $3);
            if ($score eq '-INFINITY' && $rule =~ /^cli-ban/) {
                $self->{output}->output_add(
                    severity => $self->{threshold},
                    short_msg => sprintf("Resource '%s' is locked on node '%s' ('%s')", $self->{option_results}->{resource}, $node, $rule)
                );
            }
        } else {
            $self->{output}->output_add(
                severity => 'UNKNOWN',
                short_msg => "ERROR: $line"
            );
        }
    }
}

sub run {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'crm_resource',
        command_path => '/usr/sbin',
        command_options => '--constraints -r ' . $self->{option_results}->{resource}
    );

    $self->parse_output(output => $stdout);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check that a resource has no location constraint (migrate without unmigrate)
Can be executed from any cluster node.

Command used: /usr/sbin/crm_resource --constraints -r resource_name

=over 8

=item B<--resource>

Set the resource name you want to check

=item B<--warning>

Return a warning instead of a critical

=back

=cut
