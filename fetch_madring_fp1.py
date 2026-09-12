
import fastf1, pandas as pd, numpy as np

SESSION      = 'FP1'     # <-- 'FP1', 'FP2', 'FP3', 'Q' or 'R'
TRACK_LENGTH = 5416.0    # m, official MADRING length
MIN_SAMPLES  = 600
MIN_COVERAGE = 0.98      # fraction of official lap distance
MIN_GAP_M    = 150.0     # min distance to car ahead (traffic filter)
MAX_BRAKE_DT = 0.50      # s, largest tolerated sampling gap inside braking

fastf1.Cache.enable_cache('./ff1cache')
s = fastf1.get_session(2026, 'Madrid', SESSION)
s.load(laps=True, telemetry=True, weather=False, messages=False)
print(f"Session : {s.name} | {s.date}")
print(f"Drivers : {len(s.laps['Driver'].unique())}")

laps = s.laps.pick_wo_box().dropna(subset=['LapTime']).sort_values('LapTime')


def evaluate(lap):
    """Return (telemetry, diagnostics) or (None, reason)."""
    try:
        tel = lap.get_telemetry().add_distance()
    except Exception as e:
        return None, {'fail': f'telemetry error: {e}'}

    n = len(tel)
    if n < MIN_SAMPLES:
        return None, {'fail': f'only {n} samples'}

    dist = tel['Distance'].max()
    cov = dist / TRACK_LENGTH
    if cov < MIN_COVERAGE:
        return None, {'fail': f'coverage {cov:.1%}'}

    t = tel['Time'].dt.total_seconds().to_numpy()
    dt = np.diff(t)
    br = tel['Brake'].to_numpy().astype(bool)[:-1]
    dropouts = int(np.sum((dt > MAX_BRAKE_DT) & br))
    if dropouts > 0:
        return None, {'fail': f'{dropouts} dropout(s) in braking'}

    gap = pd.to_numeric(tel.get('DistanceToDriverAhead'), errors='coerce')
    min_gap = float(np.nanmin(gap)) if gap is not None and gap.notna().any() else np.inf
    if min_gap < MIN_GAP_M:
        return None, {'fail': f'traffic, {min_gap:.0f} m to car ahead'}

    return tel, {'n': n, 'cov': cov, 'min_gap': min_gap,
                 'vmax': tel['Speed'].max(), 'vmin': tel['Speed'].min()}


chosen = None
print("\nEvaluating laps fastest-first:")
for _, lap in laps.head(15).iterrows():
    tel, d = evaluate(lap)
    tag = f"  {lap['Driver']:4s} L{int(lap['LapNumber']):<3d} {lap['LapTime'].total_seconds():7.3f}s"
    if tel is None:
        print(f"{tag}  REJECT - {d['fail']}")
        continue
    print(f"{tag}  ACCEPT - {d['n']} samples, {d['cov']:.1%} coverage, "
          f"{d['min_gap']:.0f} m clear, {d['vmin']:.0f}-{d['vmax']:.0f} km/h")
    chosen = (lap, tel)
    break

if chosen is None:
    raise SystemExit("\nNo lap passed the gates. Loosen MIN_GAP_M or MAX_BRAKE_DT "
                     "and re-run, but say so in the write-up.")

lap, tel = chosen
drv, lnum = lap['Driver'], int(lap['LapNumber'])
print(f"\nSELECTED: {drv} lap {lnum}, {lap['LapTime'].total_seconds():.3f} s")

t0 = tel['Time'].dt.total_seconds().iloc[0]
out = pd.DataFrame({
    'time':     tel['Time'].dt.total_seconds() - t0,
    'distance': tel['Distance'],
    'speed':    tel['Speed'],
    'throttle': tel['Throttle'],
    'brake':    tel['Brake'].astype(int),
    'rpm':      tel['RPM'],
    'gear':     tel['nGear'],
    'drs':      tel['DRS'],
    'x': tel['X'], 'y': tel['Y'], 'z': tel['Z'],
})

fname = f"madring_{SESSION}_{drv}_lap{lnum}.csv"
out.to_csv(fname, index=False)
print(f"Wrote {fname}: {len(out)} samples | "
      f"speed {out.speed.min():.0f}-{out.speed.max():.0f} km/h | "
      f"distance {out.distance.max():.1f} m")
print(f"\nIn runMadringStudy.m set:\n    T = loadMadringTelemetry('{fname}');")