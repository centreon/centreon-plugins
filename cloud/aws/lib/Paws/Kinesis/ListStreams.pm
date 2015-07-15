
package Paws::Kinesis::ListStreams {
  use Moose;
  has ExclusiveStartStreamName => (is => 'ro', isa => 'Str');
  has Limit => (is => 'ro', isa => 'Int');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListStreams');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Kinesis::ListStreamsOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Kinesis::ListStreams - Arguments for method ListStreams on Paws::Kinesis

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListStreams on the 
Amazon Kinesis service. Use the attributes of this class
as arguments to method ListStreams.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListStreams.

As an example:

  $service_obj->ListStreams(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ExclusiveStartStreamName => Str

  

The name of the stream to start the list with.










=head2 Limit => Int

  

The maximum number of streams to list.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListStreams in L<Paws::Kinesis>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

