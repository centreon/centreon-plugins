
package Paws::RDS::ListTagsForResource {
  use Moose;
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::RDS::Filter]');
  has ResourceName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListTagsForResource');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::TagListMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListTagsForResourceResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::ListTagsForResource - Arguments for method ListTagsForResource on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListTagsForResource on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method ListTagsForResource.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListTagsForResource.

As an example:

  $service_obj->ListTagsForResource(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Filters => ArrayRef[Paws::RDS::Filter]

  

This parameter is not currently supported.










=head2 B<REQUIRED> ResourceName => Str

  

The Amazon RDS resource with tags to be listed. This value is an Amazon
Resource Name (ARN). For information about creating an ARN, see
Constructing an RDS Amazon Resource Name (ARN).












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListTagsForResource in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

