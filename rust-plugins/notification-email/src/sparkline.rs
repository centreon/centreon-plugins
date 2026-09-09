//! Prototype: renders a line-chart PNG from the REST API v2 performance-metrics
//! CSV, as an alternative to `graph.rs`'s PNG fetched via the legacy
//! `generateImage.php` auto-login key.
//!
//! Unlike `generateImage.php`, `/monitoring/hosts/{id}/services/{id}/metrics/performance/download`
//! authenticates with a normal REST API v2 token (`X-AUTH-TOKEN`), which can
//! be revoked/expired independently - the whole point of this experiment.
//! No REST API v2 endpoint returns a rendered image, only a semicolon-CSV of
//! raw samples, so the chart is rendered here with `plotters` instead - a
//! real line, not the bulletproof-HTML bar chart this module started as
//! (kept only as discrete bars, since Outlook's Word engine renders neither
//! SVG nor smooth CSS curves; a real image is the only way to get an actual
//! line for every mail client, same delivery mechanism as `graph.rs`).
//! Plots every metric column in the CSV, not just the first (e.g. a service
//! with `load1`/`load5`/`load15` gets three lines, like the RRDtool original).

use std::io::Read;
use std::sync::Once;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

/// `ab_glyph` (the pure-Rust rasterizer behind plotters' text rendering, used
/// so this stays a single self-contained binary) does no fontconfig-style
/// system font discovery - it needs the font bytes registered explicitly, or
/// every text draw call fails with `FontUnavailable`, even with system fonts
/// installed. Bundled font: DejaVu Sans (Bitstream Vera + public-domain
/// additions license, redistribution permitted), `assets/DejaVuSans.ttf`.
static REGISTER_FONT: Once = Once::new();
const FONT_BYTES: &[u8] = include_bytes!("../assets/DejaVuSans.ttf");

fn ensure_font_registered() {
    REGISTER_FONT.call_once(|| {
        if plotters::style::register_font("sans-serif", plotters::style::FontStyle::Normal, FONT_BYTES).is_err() {
            log::warn!("failed to register bundled font");
        }
    });
}

pub enum SparklineOutcome {
    /// `--api-token` was not provided: this feature is opt-in.
    NotConfigured,
    Error(String),
    Found(Vec<u8>),
}

/// A short trend window suits a just-fired notification better than a full
/// day: at 24h the interesting spike that triggered the alert gets crushed
/// against the right edge of the chart, one pixel wide.
const LOOKBACK_SECS: u64 = 2 * 3600;
const CHART_WIDTH: u32 = 640;
const CHART_HEIGHT: u32 = 260;
const LEGEND_ROW_HEIGHT: u32 = 20;

/// Centreon-ish palette, cycled if there are more metrics than colors.
const PALETTE: &[(u8, u8, u8)] = &[
    (0, 145, 202),   // blue
    (0, 166, 90),    // green
    (255, 140, 0),   // orange
    (224, 0, 43),    // red
    (128, 82, 204),  // purple
    (0, 172, 193),   // teal
];

struct Sample {
    humantime: String,
    values: Vec<f64>,
}

pub fn fetch(
    centreon_url: &str,
    url_path: &str,
    api_token: Option<&str>,
    host_id: &str,
    service_id: &str,
    timeout_secs: u64,
    insecure: bool,
) -> SparklineOutcome {
    let Some(token) = api_token.filter(|t| !t.is_empty()) else {
        return SparklineOutcome::NotConfigured;
    };

    let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap_or_default().as_secs();
    let start = now.saturating_sub(LOOKBACK_SECS);

    let url = format!(
        "{centreon_url}{url_path}/api/latest/monitoring/hosts/{host_id}/services/{service_id}/metrics/performance/download?start_date=@{start}&end_date=@{now}"
    );

    let mut builder = ureq::AgentBuilder::new().timeout(Duration::from_secs(timeout_secs));
    if insecure {
        builder = builder.tls_config(std::sync::Arc::new(crate::graph::insecure_tls_config()));
    }
    let agent = builder.build();
    let response = match agent.get(&url).set("X-AUTH-TOKEN", token).call() {
        Ok(r) => r,
        Err(e) => {
            log::warn!("sparkline fetch failed for {url}: {e}");
            return SparklineOutcome::Error("metrics API unreachable".to_string());
        }
    };

    if response.status() != 200 {
        return SparklineOutcome::Error(format!("metrics API returned HTTP {}", response.status()));
    }

    let mut body = String::new();
    if response.into_reader().read_to_string(&mut body).is_err() {
        return SparklineOutcome::Error("could not read metrics API response".to_string());
    }

    // Header row: time;humantime;<metric1>;<metric2>;... - every metric column after the first two.
    let mut lines = body.lines();
    let metric_names: Vec<String> = lines
        .next()
        .map(|header| header.split(';').skip(2).map(str::to_string).collect())
        .unwrap_or_default();

    if metric_names.is_empty() {
        return SparklineOutcome::Error("no metric columns in response".to_string());
    }

    let samples: Vec<Sample> = lines
        .filter_map(|line| {
            let mut cols = line.split(';');
            let _time = cols.next()?;
            let humantime = cols.next()?.trim_matches('"').to_string();
            let values: Vec<f64> = cols.map(|c| c.trim().parse::<f64>().unwrap_or(f64::NAN)).collect();
            if values.len() != metric_names.len() {
                return None;
            }
            Some(Sample { humantime, values })
        })
        .collect();

    if samples.is_empty() {
        return SparklineOutcome::Error("no data points in range".to_string());
    }

    match render_png(&metric_names, &samples) {
        Ok(bytes) => SparklineOutcome::Found(bytes),
        Err(e) => SparklineOutcome::Error(format!("chart render failed: {e}")),
    }
}

