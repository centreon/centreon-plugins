
package Paws::EFS::DescribeTagsResponse {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str');
  has NextMarker => (is => 'ro', isa => 'Str');
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EFS::Tag]', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EFS::DescribeTagsResponse

=head1 ATTRIBUTES

=head2 Marker => Str

  

If the request included a C<Marker>, the response returns that value in
this field.









=head2 NextMarker => Str

  

If a value is present, there are more tags to return. In a subsequent
request, you can provide the value of C<NextMarker> as the value of the
C<Marker> parameter in your next request to retrieve the next set of
tags.









=head2 B<REQUIRED> Tags => ArrayRef[Paws::EFS::Tag]

  

Returns tags associated with the file system as an array of C<Tag>
objects.











=cut

