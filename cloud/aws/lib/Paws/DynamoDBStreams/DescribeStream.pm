
package Paws::DynamoDBStreams::DescribeStream {
  use Moose;
  has ExclusiveStartShardId => (is => 'ro', isa => 'Str');
  has Limit => (is => 'ro', isa => 'Int');
  has StreamArn => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeStream');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DynamoDBStreams::DescribeStreamOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DynamoDBStreams::DescribeStream - Arguments for method DescribeStream on Paws::DynamoDBStreams

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeStream on the 
Amazon DynamoDB Streams service. Use the attributes of this class
as arguments to method DescribeStream.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeStream.

As an example:

  $service_obj->DescribeStream(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ExclusiveStartShardId => Str

  

The shard ID of the first item that this operation will evaluate. Use
the value that was returned for C<LastEvaluatedShardId> in the previous
operation.










=head2 Limit => Int

  

The maximum number of shard objects to return. The upper limit is 100.










=head2 B<REQUIRED> StreamArn => Str

  

The Amazon Resource Name (ARN) for the stream.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeStream in L<Paws::DynamoDBStreams>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