/// Renders a real (possibly multi-line) chart to PNG bytes via `plotters`,
/// writing to a process-unique temp file (plotters' `BitMapBackend` only
/// PNG-encodes when given a file path, not an in-memory buffer) and reading
/// it back.
fn render_png(metric_names: &[String], samples: &[Sample]) -> Result<Vec<u8>, String> {
    use plotters::prelude::*;

    ensure_font_registered();

    let tmp_path = std::env::temp_dir().join(format!(
        "centreon-notif-email-sparkline-{}-{}.png",
        std::process::id(),
        SystemTime::now().duration_since(UNIX_EPOCH).unwrap_or_default().as_nanos()
    ));

    let legend_height = LEGEND_ROW_HEIGHT * metric_names.len() as u32 + 8;

    let render = || -> Result<(), String> {
        let root = BitMapBackend::new(&tmp_path, (CHART_WIDTH, CHART_HEIGHT + legend_height)).into_drawing_area();
        root.fill(&WHITE).map_err(|e| e.to_string())?;
        let (chart_area, legend_area) = root.split_vertically(CHART_HEIGHT);

        // Per-metric series, extracted column-wise so a NaN sample in one
        // metric doesn't drop that timestamp from the others.
        let series: Vec<Vec<f64>> = (0..metric_names.len())
            .map(|m| samples.iter().map(|s| s.values[m]).collect())
            .collect();

        let global_min = series.iter().flatten().cloned().filter(|v| v.is_finite()).fold(f64::MAX, f64::min);
        let global_max = series.iter().flatten().cloned().filter(|v| v.is_finite()).fold(f64::MIN, f64::max);
        let pad = ((global_max - global_min) * 0.15).max(0.5);
        let last_idx = samples.len().saturating_sub(1).max(1);

        let title = metric_names.join(" / ");
        let mut chart = ChartBuilder::on(&chart_area)
            .caption(title, ("sans-serif", 16))
            .margin(10)
            .set_label_area_size(LabelAreaPosition::Left, 55)
            .set_label_area_size(LabelAreaPosition::Bottom, 35)
            .build_cartesian_2d(0..last_idx, (global_min - pad)..(global_max + pad))
            .map_err(|e| e.to_string())?;

        chart
            .configure_mesh()
            .disable_x_mesh()
            .light_line_style(RGBColor(230, 230, 230))
            .axis_style(RGBColor(180, 180, 180))
            .label_style(("sans-serif", 11))
            .x_labels(6)
            .x_label_formatter(&|idx| {
                samples.get(*idx).map(|s| {
                    // "2026-09-08 04:40:28" -> "04:40" (drop date and seconds, keep HH:MM).
                    s.humantime.split_whitespace().nth(1).and_then(|t| t.get(0..5)).unwrap_or(&s.humantime).to_string()
                }).unwrap_or_default()
            })
            .y_labels(5)
            .y_label_formatter(&|v| format!("{v:.0}"))
            .draw()
            .map_err(|e| e.to_string())?;

        for (m, values) in series.iter().enumerate() {
            let (r, g, b) = PALETTE[m % PALETTE.len()];
            let color = RGBColor(r, g, b);
            chart
                .draw_series(LineSeries::new(
                    values.iter().enumerate().filter(|(_, v)| v.is_finite()).map(|(i, v)| (i, *v)),
                    color.stroke_width(2),
                ))
                .map_err(|e| e.to_string())?;
        }

        // Legend strip below the chart: one row per metric - color swatch,
        // name, Last/Min/Max/Avg - mirroring the stats block under
        // generateImage.php's RRDtool graphs.
        for (m, (name, values)) in metric_names.iter().zip(series.iter()).enumerate() {
            let (r, g, b) = PALETTE[m % PALETTE.len()];
            let color = RGBColor(r, g, b);
            let finite: Vec<f64> = values.iter().cloned().filter(|v| v.is_finite()).collect();
            let min = finite.iter().cloned().fold(f64::MAX, f64::min);
            let max = finite.iter().cloned().fold(f64::MIN, f64::max);
            let last = finite.last().copied().unwrap_or(0.0);
            let avg = if finite.is_empty() { 0.0 } else { finite.iter().sum::<f64>() / finite.len() as f64 };
            let y = m as i32 * LEGEND_ROW_HEIGHT as i32;

            legend_area
                .draw(&Rectangle::new([(10, y + 6), (24, y + 18)], color.filled()))
                .map_err(|e| e.to_string())?;
            legend_area
                .draw(&Text::new(
                    format!("{name}   Last: {last:.2}   Min: {min:.2}   Max: {max:.2}   Avg: {avg:.2}"),
                    (30, y + 4),
                    ("sans-serif", 13).into_font(),
                ))
                .map_err(|e| e.to_string())?;
        }

        root.present().map_err(|e| e.to_string())?;
        Ok(())
    };

    let result = render();
    let bytes = std::fs::read(&tmp_path);
    let _ = std::fs::remove_file(&tmp_path);

    result?;
    bytes.map_err(|e| e.to_string())
}
