
package Paws::ElastiCache::ListTagsForResource {
  use Moose;
  has ResourceName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListTagsForResource');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::TagListMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListTagsForResourceResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::ListTagsForResource - Arguments for method ListTagsForResource on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListTagsForResource on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method ListTagsForResource.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListTagsForResource.

As an example:

  $service_obj->ListTagsForResource(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ResourceName => Str

  

The name of the resource for which you want the list of tags, for
example C<arn:aws:elasticache:us-west-2:0123456789:cluster:myCluster>.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListTagsForResource in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

