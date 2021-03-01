package apps::proxmox::mg::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $self->{modes} = {
      'version'           => 'apps::proxmox::mg::restapi::mode::version',
      'count'             => 'apps::proxmox::mg::restapi::mode::count',
      'spam'              => 'apps::proxmox::mg::restapi::mode::spam'

    };

    $self->{custom_modes}->{api} = 'apps::proxmox::mg::restapi::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

=over 8

=back

=cut
