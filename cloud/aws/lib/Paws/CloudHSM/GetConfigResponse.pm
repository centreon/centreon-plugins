
package Paws::CloudHSM::GetConfigResponse {
  use Moose;
  has ConfigCred => (is => 'ro', isa => 'Str');
  has ConfigFile => (is => 'ro', isa => 'Str');
  has ConfigType => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CloudHSM::GetConfigResponse

=head1 ATTRIBUTES

=head2 ConfigCred => Str

  

The certificate file containing the server.pem files of the HSMs.









=head2 ConfigFile => Str

  

The chrystoki.conf configuration file.









=head2 ConfigType => Str

  

The type of credentials.











=cut

1;