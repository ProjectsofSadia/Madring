% RUNMADRINGSTUDY
% MADRING regenerative-braking analysis using public FP1 telemetry.
%
% Scope: one timed lap (RUS lap 20, FP1) as a reproducible case study.
% Measured/public: speed, throttle, brake, RPM, gear, DRS, position and time.
% Derived: braking-event boundaries, speed loss and kinetic-energy reduction.
% Modeled: MGU-K electrical recovery and Energy Store behavior.
%
% Generate the telemetry CSV first:
%   python fetch_madring_session.py

clear; clc; close all;

p = madringParams();
csvFile = 'madring_2026_FP1_RUS_lap20.csv';
if ~isfile(csvFile)
    error(['Telemetry CSV not found. Run "python fetch_madring_session.py" first. ' ...
           'The generated CSV is intentionally excluded from Git.']);
end

T = loadMadringTelemetry(csvFile);
ev = detectBrakingEvents(T, p);
[sig, ev] = buildPowerSignals(T, ev, p);

% Labels are assigned after telemetry-based event detection. They are only
% descriptive labels for the detected distance windows; they do not drive detection.
labels = {'T1','T5','T6-T7 Carcavas','T13 La Monumental', ...
          'T17','T20','T21','T22 El Parque'};
if numel(labels) == numel(ev)
    for k = 1:numel(ev)
        ev(k).corner = labels{k};
    end
else
    for k = 1:numel(ev)
        ev(k).corner = sprintf('event @ %.0f m', ev(k).d_start);
    end
end

fprintf('\n%-22s %8s %6s %6s %6s %8s %9s %8s\n', ...
    'Braking zone','dist m','v_in','v_min','dur','dKE MJ','E_rec MJ','% lap');
fprintf('%s\n', repmat('-',1,82));
for k = 1:numel(ev)
    e = ev(k);
    fprintf('%-22s %8.0f %6.0f %6.0f %6.2f %8.3f %9.3f %8.1f\n', ...
        e.corner, e.d_start, e.v_entry, e.v_min, e.duration, ...
        e.dKE/1e6, e.E_recoverable/1e6, e.pct_of_lap);
end

totalDKE = sum([ev.dKE]);
totalRecovery = sum([ev.E_recoverable]);
fprintf('%s\n', repmat('-',1,82));
fprintf('Detected events                    : %d\n', numel(ev));
fprintf('Kinetic-energy reduction           : %.3f MJ\n', totalDKE/1e6);
fprintf('Modeled recoverable electrical     : %.3f MJ\n', totalRecovery/1e6);
fprintf('Modeled recovery / kinetic-energy  : %.1f %%\n', 100*totalRecovery/totalDKE);
fprintf('Energy clipped by 350 kW ceiling   : %.3f MJ\n', sum([ev.E_lost_to_ceiling])/1e6);

% Sensitivity: test whether the recovery ranking survives plausible changes
% to development assumptions rather than treating one parameter set as truth.
sweepAssumptions(T, p);

% Independent Simulink implementation for an internal consistency check.
% Agreement between MATLAB and Simulink is not validation against a real F1 ERS.
if license('test','Simulink')
    buildRegenSimulink(p);
    out = runSimulinkRegen(sig, p); %#ok<NASGU>
else
    fprintf('\nSimulink not available; MATLAB analysis completed.\n');
end

makeMainFigure(sig, ev, p, 'MADRING_regen_main.png');

% Ranked recovery figure used in the public project summary.
[~, ord] = sort([ev.E_recoverable], 'ascend');
figure('Color','w','Position',[100 100 1000 520]);
b = barh(categorical({ev(ord).corner}, {ev(ord).corner}), ...
         [ev(ord).E_recoverable]/1e6, 'FaceColor','flat');
base = [0.604 0.647 0.694]; red = [0.784 0.063 0.180];
b.CData = repmat(base, numel(ord), 1);
[~, desc] = sort([ev(ord).E_recoverable], 'descend');
b.CData(desc(1:min(3,numel(desc))),:) = repmat(red,min(3,numel(desc)),1);
xlabel('Estimated recoverable energy (MJ)');
title('Regenerative Energy by Braking Zone');
subtitle('MADRING FP1 | RUS Lap 20 | modeled electrical recovery');
grid on;
exportgraphics(gcf,'MADRING_ranked_bar.png','Resolution',300);
