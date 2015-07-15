
package Paws::DynamoDB::ListTablesOutput {
  use Moose;
  has LastEvaluatedTableName => (is => 'ro', isa => 'Str');
  has TableNames => (is => 'ro', isa => 'ArrayRef[Str]');

}

### main pod documentation begin ###

=head1 NAME

Paws::DynamoDB::ListTablesOutput

=head1 ATTRIBUTES

=head2 LastEvaluatedTableName => Str

  

The name of the last table in the current page of results. Use this
value as the I<ExclusiveStartTableName> in a new request to obtain the
next page of results, until all the table names are returned.

If you do not receive a I<LastEvaluatedTableName> value in the
response, this means that there are no more table names to be
retrieved.









=head2 TableNames => ArrayRef[Str]

  

The names of the tables associated with the current account at the
current endpoint. The maximum size of this array is 100.

If I<LastEvaluatedTableName> also appears in the output, you can use
this value as the I<ExclusiveStartTableName> parameter in a subsequent
I<ListTables> request and obtain the next page of results.











=cut

1;