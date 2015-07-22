
package Paws::DynamoDBStreams::GetRecords {
  use Moose;
  has Limit => (is => 'ro', isa => 'Int');
  has ShardIterator => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetRecords');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DynamoDBStreams::GetRecordsOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DynamoDBStreams::GetRecords - Arguments for method GetRecords on Paws::DynamoDBStreams

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetRecords on the 
Amazon DynamoDB Streams service. Use the attributes of this class
as arguments to method GetRecords.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetRecords.

As an example:

  $service_obj->GetRecords(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Limit => Int

  

The maximum number of records to return from the shard. The upper limit
is 1000.










=head2 B<REQUIRED> ShardIterator => Str

  

A shard iterator that was retrieved from a previous GetShardIterator
operation. This iterator can be used to access the stream records in
this shard.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetRecords in L<Paws::DynamoDBStreams>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

