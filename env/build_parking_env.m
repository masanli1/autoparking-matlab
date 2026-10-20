% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function env = build_parking_env(cfg)
%BUILD_PARKING_ENV  Build the occupancy grid and slot metadata.
%
%   env = build_parking_env(cfg)
%
%   Layout (metres, x right, y up):
%
%     y = 16.2 .. 18.0   solid back wall
%     y = 11.0 .. 16.2   top row of 8 perpendicular slots (2.8 m pitch)
%     y =  3.5 .. 11.0   free manoeuvring aisle (7.5 m wide)
%     y =  0.0 ..  3.5   solid wall / building block
%
%   The target slot is left empty; all other slots are occupied by parked
%   cars.  A wide aisle is deliberate: it gives the front corner of a 4.5 m
%   car enough room to swing while reversing into the slot.

env.cfg   = cfg;
env.res   = cfg.map.res;
env.xlim  = cfg.map.xlim;
env.ylim  = cfg.map.ylim;
env.nx    = round((env.xlim(2) - env.xlim(1)) / env.res) + 1;
env.ny    = round((env.ylim(2) - env.ylim(1)) / env.res) + 1;
env.x     = env.xlim(1) + (0:env.nx-1) * env.res;
env.y     = env.ylim(1) + (0:env.ny-1) * env.res;
env.occ   = false(env.ny, env.nx);
env.veh   = cfg.veh;

% ------------------------------------------------------------- boundary --
env = add_rect(env, 0.0,  0.0, 0.30, 18.0);      % left wall
env = add_rect(env, 29.7, 0.0, 0.30, 18.0);      % right wall
env = add_rect(env, 0.0,  0.0, 30.0, 3.50);      % bottom building block
env = add_rect(env, 0.0, 16.2, 30.0, 1.80);      % back wall behind slots

% --------------------------------------------------------------- slots ---
top = cfg.slots.top;
top.y_back = top.y_entrance + top.depth;
env.slots.top = repmat(struct( ...
    'index', 0, 'x_center', 0, 'y_entrance', 0, 'depth', 0, ...
    'width', 0, 'y_back', 0, 'occupied', false), 1, top.count);

for i = 1:top.count
    xc = top.x_start + (i - 0.5) * top.width;
    env.slots.top(i).index      = i;
    env.slots.top(i).x_center   = xc;
    env.slots.top(i).y_entrance = top.y_entrance;
    env.slots.top(i).depth      = top.depth;
    env.slots.top(i).width      = top.width;
    env.slots.top(i).y_back     = top.y_back;
    env.slots.top(i).occupied   = (i ~= cfg.slots.target);
end

% Slot dividers (the two outer ones coincide with the side walls).
for k = 0:top.count
    xb = top.x_start + k * top.width;
    env = add_rect(env, xb - top.divider/2, top.y_entrance, top.divider, top.depth);
end

% ---------------------------------------------------------- parked cars --
for i = 1:top.count
    if i == cfg.slots.target
        continue;                       % keep the target slot free
    end
    xc = top.x_start + (i - 0.5) * top.width;
    yc = top.y_entrance + cfg.parked.inset + cfg.parked.length/2;
    env = add_rect(env, xc - cfg.parked.width/2, ...
                        yc - cfg.parked.length/2, ...
                        cfg.parked.width, cfg.parked.length);
end

% ------------------------------------------------------------- target ----
idx = cfg.slots.target;
slot.x_center   = env.slots.top(idx).x_center;
slot.y_entrance = env.slots.top(idx).y_entrance;
slot.depth      = env.slots.top(idx).depth;
slot.width      = env.slots.top(idx).width;
slot.y_back     = env.slots.top(idx).y_back;
slot.final_pose = [slot.x_center; ...
                   slot.y_back - cfg.veh.rear_overhang - cfg.slots.final_clearance; ...
                   -pi/2];
slot.final_pose(3) = -pi/2;             % reverse park: nose towards the aisle

env.target = slot;

% ------------------------------------------------------------- metadata --
env.aisle       = [0.30, 29.70, 3.50, 11.00];   % xmin xmax ymin ymax
env.free_start  = [0.80, 29.20, 5.60, 7.40];    % conservative start box
env.planning_ok = true;
end
