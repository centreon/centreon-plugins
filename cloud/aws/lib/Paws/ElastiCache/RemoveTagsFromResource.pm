
package Paws::ElastiCache::RemoveTagsFromResource {
  use Moose;
  has ResourceName => (is => 'ro', isa => 'Str', required => 1);
  has TagKeys => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RemoveTagsFromResource');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::TagListMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'RemoveTagsFromResourceResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::RemoveTagsFromResource - Arguments for method RemoveTagsFromResource on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method RemoveTagsFromResource on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method RemoveTagsFromResource.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RemoveTagsFromResource.

As an example:

  $service_obj->RemoveTagsFromResource(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ResourceName => Str

  

The name of the ElastiCache resource from which you want the listed
tags removed, for example
C<arn:aws:elasticache:us-west-2:0123456789:cluster:myCluster>.










=head2 B<REQUIRED> TagKeys => ArrayRef[Str]

  

A list of C<TagKeys> identifying the tags you want removed from the
named resource. For example, C<TagKeys.member.1=Region> removes the
cost allocation tag with the key name C<Region> from the resource named
by the I<ResourceName> parameter.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RemoveTagsFromResource in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

