% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function S = vehicle_step(S, delta_cmd, v, dt, veh)
%VEHICLE_STEP  One explicit-Euler step of the rear-axle bicycle model.
%
%   S = vehicle_step(S, delta_cmd, v, dt, veh)
%   S = [x; y; theta; delta] (rear-axle centre).
%   v is the signed longitudinal speed (negative = reverse).

% Steering rate limit first, then absolute limit.
dmax = veh.max_steer_rate * dt;
d    = S(4) + max(-dmax, min(dmax, delta_cmd - S(4)));
d    = max(-veh.max_steer, min(veh.max_steer, d));

theta = S(3) + (v / veh.wheelbase) * tan(d) * dt;
theta = wrap_pi(theta);

S(1) = S(1) + v * cos(theta) * dt;
S(2) = S(2) + v * sin(theta) * dt;
S(3) = theta;
S(4) = d;
end
