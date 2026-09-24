//
// Copyright 2026-Present Centreon (http://www.centreon.com/)
//
// Centreon is a full-fledged industry-strength solution that meets
// the needs in IT infrastructure and application monitoring for
// service performance.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

extern crate criterion;

use criterion::{criterion_group, criterion_main, Criterion};
use std::hint::black_box;

fn average_for(v: &Vec<f64>) -> f64 {
    let mut sum = 0.0;
    let mut count = 0;

    for &x in v.iter() {
        if !x.is_nan() {
            sum += x;
            count += 1;
        }
    }

    if count == 0 {
        0.0
    } else {
        sum / count as f64
    }
}

fn average_fold(v: &Vec<f64>) -> f64 {
    let (sum, count) = v
        .iter()
        .filter(|x| !x.is_nan())
        .fold((0.0, 0), |(s, c), &x| (s + x, c + 1));

    if count == 0 {
        0.0
    } else {
        sum / count as f64
    }
}

fn benchmark_averages(c: &mut Criterion) {
    let data: Vec<f64> = (0..100_000)
        .map(|i| if i % 1000 == 0 { f64::NAN } else { i as f64 })
        .collect();

    c.bench_function("average_for", |b| b.iter(|| average_for(black_box(&data))));

    c.bench_function("average_fold", |b| {
        b.iter(|| average_fold(black_box(&data)))
    });
}

criterion_group!(benches, benchmark_averages);
criterion_main!(benches);
