use serde::Deserialize;

#[derive(Deserialize, Debug)]
pub struct Metric {
    pub name: String,
    pub prefix: Option<String>,
    value: String,
    uom: Option<String>,
    min: Option<f32>,
    max: Option<f32>,
}

#[derive(Deserialize, Debug)]
pub struct Compute {
    pub metrics: Vec<Metric>,
    pub aggregations: Option<Vec<Metric>>,
}
