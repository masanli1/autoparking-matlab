% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function out = plan_approach(env, start, cfg)
%PLAN_APPROACH  Forward path from the current pose to the reverse staging pose.
%
%   out = plan_approach(env, start, cfg)
%
%   The staging pose is fixed for the selected slot:
%
%       left  approach: stage = [xs + R, ye - R, 0]
%       right approach: stage = [xs - R, ye - R, pi]
%
%   with R = cfg.ctrl.reverse_radius.  Starting from the car's current lane
%   (which may be a little above or below the staging lane), the forward
%   path is a cubic Hermite that ends exactly on the staging pose.  The car
%   then reverses along a quarter circle and a straight line into the slot.

out.ok    = false;
out.side  = 0;
out.R     = 0;
out.stage = [];
out.path  = [];
out.msg   = '';

veh = cfg.veh;
xs  = env.target.x_center;
ye  = env.target.y_entrance;

R    = cfg.ctrl.reverse_radius;
Rmin = veh.wheelbase / tan(veh.max_steer);

if R < Rmin + 0.40
    out.msg = sprintf('reverse radius %.2f m is too close to the minimum %.2f m', R, Rmin);
    return;
end

stage_y = ye - R;
h = wrap_pi(start(3));
if abs(h) <= pi/2
    side  = 1;
    stage = [xs + R; stage_y; 0];
else
    side  = -1;
    stage = [xs - R; stage_y; pi];
end

% The staging pose must be ahead of the car (the sampler guarantees this).
if side > 0 && stage(1) < start(1) + 0.50
    out.msg = 'staging pose is not ahead of the car (left approach)';
    return;
elseif side < 0 && stage(1) > start(1) - 0.50
    out.msg = 'staging pose is not ahead of the car (right approach)';
    return;
end

if stage(1) < 0.50 || stage(1) > 29.50
    out.msg = 'staging pose outside the map';
    return;
end

path = make_hermite_path(start(1:3), stage, ...
    max(120, ceil(abs(stage(1)-start(1)) / 0.08)));

[ok, bad] = validate_path_collision(env, path);
if ~ok
    out.msg = sprintf('forward path collides at sample %d', bad);
    return;
end

out.ok    = true;
out.side  = side;
out.R     = R;
out.stage = stage;
out.path  = path;
out.msg   = 'ok';
end
