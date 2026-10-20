% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function hit = check_vehicle_collision(env, pose, mode)
%CHECK_VEHICLE_COLLISION  Occupancy-grid collision test for the car body.
%
%   hit = check_vehicle_collision(env, pose, mode)
%
%   mode = 'fast'   ~130 sample points, used inside the control loop.
%   mode = 'dense'  ~0.15 m lattice, used when validating a planned path.
%
%   The body rectangle is enlarged by cfg.sim.margin before sampling so a
%   small safety buffer is included automatically.

if nargin < 3
    mode = 'fast';
end

veh = env.cfg.veh;
m   = env.cfg.sim.margin;

x_min = -veh.rear_overhang - m;
x_max =  veh.wheelbase + veh.front_overhang + m;
y_min = -veh.width/2 - m;
y_max =  veh.width/2 + m;

switch lower(mode)
    case 'dense'
        step = 0.15;
    otherwise
        step = 0.30;
end

xs = x_min:step:x_max;
ys = y_min:step:y_max;
if xs(end) < x_max, xs(end+1) = x_max; end
if ys(end) < y_max, ys(end+1) = y_max; end
[X, Y] = meshgrid(xs, ys);
local = [X(:)'; Y(:)'];

c = cos(pose(3));
s = sin(pose(3));
W = [c, -s; s, c] * local + pose(1:2);

% Outside the map is an obstacle.
if any(W(1,:) < env.xlim(1) | W(1,:) > env.xlim(2) | ...
       W(2,:) < env.ylim(1) | W(2,:) > env.ylim(2))
    hit = true;
    return;
end

cols = round((W(1,:) - env.xlim(1)) / env.res) + 1;
rows = round((W(2,:) - env.ylim(1)) / env.res) + 1;
cols = max(1, min(env.nx, cols));
rows = max(1, min(env.ny, rows));

hit = any(env.occ(sub2ind([env.ny, env.nx], rows, cols)));
end
