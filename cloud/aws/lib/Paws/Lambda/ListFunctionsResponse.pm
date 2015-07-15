
package Paws::Lambda::ListFunctionsResponse {
  use Moose;
  has Functions => (is => 'ro', isa => 'ArrayRef[Paws::Lambda::FunctionConfiguration]');
  has NextMarker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Lambda::ListFunctionsResponse

=head1 ATTRIBUTES

=head2 Functions => ArrayRef[Paws::Lambda::FunctionConfiguration]

  

A list of Lambda functions.









=head2 NextMarker => Str

  

A string, present if there are more functions.











=cut

