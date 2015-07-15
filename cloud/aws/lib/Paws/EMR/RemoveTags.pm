
package Paws::EMR::RemoveTags {
  use Moose;
  has ResourceId => (is => 'ro', isa => 'Str', required => 1);
  has TagKeys => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RemoveTags');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EMR::RemoveTagsOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EMR::RemoveTags - Arguments for method RemoveTags on Paws::EMR

=head1 DESCRIPTION

This class represents the parameters used for calling the method RemoveTags on the 
Amazon Elastic MapReduce service. Use the attributes of this class
as arguments to method RemoveTags.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RemoveTags.

As an example:

  $service_obj->RemoveTags(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ResourceId => Str

  

The Amazon EMR resource identifier from which tags will be removed.
This value must be a cluster identifier.










=head2 B<REQUIRED> TagKeys => ArrayRef[Str]

  

A list of tag keys to remove from a resource.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RemoveTags in L<Paws::EMR>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

