import fastf1
from pathlib import Path
print("FastF1 version:", fastf1.__version__)

cache_dir = Path("fastf1_cache")
cache_dir.mkdir(exist_ok=True)
fastf1.Cache.enable_cache(str(cache_dir))

YEAR = 2026

# First inspect the 2026 event schedule so we use the exact FastF1 event name.
schedule = fastf1.get_event_schedule(YEAR)

print("\n2026 events containing Madrid or Spain:")
mask = (
    schedule["EventName"].astype(str).str.contains("Madrid|Spain", case=False, na=False)
    | schedule["Location"].astype(str).str.contains("Madrid", case=False, na=False)
)

cols = [
    c for c in
    ["RoundNumber", "EventName", "OfficialEventName", "Location", "EventDate"]
    if c in schedule.columns
]

print(schedule.loc[mask, cols].to_string(index=False))

matches = schedule.loc[mask]

if matches.empty:
    raise RuntimeError(
        "FastF1's 2026 event schedule does not currently contain a Madrid event."
    )

# Prefer an event physically located in Madrid.
madrid_matches = matches[
    matches["Location"].astype(str).str.contains("Madrid", case=False, na=False)
]

if not madrid_matches.empty:
    event = madrid_matches.iloc[0]
else:
    event = matches.iloc[0]

round_number = int(event["RoundNumber"])
event_name = str(event["EventName"])

print("\nSelected event:")
print("Round:", round_number)
print("Event:", event_name)

print("\nAttempting to load Practice 1...")

try:
    session = fastf1.get_session(YEAR, round_number, "FP1")
    session.load(
        laps=True,
        telemetry=True,
        weather=False,
        messages=False
    )
except Exception as exc:
    print("\nFAILED TO LOAD MADRID FP1")
    print(type(exc).__name__ + ":", exc)
    print(
        "\nThis may simply mean that the session data has not yet "
        "propagated to FastF1."
    )
    raise SystemExit(1)

print("\nSESSION LOADED SUCCESSFULLY")
print("Event:", session.event["EventName"])
print("Session:", session.name)
print("Date:", session.date)
print("Number of laps:", len(session.laps))

if session.laps.empty:
    print("\nThe session exists, but no lap data is currently available.")
    raise SystemExit(2)

# Find the fastest valid lap in the session.
valid_laps = session.laps.dropna(subset=["LapTime"])

if valid_laps.empty:
    print("\nNo timed laps are currently available.")
    raise SystemExit(3)

fastest = valid_laps.pick_fastest()

print("\nFASTEST AVAILABLE LAP")
print("Driver:", fastest["Driver"])
print("Lap number:", fastest["LapNumber"])
print("Lap time:", fastest["LapTime"])

try:
    telemetry = fastest.get_telemetry().add_distance()
except Exception as exc:
    print("\nLap exists, but telemetry could not be retrieved.")
    print(type(exc).__name__ + ":", exc)
    raise SystemExit(4)

print("\nTELEMETRY VALIDATION")
print("Samples:", len(telemetry))
print("Channels:")
print(list(telemetry.columns))

if "Speed" in telemetry.columns:
    print("Minimum speed:", telemetry["Speed"].min(), "km/h")
    print("Maximum speed:", telemetry["Speed"].max(), "km/h")

if "Distance" in telemetry.columns:
    print("Telemetry distance:", telemetry["Distance"].max(), "m")

# Export only useful channels that are actually present.
import pandas as pd

t0 = telemetry["Time"].dt.total_seconds().iloc[0]
out = pd.DataFrame({
    "time":     telemetry["Time"].dt.total_seconds() - t0,
    "distance": telemetry["Distance"],
    "speed":    telemetry["Speed"],
    "throttle": telemetry["Throttle"],
    "brake":    telemetry["Brake"].astype(int),
    "rpm":      telemetry["RPM"],
    "gear":     telemetry["nGear"],
    "drs":      telemetry["DRS"],
    "x": telemetry["X"], "y": telemetry["Y"], "z": telemetry["Z"],
})

filename = f"madring_2026_FP1_{fastest['Driver']}_lap{int(fastest['LapNumber'])}.csv"
out.to_csv(filename, index=False)

print("\nSUCCESS")
print("Exported:", filename)
print("Rows:", len(out))
print(f"Speed {out.speed.min():.0f}-{out.speed.max():.0f} km/h | "
      f"Distance {out.distance.max():.1f} m")
print(f"\nIn runMadringStudy.m set:\n    T = loadMadringTelemetry('{filename}');")