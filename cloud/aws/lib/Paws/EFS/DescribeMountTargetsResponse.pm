
package Paws::EFS::DescribeMountTargetsResponse {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str');
  has MountTargets => (is => 'ro', isa => 'ArrayRef[Paws::EFS::MountTargetDescription]');
  has NextMarker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EFS::DescribeMountTargetsResponse

=head1 ATTRIBUTES

=head2 Marker => Str

  

If the request included the C<Marker>, the response returns that value
in this field.









=head2 MountTargets => ArrayRef[Paws::EFS::MountTargetDescription]

  

Returns the file system's mount targets as an array of
C<MountTargetDescription> objects.









=head2 NextMarker => Str

  

If a value is present, there are more mount targets to return. In a
subsequent request, you can provide C<Marker> in your request with this
value to retrieve the next set of mount targets.











=cut

