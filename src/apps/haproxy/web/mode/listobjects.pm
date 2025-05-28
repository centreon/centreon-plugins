#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::haproxy::web::mode::listobjects;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'        => { name => 'filter_name' },
        'filter-object-type:s' => { name => 'filter_objtype', default => 'frontend|backend' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_stats();
    my $backends;
    foreach (@$results) {
        foreach my $entry (@$_) {
            next if (defined($self->{option_results}->{filter_objtype}) && $self->{option_results}->{filter_objtype} ne ''
            && lc($entry->{objType}) !~ /$self->{option_results}->{filter_objtype}/);
            
            $backends->{$entry->{proxyId}}->{type} = lc($entry->{objType});
            next if ($entry->{field}->{name} !~ /^(pxname|status)$/);
            $backends->{$entry->{proxyId}}->{$entry->{field}->{name}} = $entry->{value}->{value};
        }
    }
    return $backends;
}

sub run {
    my ($self, %options) = @_;

    my $backends = $self->manage_selection(%options);
    foreach (sort keys %$backends) {
        $self->{output}->output_add(
            long_msg => sprintf("[name = %s][status = %s][type = %s]", $backends->{$_}->{pxname}, $backends->{$_}->{status}, $backends->{$_}->{type})
        );
    }

    $self->{output}->output_add(severity => 'OK', short_msg => 'HAProxy objects:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name','status','type']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $backends = $self->manage_selection(%options);
    foreach (sort keys %$backends) {
        $self->{output}->add_disco_entry(
            name   => $backends->{$_}->{pxname},
            status => $backends->{$_}->{status},
            type   => $backends->{$_}->{type},
        );
    }
}
1;

__END__

=head1 MODE

List HAProxy objects (Backends & Frontends).

=over 8

=item B<--filter-object-type>

Filter object type (can be a regexp).

=item B<--filter-name>

Filter object name (can be a regexp).

=back

=cut