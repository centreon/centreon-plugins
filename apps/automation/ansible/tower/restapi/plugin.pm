#...
# Authors: Guillaume Carpentier <guillaume.carpentier@externes.justice.gouv.fr>

package apps::automation::ansible::tower::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    %{$self->{modes}} = (
        'job-template'   => 'apps::automation::ansible::tower::restapi::mode::jobtemplate',
        'jobs'           => 'apps::automation::ansible::tower::restapi::mode::jobs',
        'schedule'       => 'apps::automation::ansible::tower::restapi::mode::schedule',
    );
    $self->{custom_modes}{api} = 'apps::automation::ansible::tower::restapi::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Checks various elements of Tower/AWX through its REST API.
Currently supports :
    check job result
    check scheduled job-template result
    launch job template and checks its result


=over 8

=back

=cut
