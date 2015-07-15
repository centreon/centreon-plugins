
package Paws::Kinesis::AddTagsToStream {
  use Moose;
  has StreamName => (is => 'ro', isa => 'Str', required => 1);
  has Tags => (is => 'ro', isa => 'Paws::Kinesis::TagMap', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AddTagsToStream');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Kinesis::AddTagsToStream - Arguments for method AddTagsToStream on Paws::Kinesis

=head1 DESCRIPTION

This class represents the parameters used for calling the method AddTagsToStream on the 
Amazon Kinesis service. Use the attributes of this class
as arguments to method AddTagsToStream.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AddTagsToStream.

As an example:

  $service_obj->AddTagsToStream(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> StreamName => Str

  

The name of the stream.










=head2 B<REQUIRED> Tags => Paws::Kinesis::TagMap

  

The set of key-value pairs to use to create the tags.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AddTagsToStream in L<Paws::Kinesis>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

