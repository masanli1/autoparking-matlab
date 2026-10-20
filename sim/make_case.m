% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function c = make_case(env, cfg)
%MAKE_CASE  Sample one random but feasible initial pose for the Monte Carlo run.
%
%   The car starts in the aisle aligned with one of the two approach
%   directions.  The approach side is chosen so that the staging pose is
%   always ahead of the car, which removes pointless U-turns from the test.

veh = cfg.veh;
xs  = env.target.x_center;
R   = cfg.ctrl.reverse_radius;

if R < veh.wheelbase / tan(veh.max_steer) + 0.40
    error('make_case: reverse radius is too small');
end

% Only choose approach sides for which the staging pose and the whole car
% body stay inside the map.  Central slots allow both sides; edge slots
% automatically fall back to the only feasible one.
body_half = max(veh.wheelbase + veh.front_overhang, veh.rear_overhang);
sides = [];
if xs + R - body_half >= 0.5 && xs + R + body_half <= 29.5
    sides(end+1) = 1; %#ok<AGROW>
end
if xs - R - body_half >= 0.5 && xs - R + body_half <= 29.5
    sides(end+1) = -1; %#ok<AGROW>
end
if isempty(sides)
    error('make_case: no feasible approach side for slot %d', cfg.slots.target);
end

for attempt = 1:200
    side = sides(randi(numel(sides)));    % +1 = from left, -1 = from right
    y0   = cfg.sim.start_y(1) + diff(cfg.sim.start_y) * rand;
    stage_x = xs + side * R;

    if side > 0
        x_hi = stage_x - 3.0;
        if x_hi <= cfg.sim.start_x(1) + 0.5
            continue;
        end
        x0 = cfg.sim.start_x(1) + (x_hi - cfg.sim.start_x(1)) * rand;
        theta0 = 0 + (rand - 0.5) * 2 * cfg.sim.heading_noise;
    else
        x_lo = stage_x + 3.0;
        if x_lo >= cfg.sim.start_x(2) - 0.5
            continue;
        end
        x0 = x_lo + (cfg.sim.start_x(2) - x_lo) * rand;
        theta0 = pi + (rand - 0.5) * 2 * cfg.sim.heading_noise;
    end

    delta0 = (rand - 0.5) * 2 * cfg.sim.steer_noise;
    S = [x0; y0; theta0; delta0];

    % Must be inside the aisle and collision-free.
    if x0 < env.free_start(1) || x0 > env.free_start(2) || ...
       y0 < env.free_start(3) || y0 > env.free_start(4)
        continue;
    end
    if ~check_vehicle_collision(env, S, 'dense')
        c = struct('start', S, 'side', side, 'y0', y0, 'R', R, ...
                   'stage_x', stage_x, 'attempts', attempt);
        return;
    end
end

error('make_case: could not sample a collision-free start pose');
end
