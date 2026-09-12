function [sig, ev] = buildPowerSignals(T, ev, p)
%BUILDPOWERSIGNALS  Turn measured telemetry into the power signals the
%Simulink model consumes. This is where dKE stops being recoverable energy.
%
%  Three deductions, applied in order:
%   (1) aerodynamic drag + rolling resistance dissipate to air and tyres and
%       never reach the MGU-K. Scales with v^2, so it penalises fast corners most.
%   (2) only the REAR axle drives the MGU-K (MGU-H deleted for 2026). The front
%       brakes' share is unrecoverable.
%   (3) conversion losses, then the 350 kW ceiling applied INSTANTANEOUSLY
%       (clipping at the peak, not on the event average).

    t = T.time(:); d = T.distance(:); v = T.speed(:)/3.6; thr = T.throttle(:);
    n = numel(t);
    P_rear   = zeros(n,1);   % electrical power offered to the ES, before the ceiling
    P_deploy = zeros(n,1);   % assumed deployment demand

    isBrakeSample = false(n,1);
    for k = 1:numel(ev), isBrakeSample(ev(k).i0:max(ev(k).i1-1,ev(k).i0)) = true; end

    for i = 1:n-1
        dt = t(i+1) - t(i);
        if dt <= 0, continue; end
        vm = 0.5*(v(i) + v(i+1));
        ds = d(i+1) - d(i);
        if isBrakeSample(i)
            P_dec = 0.5*p.mass*(v(i)^2 - v(i+1)^2)/dt;                    % total decel
            P_res = (0.5*p.rho*p.CdA*vm^2 + p.Crr*p.mass*p.g)*ds/dt;      % (1)
            P_rear(i) = max(P_dec - P_res, 0) * p.rear_frac * p.eta_regen;% (2)(3)
        elseif thr(i) >= p.thr_deploy
            P_deploy(i) = deploymentPower(T.speed(i), p);
        end
    end

    sig.time     = t;
    sig.distance = d;
    sig.speed    = T.speed(:);
    sig.brake    = double(T.brake(:) > 0);
    sig.P_rear   = P_rear;
    sig.P_deploy = P_deploy;

    % per-event bookkeeping
    for k = 1:numel(ev)
        idx = ev(k).i0:max(ev(k).i1-1, ev(k).i0);
        idx = idx(idx < n);                      % guard: never index past the last sample
        if isempty(idx), idx = ev(k).i0; end
        dts = t(idx+1) - t(idx);
        Pk  = P_rear(idx);
        Pc  = min(Pk, p.P_max_ERSK);
        ev(k).P_peak_unclipped  = max(Pk);
        ev(k).cap_350kW         = p.P_max_ERSK * ev(k).duration;
        ev(k).E_recoverable     = sum(Pc  .* dts);
        ev(k).E_lost_to_ceiling = sum((Pk - Pc) .* dts);
        ev(k).t_above_350kW     = sum(dts(Pk > p.P_max_ERSK));
    end
    tot = sum([ev.E_recoverable]);
    for k = 1:numel(ev), ev(k).pct_of_lap = 100*ev(k).E_recoverable/tot; end
end
