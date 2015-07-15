package Paws::MachineLearning::Prediction {
  use Moose;
  has details => (is => 'ro', isa => 'Paws::MachineLearning::DetailsMap');
  has predictedLabel => (is => 'ro', isa => 'Str');
  has predictedScores => (is => 'ro', isa => 'Paws::MachineLearning::ScoreValuePerLabelMap');
  has predictedValue => (is => 'ro', isa => 'Num');
}
1;
