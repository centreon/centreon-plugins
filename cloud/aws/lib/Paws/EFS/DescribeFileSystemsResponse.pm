
package Paws::EFS::DescribeFileSystemsResponse {
  use Moose;
  has FileSystems => (is => 'ro', isa => 'ArrayRef[Paws::EFS::FileSystemDescription]');
  has Marker => (is => 'ro', isa => 'Str');
  has NextMarker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EFS::DescribeFileSystemsResponse

=head1 ATTRIBUTES

=head2 FileSystems => ArrayRef[Paws::EFS::FileSystemDescription]

  

An array of file system descriptions.









=head2 Marker => Str

  

A string, present if provided by caller in the request.









=head2 NextMarker => Str

  

A string, present if there are more file systems than returned in the
response. You can use the C<NextMarker> in the subsequent request to
fetch the descriptions.











=cut

