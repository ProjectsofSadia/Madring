# Reproducing the MADRING analysis

## Requirements

- Python 3.10+
- `fastf1` 3.8+
- `pandas`
- MATLAB
- Simulink is optional; the MATLAB analysis runs without it

## 1. Fetch the public telemetry

From the repository root:

```bash
pip install -r requirements.txt
python fetch_madring_session.py
```

The script queries the 2026 schedule, selects the Madrid event, loads FP1, finds the fastest available timed lap and exports a MATLAB-friendly CSV. For the analysis documented here the selected lap was RUS lap 20, 1:34.077.

The generated telemetry CSV and FastF1 cache are intentionally ignored by Git.

## 2. Run the MATLAB study

Open MATLAB in the repository directory and run:

```matlab
runMadringStudy
```

The pipeline:

1. loads the telemetry extract;
2. detects significant braking events from the brake signal and speed trace;
3. derives speed loss and kinetic-energy reduction;
4. estimates rear-axle electrical recovery using documented development assumptions;
5. clips modeled recovery at the study's 350 kW electrical ceiling;
6. ranks the braking events by modeled recoverable energy;
7. runs a nine-case sensitivity sweep;
8. optionally rebuilds and runs the small Simulink implementation;
9. exports the two figures used in the project summary.

## 3. Interpret the output correctly

FastF1 provides the public telemetry channels. It does **not** provide actual MGU-K power, Energy Store SOC, recovered electrical energy, brake torque or a team's ERS strategy.

Therefore:

- speed, throttle, brake, RPM, gear, DRS, position and time are public telemetry;
- braking events and kinetic-energy reduction are derived;
- MGU-K recovery and Energy Store quantities are modeled.

MATLAB/Simulink agreement checks two implementations of the same simplified model. It is not validation against a Formula 1 team's measured energy system.
