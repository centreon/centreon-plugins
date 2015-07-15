
package Paws::Kinesis::CreateStream {
  use Moose;
  has ShardCount => (is => 'ro', isa => 'Int', required => 1);
  has StreamName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateStream');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Kinesis::CreateStream - Arguments for method CreateStream on Paws::Kinesis

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateStream on the 
Amazon Kinesis service. Use the attributes of this class
as arguments to method CreateStream.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateStream.

As an example:

  $service_obj->CreateStream(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ShardCount => Int

  

The number of shards that the stream will use. The throughput of the
stream is a function of the number of shards; more shards are required
for greater provisioned throughput.

DefaultShardLimit;










=head2 B<REQUIRED> StreamName => Str

  

A name to identify the stream. The stream name is scoped to the AWS
account used by the application that creates the stream. It is also
scoped by region. That is, two streams in two different AWS accounts
can have the same name, and two streams in the same AWS account, but in
two different regions, can have the same name.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateStream in L<Paws::Kinesis>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

