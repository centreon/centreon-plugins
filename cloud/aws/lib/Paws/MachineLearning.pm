package Paws::MachineLearning {
  use Moose;
  sub service { 'machinelearning' }
  sub version { '2014-12-12' }
  sub target_prefix { 'AmazonML_20141212' }
  sub json_version { "1.1" }

  with 'Paws::API::Caller', 'Paws::API::RegionalEndpointCaller', 'Paws::Net::V4Signature', 'Paws::Net::JsonCaller', 'Paws::Net::JsonResponse';

  
  sub CreateBatchPrediction {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::CreateBatchPrediction', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateDataSourceFromRDS {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::CreateDataSourceFromRDS', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateDataSourceFromRedshift {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::CreateDataSourceFromRedshift', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateDataSourceFromS3 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::CreateDataSourceFromS3', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateEvaluation {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::CreateEvaluation', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateMLModel {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::CreateMLModel', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateRealtimeEndpoint {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::CreateRealtimeEndpoint', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteBatchPrediction {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::DeleteBatchPrediction', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteDataSource {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::DeleteDataSource', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteEvaluation {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::DeleteEvaluation', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteMLModel {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::DeleteMLModel', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteRealtimeEndpoint {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::DeleteRealtimeEndpoint', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeBatchPredictions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::DescribeBatchPredictions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeDataSources {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::DescribeDataSources', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeEvaluations {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::DescribeEvaluations', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeMLModels {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::DescribeMLModels', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetBatchPrediction {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::GetBatchPrediction', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetDataSource {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::GetDataSource', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetEvaluation {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::GetEvaluation', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetMLModel {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::GetMLModel', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub Predict {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::Predict', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateBatchPrediction {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::UpdateBatchPrediction', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateDataSource {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::UpdateDataSource', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateEvaluation {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::UpdateEvaluation', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateMLModel {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::MachineLearning::UpdateMLModel', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning - Perl Interface to AWS Amazon Machine Learning

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('MachineLearning')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



Definition of the public APIs exposed by Amazon Machine Learning










=head1 METHODS

=head2 CreateBatchPrediction(BatchPredictionDataSourceId => Str, BatchPredictionId => Str, MLModelId => Str, OutputUri => Str, [BatchPredictionName => Str])

Each argument is described in detail in: L<Paws::MachineLearning::CreateBatchPrediction>

Returns: a L<Paws::MachineLearning::CreateBatchPredictionOutput> instance

  

Generates predictions for a group of observations. The observations to
process exist in one or more data files referenced by a C<DataSource>.
This operation creates a new C<BatchPrediction>, and uses an C<MLModel>
and the data files referenced by the C<DataSource> as information
sources.

C<CreateBatchPrediction> is an asynchronous operation. In response to
C<CreateBatchPrediction>, Amazon Machine Learning (Amazon ML)
immediately returns and sets the C<BatchPrediction> status to
C<PENDING>. After the C<BatchPrediction> completes, Amazon ML sets the
status to C<COMPLETED>.

You can poll for status updates by using the GetBatchPrediction
operation and checking the C<Status> parameter of the result. After the
C<COMPLETED> status appears, the results are available in the location
specified by the C<OutputUri> parameter.











=head2 CreateDataSourceFromRDS(DataSourceId => Str, RDSData => Paws::MachineLearning::RDSDataSpec, RoleARN => Str, [ComputeStatistics => Bool, DataSourceName => Str])

Each argument is described in detail in: L<Paws::MachineLearning::CreateDataSourceFromRDS>

Returns: a L<Paws::MachineLearning::CreateDataSourceFromRDSOutput> instance

  

Creates a C<DataSource> object from an Amazon Relational Database
Service (Amazon RDS). A C<DataSource> references data that can be used
to perform CreateMLModel, CreateEvaluation, or CreateBatchPrediction
operations.

C<CreateDataSourceFromRDS> is an asynchronous operation. In response to
C<CreateDataSourceFromRDS>, Amazon Machine Learning (Amazon ML)
immediately returns and sets the C<DataSource> status to C<PENDING>.
After the C<DataSource> is created and ready for use, Amazon ML sets
the C<Status> parameter to C<COMPLETED>. C<DataSource> in C<COMPLETED>
or C<PENDING> status can only be used to perform CreateMLModel,
CreateEvaluation, or CreateBatchPrediction operations.

If Amazon ML cannot accept the input source, it sets the C<Status>
parameter to C<FAILED> and includes an error message in the C<Message>
attribute of the GetDataSource operation response.











=head2 CreateDataSourceFromRedshift(DataSourceId => Str, DataSpec => Paws::MachineLearning::RedshiftDataSpec, RoleARN => Str, [ComputeStatistics => Bool, DataSourceName => Str])

Each argument is described in detail in: L<Paws::MachineLearning::CreateDataSourceFromRedshift>

Returns: a L<Paws::MachineLearning::CreateDataSourceFromRedshiftOutput> instance

  

Creates a C<DataSource> from Amazon Redshift. A C<DataSource>
references data that can be used to perform either CreateMLModel,
CreateEvaluation or CreateBatchPrediction operations.

C<CreateDataSourceFromRedshift> is an asynchronous operation. In
response to C<CreateDataSourceFromRedshift>, Amazon Machine Learning
(Amazon ML) immediately returns and sets the C<DataSource> status to
C<PENDING>. After the C<DataSource> is created and ready for use,
Amazon ML sets the C<Status> parameter to C<COMPLETED>. C<DataSource>
in C<COMPLETED> or C<PENDING> status can only be used to perform
CreateMLModel, CreateEvaluation, or CreateBatchPrediction operations.

If Amazon ML cannot accept the input source, it sets the C<Status>
parameter to C<FAILED> and includes an error message in the C<Message>
attribute of the GetDataSource operation response.

The observations should exist in the database hosted on an Amazon
Redshift cluster and should be specified by a C<SelectSqlQuery>. Amazon
ML executes Unload command in Amazon Redshift to transfer the result
set of C<SelectSqlQuery> to C<S3StagingLocation.>

After the C<DataSource> is created, it's ready for use in evaluations
and batch predictions. If you plan to use the C<DataSource> to train an
C<MLModel>, the C<DataSource> requires another item -- a recipe. A
recipe describes the observation variables that participate in training
an C<MLModel>. A recipe describes how each input variable will be used
in training. Will the variable be included or excluded from training?
Will the variable be manipulated, for example, combined with another
variable or split apart into word combinations? The recipe provides
answers to these questions. For more information, see the Amazon
Machine Learning Developer Guide.











=head2 CreateDataSourceFromS3(DataSourceId => Str, DataSpec => Paws::MachineLearning::S3DataSpec, [ComputeStatistics => Bool, DataSourceName => Str])

Each argument is described in detail in: L<Paws::MachineLearning::CreateDataSourceFromS3>

Returns: a L<Paws::MachineLearning::CreateDataSourceFromS3Output> instance

  

Creates a C<DataSource> object. A C<DataSource> references data that
can be used to perform CreateMLModel, CreateEvaluation, or
CreateBatchPrediction operations.

C<CreateDataSourceFromS3> is an asynchronous operation. In response to
C<CreateDataSourceFromS3>, Amazon Machine Learning (Amazon ML)
immediately returns and sets the C<DataSource> status to C<PENDING>.
After the C<DataSource> is created and ready for use, Amazon ML sets
the C<Status> parameter to C<COMPLETED>. C<DataSource> in C<COMPLETED>
or C<PENDING> status can only be used to perform CreateMLModel,
CreateEvaluation or CreateBatchPrediction operations.

If Amazon ML cannot accept the input source, it sets the C<Status>
parameter to C<FAILED> and includes an error message in the C<Message>
attribute of the GetDataSource operation response.

The observation data used in a C<DataSource> should be ready to use;
that is, it should have a consistent structure, and missing data values
should be kept to a minimum. The observation data must reside in one or
more CSV files in an Amazon Simple Storage Service (Amazon S3) bucket,
along with a schema that describes the data items by name and type. The
same schema must be used for all of the data files referenced by the
C<DataSource>.

After the C<DataSource> has been created, it's ready to use in
evaluations and batch predictions. If you plan to use the C<DataSource>
to train an C<MLModel>, the C<DataSource> requires another item: a
recipe. A recipe describes the observation variables that participate
in training an C<MLModel>. A recipe describes how each input variable
will be used in training. Will the variable be included or excluded
from training? Will the variable be manipulated, for example, combined
with another variable, or split apart into word combinations? The
recipe provides answers to these questions. For more information, see
the Amazon Machine Learning Developer Guide.











=head2 CreateEvaluation(EvaluationDataSourceId => Str, EvaluationId => Str, MLModelId => Str, [EvaluationName => Str])

Each argument is described in detail in: L<Paws::MachineLearning::CreateEvaluation>

Returns: a L<Paws::MachineLearning::CreateEvaluationOutput> instance

  

Creates a new C<Evaluation> of an C<MLModel>. An C<MLModel> is
evaluated on a set of observations associated to a C<DataSource>. Like
a C<DataSource> for an C<MLModel>, the C<DataSource> for an
C<Evaluation> contains values for the Target Variable. The
C<Evaluation> compares the predicted result for each observation to the
actual outcome and provides a summary so that you know how effective
the C<MLModel> functions on the test data. Evaluation generates a
relevant performance metric such as BinaryAUC, RegressionRMSE or
MulticlassAvgFScore based on the corresponding C<MLModelType>:
C<BINARY>, C<REGRESSION> or C<MULTICLASS>.

C<CreateEvaluation> is an asynchronous operation. In response to
C<CreateEvaluation>, Amazon Machine Learning (Amazon ML) immediately
returns and sets the evaluation status to C<PENDING>. After the
C<Evaluation> is created and ready for use, Amazon ML sets the status
to C<COMPLETED>.

You can use the GetEvaluation operation to check progress of the
evaluation during the creation operation.











=head2 CreateMLModel(MLModelId => Str, MLModelType => Str, TrainingDataSourceId => Str, [MLModelName => Str, Parameters => Paws::MachineLearning::TrainingParameters, Recipe => Str, RecipeUri => Str])

Each argument is described in detail in: L<Paws::MachineLearning::CreateMLModel>

Returns: a L<Paws::MachineLearning::CreateMLModelOutput> instance

  

Creates a new C<MLModel> using the data files and the recipe as
information sources.

An C<MLModel> is nearly immutable. Users can only update the
C<MLModelName> and the C<ScoreThreshold> in an C<MLModel> without
creating a new C<MLModel>.

C<CreateMLModel> is an asynchronous operation. In response to
C<CreateMLModel>, Amazon Machine Learning (Amazon ML) immediately
returns and sets the C<MLModel> status to C<PENDING>. After the
C<MLModel> is created and ready for use, Amazon ML sets the status to
C<COMPLETED>.

You can use the GetMLModel operation to check progress of the
C<MLModel> during the creation operation.

CreateMLModel requires a C<DataSource> with computed statistics, which
can be created by setting C<ComputeStatistics> to C<true> in
CreateDataSourceFromRDS, CreateDataSourceFromS3, or
CreateDataSourceFromRedshift operations.











=head2 CreateRealtimeEndpoint(MLModelId => Str)

Each argument is described in detail in: L<Paws::MachineLearning::CreateRealtimeEndpoint>

Returns: a L<Paws::MachineLearning::CreateRealtimeEndpointOutput> instance

  

Creates a real-time endpoint for the C<MLModel>. The endpoint contains
the URI of the C<MLModel>; that is, the location to send real-time
prediction requests for the specified C<MLModel>.











=head2 DeleteBatchPrediction(BatchPredictionId => Str)

Each argument is described in detail in: L<Paws::MachineLearning::DeleteBatchPrediction>

Returns: a L<Paws::MachineLearning::DeleteBatchPredictionOutput> instance

  

Assigns the DELETED status to a C<BatchPrediction>, rendering it
unusable.

After using the C<DeleteBatchPrediction> operation, you can use the
GetBatchPrediction operation to verify that the status of the
C<BatchPrediction> changed to DELETED.

The result of the C<DeleteBatchPrediction> operation is irreversible.











=head2 DeleteDataSource(DataSourceId => Str)

Each argument is described in detail in: L<Paws::MachineLearning::DeleteDataSource>

Returns: a L<Paws::MachineLearning::DeleteDataSourceOutput> instance

  

Assigns the DELETED status to a C<DataSource>, rendering it unusable.

After using the C<DeleteDataSource> operation, you can use the
GetDataSource operation to verify that the status of the C<DataSource>
changed to DELETED.

The results of the C<DeleteDataSource> operation are irreversible.











=head2 DeleteEvaluation(EvaluationId => Str)

Each argument is described in detail in: L<Paws::MachineLearning::DeleteEvaluation>

Returns: a L<Paws::MachineLearning::DeleteEvaluationOutput> instance

  

Assigns the C<DELETED> status to an C<Evaluation>, rendering it
unusable.

After invoking the C<DeleteEvaluation> operation, you can use the
GetEvaluation operation to verify that the status of the C<Evaluation>
changed to C<DELETED>.

The results of the C<DeleteEvaluation> operation are irreversible.











=head2 DeleteMLModel(MLModelId => Str)

Each argument is described in detail in: L<Paws::MachineLearning::DeleteMLModel>

Returns: a L<Paws::MachineLearning::DeleteMLModelOutput> instance

  

Assigns the DELETED status to an C<MLModel>, rendering it unusable.

After using the C<DeleteMLModel> operation, you can use the GetMLModel
operation to verify that the status of the C<MLModel> changed to
DELETED.

The result of the C<DeleteMLModel> operation is irreversible.











=head2 DeleteRealtimeEndpoint(MLModelId => Str)

Each argument is described in detail in: L<Paws::MachineLearning::DeleteRealtimeEndpoint>

Returns: a L<Paws::MachineLearning::DeleteRealtimeEndpointOutput> instance

  

Deletes a real time endpoint of an C<MLModel>.











=head2 DescribeBatchPredictions([EQ => Str, FilterVariable => Str, GE => Str, GT => Str, LE => Str, Limit => Int, LT => Str, NE => Str, NextToken => Str, Prefix => Str, SortOrder => Str])

Each argument is described in detail in: L<Paws::MachineLearning::DescribeBatchPredictions>

Returns: a L<Paws::MachineLearning::DescribeBatchPredictionsOutput> instance

  

Returns a list of C<BatchPrediction> operations that match the search
criteria in the request.











=head2 DescribeDataSources([EQ => Str, FilterVariable => Str, GE => Str, GT => Str, LE => Str, Limit => Int, LT => Str, NE => Str, NextToken => Str, Prefix => Str, SortOrder => Str])

Each argument is described in detail in: L<Paws::MachineLearning::DescribeDataSources>

Returns: a L<Paws::MachineLearning::DescribeDataSourcesOutput> instance

  

Returns a list of C<DataSource> that match the search criteria in the
request.











=head2 DescribeEvaluations([EQ => Str, FilterVariable => Str, GE => Str, GT => Str, LE => Str, Limit => Int, LT => Str, NE => Str, NextToken => Str, Prefix => Str, SortOrder => Str])

Each argument is described in detail in: L<Paws::MachineLearning::DescribeEvaluations>

Returns: a L<Paws::MachineLearning::DescribeEvaluationsOutput> instance

  

Returns a list of C<DescribeEvaluations> that match the search criteria
in the request.











=head2 DescribeMLModels([EQ => Str, FilterVariable => Str, GE => Str, GT => Str, LE => Str, Limit => Int, LT => Str, NE => Str, NextToken => Str, Prefix => Str, SortOrder => Str])

Each argument is described in detail in: L<Paws::MachineLearning::DescribeMLModels>

Returns: a L<Paws::MachineLearning::DescribeMLModelsOutput> instance

  

Returns a list of C<MLModel> that match the search criteria in the
request.











=head2 GetBatchPrediction(BatchPredictionId => Str)

Each argument is described in detail in: L<Paws::MachineLearning::GetBatchPrediction>

Returns: a L<Paws::MachineLearning::GetBatchPredictionOutput> instance

  

Returns a C<BatchPrediction> that includes detailed metadata, status,
and data file information for a C<Batch Prediction> request.











=head2 GetDataSource(DataSourceId => Str, [Verbose => Bool])

Each argument is described in detail in: L<Paws::MachineLearning::GetDataSource>

Returns: a L<Paws::MachineLearning::GetDataSourceOutput> instance

  

Returns a C<DataSource> that includes metadata and data file
information, as well as the current status of the C<DataSource>.

C<GetDataSource> provides results in normal or verbose format. The
verbose format adds the schema description and the list of files
pointed to by the DataSource to the normal format.











=head2 GetEvaluation(EvaluationId => Str)

Each argument is described in detail in: L<Paws::MachineLearning::GetEvaluation>

Returns: a L<Paws::MachineLearning::GetEvaluationOutput> instance

  

Returns an C<Evaluation> that includes metadata as well as the current
status of the C<Evaluation>.











=head2 GetMLModel(MLModelId => Str, [Verbose => Bool])

Each argument is described in detail in: L<Paws::MachineLearning::GetMLModel>

Returns: a L<Paws::MachineLearning::GetMLModelOutput> instance

  

Returns an C<MLModel> that includes detailed metadata, and data source
information as well as the current status of the C<MLModel>.

C<GetMLModel> provides results in normal or verbose format.











=head2 Predict(MLModelId => Str, PredictEndpoint => Str, Record => Paws::MachineLearning::Record)

Each argument is described in detail in: L<Paws::MachineLearning::Predict>

Returns: a L<Paws::MachineLearning::PredictOutput> instance

  

Generates a prediction for the observation using the specified
C<MLModel>.

Not all response parameters will be populated because this is dependent
on the type of requested model.











=head2 UpdateBatchPrediction(BatchPredictionId => Str, BatchPredictionName => Str)

Each argument is described in detail in: L<Paws::MachineLearning::UpdateBatchPrediction>

Returns: a L<Paws::MachineLearning::UpdateBatchPredictionOutput> instance

  

Updates the C<BatchPredictionName> of a C<BatchPrediction>.

You can use the GetBatchPrediction operation to view the contents of
the updated data element.











=head2 UpdateDataSource(DataSourceId => Str, DataSourceName => Str)

Each argument is described in detail in: L<Paws::MachineLearning::UpdateDataSource>

Returns: a L<Paws::MachineLearning::UpdateDataSourceOutput> instance

  

Updates the C<DataSourceName> of a C<DataSource>.

You can use the GetDataSource operation to view the contents of the
updated data element.











=head2 UpdateEvaluation(EvaluationId => Str, EvaluationName => Str)

Each argument is described in detail in: L<Paws::MachineLearning::UpdateEvaluation>

Returns: a L<Paws::MachineLearning::UpdateEvaluationOutput> instance

  

Updates the C<EvaluationName> of an C<Evaluation>.

You can use the GetEvaluation operation to view the contents of the
updated data element.











=head2 UpdateMLModel(MLModelId => Str, [MLModelName => Str, ScoreThreshold => Num])

Each argument is described in detail in: L<Paws::MachineLearning::UpdateMLModel>

Returns: a L<Paws::MachineLearning::UpdateMLModelOutput> instance

  

Updates the C<MLModelName> and the C<ScoreThreshold> of an C<MLModel>.

You can use the GetMLModel operation to view the contents of the
updated data element.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

