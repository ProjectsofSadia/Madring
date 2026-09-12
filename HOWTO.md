# How to run

## Option 1 - use the bundled lap (works immediately)
```matlab
cd mlab
runMadringStudy
```

## Option 2 - pull the lap yourself from FastF1 first (recommended for publication)
```bash
pip install fastf1 pandas
python fetch_madring_fp1.py     # overwrites madring_FP1_RUS_lap20.csv
```
then run `runMadringStudy` as above.

Option 2 gives you first-party provenance: "retrieved via FastF1" rather than
"retrieved via a GitHub archive of FastF1 output". Worth doing before you post.

## Files
| File | Role |
|---|---|
| `runMadringStudy.m` | master script - run this |
| `madringParams.m` | every constant, tagged FIA_REGULATION / ASSUMPTION / DERIVED |
| `loadMadringTelemetry.m` | reads and validates the CSV |
| `detectBrakingEvents.m` | finds braking events from the brake channel, no assumed corners |
| `buildPowerSignals.m` | drag, rear-axle and ceiling deductions - where dKE stops being recoverable |
| `deploymentPower.m` | FIA Art. C5.2.7 deployment taper |
| `buildRegenSimulink.m` | builds the Simulink model programmatically |
| `runSimulinkRegen.m` | pushes the real signals through Simulink |
| `compareStrategies.m` | Strategy A vs Strategy B |
| `sweepAssumptions.m` | sensitivity of the ranking to every assumed parameter |
| `makeMainFigure.m` | the publication figure |
| `EXPECTED_OUTPUT.txt` | checksum values to verify your run |

## Caveats I cannot remove for you
- These scripts are **untested**. I had no MATLAB or Octave available, so they are
  written defensively but not executed. Check against `EXPECTED_OUTPUT.txt`.
- `buildRegenSimulink.m` uses the programmatic Simulink API. Block library paths
  occasionally shift between releases; if `add_block` errors, the fix is usually the
  library path string, not the logic.
- The MATLAB path is the numerical reference. Simulink is there because the brief
  asked for it, and it reproduces the same answer rather than adding new information.
