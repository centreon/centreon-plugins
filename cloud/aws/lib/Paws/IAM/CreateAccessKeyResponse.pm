
package Paws::IAM::CreateAccessKeyResponse {
  use Moose;
  has AccessKey => (is => 'ro', isa => 'Paws::IAM::AccessKey', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::CreateAccessKeyResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> AccessKey => Paws::IAM::AccessKey

  

Information about the access key.











=cut

