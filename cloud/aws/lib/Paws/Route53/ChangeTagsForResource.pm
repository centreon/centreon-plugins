
package Paws::Route53::ChangeTagsForResource {
  use Moose;
  has AddTags => (is => 'ro', isa => 'ArrayRef[Paws::Route53::Tag]');
  has RemoveTagKeys => (is => 'ro', isa => 'ArrayRef[Str]');
  has ResourceId => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'ResourceId' , required => 1);
  has ResourceType => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'ResourceType' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ChangeTagsForResource');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2013-04-01/tags/{ResourceType}/{ResourceId}');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'POST');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Route53::ChangeTagsForResourceResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53::ChangeTagsForResourceResponse

=head1 ATTRIBUTES

=head2 AddTags => ArrayRef[Paws::Route53::Tag]

  

A complex type that contains a list of C<Tag> elements. Each C<Tag>
element identifies a tag that you want to add or update for the
specified resource.









=head2 RemoveTagKeys => ArrayRef[Str]

  

A list of C<Tag> keys that you want to remove from the specified
resource.









=head2 B<REQUIRED> ResourceId => Str

  

The ID of the resource for which you want to add, change, or delete
tags.









=head2 B<REQUIRED> ResourceType => Str

  

The type of the resource.

- The resource type for health checks is C<healthcheck>.

- The resource type for hosted zones is C<hostedzone>.











=cut

