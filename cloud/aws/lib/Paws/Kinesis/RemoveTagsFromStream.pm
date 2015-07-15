
package Paws::Kinesis::RemoveTagsFromStream {
  use Moose;
  has StreamName => (is => 'ro', isa => 'Str', required => 1);
  has TagKeys => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RemoveTagsFromStream');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Kinesis::RemoveTagsFromStream - Arguments for method RemoveTagsFromStream on Paws::Kinesis

=head1 DESCRIPTION

This class represents the parameters used for calling the method RemoveTagsFromStream on the 
Amazon Kinesis service. Use the attributes of this class
as arguments to method RemoveTagsFromStream.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RemoveTagsFromStream.

As an example:

  $service_obj->RemoveTagsFromStream(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> StreamName => Str

  

The name of the stream.










=head2 B<REQUIRED> TagKeys => ArrayRef[Str]

  

A list of tag keys. Each corresponding tag is removed from the stream.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RemoveTagsFromStream in L<Paws::Kinesis>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

