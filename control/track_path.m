% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function [S, v, idx, done] = track_path(S, v, gear, idx, path, cfg, mode)
%TRACK_PATH  One control step along a pre-computed path.
%
%   [S, v, idx, done] = track_path(S, v, gear, idx, path, cfg, mode)
%
%   Controller:
%       delta = gear * ( atan(L*kappa)
%                        - k_theta * e_theta
%                        - k_lat   * e_lat )
%
%   The sign flip with the gear direction makes the same lateral/heading
%   feedback stable for both forward and reverse motion.  Speed is scheduled
%   from the remaining path length and integrated with an acceleration limit.

dt  = cfg.ctrl.dt;
veh = cfg.veh;

% ---- nearest path point (monotonic, local search window) ----------------
i0 = idx;
i1 = min(path.n, idx + 60);
dd = (path.P(1,i0:i1) - S(1)).^2 + (path.P(2,i0:i1) - S(2)).^2;
[~, k] = min(dd);
idx = i0 + k - 1;

% ---- path-relative errors ----------------------------------------------
e_theta = wrap_pi(S(3) - path.theta(idx));
n_hat   = [-sin(path.theta(idx)); cos(path.theta(idx))];
e_lat   = n_hat' * (S(1:2) - path.P(:,idx));
kappa   = path.kappa(idx);

% Feed-forward + heading term flip with the gear direction; the lateral
% term does not (steering right always moves the car right relative to the
% path, whether the car is driving forward or backward).
delta_cmd = gear * atan(veh.wheelbase * kappa) ...
          - gear * cfg.ctrl.k_theta * e_theta ...
          - cfg.ctrl.k_lat * e_lat;
delta_cmd = max(-veh.max_steer, min(veh.max_steer, delta_cmd));

% ---- speed profile ------------------------------------------------------
s_rem = path.s(end) - path.s(idx);
if s_rem < 0.30
    speed_scale = 0.60;
else
    speed_scale = 1.00;
end

if strcmpi(mode, 'forward')
    v_target = min(veh.max_speed, max(cfg.ctrl.min_speed, ...
                 speed_scale * cfg.ctrl.forward_gain * s_rem));
    v = move_toward(v, v_target, veh.accel * dt);
else
    v_target = -min(veh.max_rev_speed, max(cfg.ctrl.min_speed, ...
                 speed_scale * cfg.ctrl.reverse_gain * s_rem));
    v = move_toward(v, v_target, veh.accel * dt);
end

S = vehicle_step(S, delta_cmd, v, dt, veh);

done = (s_rem < 0.04);
if done
    v = 0;
end
end

function x = move_toward(x, target, step)
if x < target
    x = min(target, x + step);
else
    x = max(target, x - step);
end
end
