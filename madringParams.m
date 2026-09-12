function p = madringParams()
%MADRINGPARAMS Parameters used by the simplified recovery model.
%
% Keep regulatory constraints separate from development assumptions. FastF1
% does not expose actual MGU-K power, Energy Store SOC, brake torque, recovered
% energy or team ERS strategy, so electrical quantities are modeled.

% Electrical constraints used by this study. Verify against the current FIA
% 2026 Technical Regulations before reusing the values in another season.
p.P_max_ERSK = 350e3;  % W, modeled electrical power ceiling
p.ES_usable  = 4.0e6;  % J, Energy Store operating window used in the model

% Development assumptions. These are not claimed as team or supplier values.
p.mass      = 800;    % kg, effective vehicle mass for this case study
p.CdA       = 1.15;   % m^2, aerodynamic-loss assumption
p.Crr       = 0.015;  % rolling-resistance coefficient
p.rear_frac = 0.40;   % fraction of modeled mechanical deceleration available at rear axle
p.eta_regen = 0.90;   % aggregate generator/inverter/storage efficiency assumption

% Environment / constants.
p.rho = 1.09;  % kg/m^3, air-density assumption
p.g   = 9.81;  % m/s^2

% Event detection.
p.dv_min_kmh = 30;  % minimum speed reduction for a significant event
p.bridge     = 2;   % bridge short brake-signal gaps within one event
end
