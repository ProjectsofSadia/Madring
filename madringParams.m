function p = madringParams()
%MADRINGPARAMS  Every constant used in the study, tagged by provenance.
%
%  FIA_REGULATION      : 2026 F1 Regulations, Section C (Technical), Issue 17, 28/04/2026
%  ASSUMPTION          : no public F1 value exists. Swept in compareStrategies.m
%  ACADEMIC_REFERENCE  : taken from open battery literature, not an F1 specification
%
%  NOTE: FastF1 does NOT expose battery SOC, MGU-K power, regenerated energy,
%  battery temperature, brake torque or team ERS strategy. Everything electrical
%  in this study is MODELLED from measured speed / brake / throttle channels.

% ---------- FIA_REGULATION ----------
p.P_max_ERSK  = 350e3;   % W    Art. C5.2    absolute ERS-K DC power ceiling
p.ES_usable   = 4.0e6;   % J    Art. C5.2.8  max-minus-min state-of-charge delta
p.harvest_lap = 8.5e6;   % J    Art. C5.2.10 baseline per-lap harvest limit
p.v_taper_end = 345;     % km/h Art. C5.2.7  deployment power reaches zero here

% ---------- ASSUMPTION ----------
p.mass      = 800;    % kg    768 kg regulatory minimum + ~32 kg FP1 fuel
p.CdA       = 1.15;   % m^2   2026 low-drag regulations
p.Crr       = 0.015;  % -     rolling resistance coefficient
p.rear_frac = 0.40;   % -     share of braking force passing through the rear axle
p.eta_regen = 0.90;   % -     MGU-K generator x inverter x charge acceptance
p.thr_deploy= 95;     % %     throttle above which full deployment is assumed

% ---------- DERIVED ----------
p.rho = 1.09;   % kg/m^3  ~670 m elevation (MADRING low point 671 m), ~25 C
p.g   = 9.81;   % m/s^2

% ---------- DETECTION ----------
p.dv_min_kmh = 30;   % minimum speed drop for a "significant" braking event
p.bridge     = 2;    % samples of brake==0 bridged inside one event
end
