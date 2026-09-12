%RUNMADRINGSTUDY  Where Can a 2026 Hybrid Race Car Recover the Most Energy at MADRING?
% A MATLAB/Simulink study using real Madrid telemetry and simplified
% FIA-constrained regenerative-braking modeling.
%
% Run this file from the folder containing it.
clear; clc; close all;

p = madringParams();
T = loadMadringTelemetry('madring_2026_FP1_RUS_lap20.csv');
ev        = detectBrakingEvents(T, p);
[sig, ev] = buildPowerSignals(T, ev, p);

% --- corner labels: assigned AFTER detection, by matching distance to the
% --- official MADRING corner data. Detection itself assumes no corners.
labels = {'T1','T5 / 5A','T6-T7 Carcavas','T13 (exit La Monumental)', ...
          'T17','T20','T21','T22 El Parque'};
if numel(labels) == numel(ev)
    for k = 1:numel(ev), ev(k).corner = labels{k}; end
else
    for k = 1:numel(ev), ev(k).corner = sprintf('event @ %.0f m', ev(k).d_start); end
end

fprintf('\n%-26s %9s %6s %6s %6s %8s %8s %8s %7s\n', ...
    'Braking zone','dist (m)','v_in','v_min','dur','dKE MJ','350kW MJ','E_rec MJ','%% lap');
fprintf('%s\n', repmat('-',1,92));
for k = 1:numel(ev)
    e = ev(k);
    fprintf('%-26s %9.0f %6.0f %6.0f %6.2f %8.3f %8.3f %8.3f %7.1f\n', ...
        e.corner, e.d_start, e.v_entry, e.v_min, e.duration, ...
        e.dKE/1e6, e.cap_350kW/1e6, e.E_recoverable/1e6, e.pct_of_lap);
end
fprintf('%s\n', repmat('-',1,92));
fprintf('%-26s %9s %6s %6s %6s %8.3f %8s %8.3f %7s\n','LAP TOTAL','','','','', ...
    sum([ev.dKE])/1e6,'', sum([ev.E_recoverable])/1e6,'100.0');

fprintf('\nEnergy lost to the 350 kW ceiling : %.3f MJ\n', sum([ev.E_lost_to_ceiling])/1e6);
fprintf('Fraction of dKE reaching the store: %.1f %%\n', ...
    100*sum([ev.E_recoverable])/sum([ev.dKE]));
fprintf('Per-lap harvest allowance used    : %.1f %% of 8.5 MJ\n', ...
    100*sum([ev.E_recoverable])/p.harvest_lap);

S = compareStrategies(sig, p);
sweepAssumptions(T, p);

% --- Simulink (requires Simulink licence). Comment out if unavailable.
if license('test','Simulink')
    buildRegenSimulink(p);
    out = runSimulinkRegen(sig, p); %#ok<NASGU>
else
    fprintf('\nSimulink not available - MATLAB results above stand on their own.\n');
end

makeMainFigure(sig, ev, p, 'MADRING_regen_main.png');

% --- ranked bar chart
[~, ord] = sort([ev.E_recoverable],'ascend');
figure('Color','w','Position',[100 100 900 460]);
barh(categorical({ev(ord).corner}, {ev(ord).corner}), [ev(ord).E_recoverable]/1e6, ...
     'FaceColor',[0.604 0.647 0.694]);
xlabel('Estimated recoverable electrical energy (MJ)');
title('MADRING braking events ranked by recoverable energy, not by \DeltaKE');
grid on; exportgraphics(gcf,'MADRING_ranked_bar.png','Resolution',200);
