function [sig, ev] = buildPowerSignals(T, ev, p)
%BUILDPOWERSIGNALS Convert telemetry-derived deceleration into a simplified
%electrical-recovery estimate.
%
% The calculation intentionally separates measured/derived quantities from
% modeled assumptions. Kinetic-energy reduction is not called regenerated energy.

    t = T.time(:); d = T.distance(:); v = T.speed(:)/3.6;
    n = numel(t);
    P_rear = zeros(n,1);

    isBrakeSample = false(n,1);
    for k = 1:numel(ev)
        isBrakeSample(ev(k).i0:max(ev(k).i1-1,ev(k).i0)) = true;
    end

    for i = 1:n-1
        dt = t(i+1)-t(i);
        if dt <= 0 || ~isBrakeSample(i), continue; end

        vm = 0.5*(v(i)+v(i+1));
        ds = max(d(i+1)-d(i),0);
        P_dec = max(0.5*p.mass*(v(i)^2-v(i+1)^2)/dt,0);

        % Remove modeled aerodynamic and rolling losses before applying the
        % rear-axle availability and aggregate electrical efficiency assumptions.
        F_drag = 0.5*p.rho*p.CdA*vm^2;
        F_roll = p.Crr*p.mass*p.g;
        P_res = (F_drag+F_roll)*ds/dt;
        P_mech_available = max(P_dec-P_res,0);
        P_rear(i) = P_mech_available*p.rear_frac*p.eta_regen;
    end

    sig.time = t;
    sig.distance = d;
    sig.speed = T.speed(:);
    sig.brake = double(T.brake(:)>0);
    sig.P_rear = P_rear;

    for k = 1:numel(ev)
        idx = ev(k).i0:max(ev(k).i1-1,ev(k).i0);
        idx = idx(idx < n);
        if isempty(idx), continue; end
        dts = t(idx+1)-t(idx);
        Pk = P_rear(idx);
        Pc = min(Pk,p.P_max_ERSK);
        ev(k).P_peak_unclipped = max(Pk);
        ev(k).E_recoverable = sum(Pc.*dts);
        ev(k).E_lost_to_ceiling = sum((Pk-Pc).*dts);
        ev(k).t_above_350kW = sum(dts(Pk>p.P_max_ERSK));
    end

    total = sum([ev.E_recoverable]);
    for k = 1:numel(ev)
        if total > 0, ev(k).pct_of_lap = 100*ev(k).E_recoverable/total;
        else, ev(k).pct_of_lap = 0; end
    end
end
