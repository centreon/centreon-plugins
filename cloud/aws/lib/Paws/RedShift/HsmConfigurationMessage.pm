
package Paws::RedShift::HsmConfigurationMessage {
  use Moose;
  has HsmConfigurations => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::HsmConfiguration]', xmlname => 'HsmConfiguration', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::HsmConfigurationMessage

=head1 ATTRIBUTES

=head2 HsmConfigurations => ArrayRef[Paws::RedShift::HsmConfiguration]

  

A list of Amazon Redshift HSM configurations.









=head2 Marker => Str

  

A value that indicates the starting point for the next set of response
records in a subsequent request. If a value is returned in a response,
you can retrieve the next set of records by providing this returned
marker value in the C<Marker> parameter and retrying the command. If
the C<Marker> field is empty, all response records have been retrieved
for the request.











=cut

