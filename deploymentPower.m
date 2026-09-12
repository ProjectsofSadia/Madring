function P = deploymentPower(v_kmh, p)
%DEPLOYMENTPOWER  FIA Art. C5.2.7 deployment taper (W).
%   P(kW) = 1800 - 5*v(km/h) up to 340 km/h, capped at the 350 kW ceiling,
%   falling to zero at 345 km/h.
    P = min(p.P_max_ERSK, max(0, (1800 - 5*v_kmh)*1e3));
    P(v_kmh >= p.v_taper_end) = 0;
end
