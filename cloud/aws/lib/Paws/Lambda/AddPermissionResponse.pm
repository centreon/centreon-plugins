
package Paws::Lambda::AddPermissionResponse {
  use Moose;
  has Statement => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Lambda::AddPermissionResponse

=head1 ATTRIBUTES

=head2 Statement => Str

  

The permission statement you specified in the request. The response
returns the same as a string using "\" as an escape character in the
JSON.











=cut

