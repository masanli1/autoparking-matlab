% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function res = run_parking_sim(env, start, cfg, opts)
%RUN_PARKING_SIM  Complete forward-approach + reverse-park simulation.
%
%   res = run_parking_sim(env, start, cfg, opts)
%
%   State machine:
%       APPROACH -> SHIFT -> REVERSE -> PARKED
%
%   The car first follows a Hermite path to a staging pose, stops, selects
%   reverse gear, then tracks a quarter-circle + straight path backwards
%   into the target slot.  Success requires a collision-free run and a final
%   pose within cfg.mc.goal_pos_tol / cfg.mc.goal_head_tol.

if nargin < 4, opts = struct(); end
if ~isfield(opts, 'keep_traj'), opts.keep_traj = true; end
if ~isfield(opts, 'verbose'),   opts.verbose   = cfg.sim.verbose; end

veh = cfg.veh;
dt  = cfg.ctrl.dt;
max_steps = ceil(cfg.sim.max_time / dt);

S      = start(:);
if numel(S) < 4, S(4) = 0; end
v      = 0;
gear   = 1;
state  = 'APPROACH';
shift_t = 0;
collision = false;

res = struct();
res.ok        = false;
res.plan_ok   = false;
res.success   = false;
res.collision = false;
res.state     = state;
res.start     = S;
res.stage     = [];
res.side      = 0;
res.R         = 0;
res.pos_err   = NaN;
res.head_err  = NaN;
res.steps     = 0;
res.time      = 0;
res.traj      = S;
res.states    = {state};
res.gear_changes = 0;
res.msg       = '';

% ---------------------------------------------------------------- plan ---
ap = plan_approach(env, S, cfg);
if ~ap.ok
    res.msg = ['approach: ' ap.msg];
    return;
end

rp = plan_reverse_path(env, ap.stage, ap.R, cfg);
if ~rp.ok
    res.msg = ['reverse: ' rp.msg];
    res.stage = ap.stage;
    res.side  = ap.side;
    res.R     = ap.R;
    return;
end

res.plan_ok = true;
res.stage   = ap.stage;
res.side    = ap.side;
res.R       = ap.R;
res.apath   = ap.path;
res.rpath   = rp.path;

idx_a = 1;
idx_r = 1;

if opts.keep_traj
    traj   = zeros(4, max_steps);
    states = cell(1, max_steps);
    traj(:,1) = S;
    states{1} = state;
    ntraj = 1;
else
    traj = [];
    states = {};
    ntraj = 0;
end

% ---------------------------------------------------------------- loop ---
step = 1;
while step < max_steps
    % Collision check on the current pose before moving.
    if check_vehicle_collision(env, S, 'fast')
        collision = true;
        res.state = 'COLLISION';
        break;
    end

    switch state
        case 'APPROACH'
            [S, v, idx_a, done] = track_path(S, v, gear, idx_a, ap.path, cfg, 'forward');
            if done
                state = 'SHIFT';
                shift_t = 0;
                v = 0;
            end

        case 'SHIFT'
            v = 0;
            % Pre-steer to the feed-forward angle of the reverse arc while
            % the car is stationary.  Without this the steering-rate limit
            % makes the car lag the arc by several degrees at entry.
            delta_rev = -atan(veh.wheelbase * rp.path.kappa(1));
            S = vehicle_step(S, delta_rev, 0, dt, veh);
            shift_t = shift_t + dt;
            if shift_t >= cfg.ctrl.shift_time
                state = 'REVERSE';
                gear  = -1;
                res.gear_changes = res.gear_changes + 1;
                idx_r = 1;
            end

        case 'REVERSE'
            [S, v, idx_r, done] = track_path(S, v, gear, idx_r, rp.path, cfg, 'reverse');
            if done
                state = 'PARKED';
                v = 0;
            end

        case 'PARKED'
            break;
    end

    step = step + 1;

    if opts.keep_traj
        traj(:,step) = S;
        states{step} = state;
        ntraj = step;
    end

    if strcmp(state, 'PARKED')
        break;
    end
end

% --------------------------------------------------------------- result --
if collision
    res.state = 'COLLISION';
else
    res.state = state;
end
res.collision = collision;
res.steps     = step;
res.time      = step * dt;
res.final_pose = S;

if opts.keep_traj
    res.traj   = traj(:,1:ntraj);
    res.states = states(1:ntraj);
else
    res.traj   = S;
    res.states = {state};
end

res.pos_err  = norm(S(1:2) - env.target.final_pose(1:2));
res.head_err = abs(wrap_pi(S(3) - env.target.final_pose(3)));

res.success = strcmp(state, 'PARKED') && ~collision && ...
              res.pos_err <= cfg.mc.goal_pos_tol && ...
              res.head_err <= cfg.mc.goal_head_tol;

if res.success
    res.msg = 'parked';
elseif collision
    res.msg = 'collision';
elseif strcmp(state, 'PARKED')
    res.msg = 'parked but outside tolerance';
else
    res.msg = 'timeout / incomplete';
end

if opts.verbose
    fprintf('  sim: %-8s success=%d pos=%.3f head=%.2fdeg t=%.1fs\n', ...
        res.msg, res.success, res.pos_err, rad2deg(res.head_err), res.time);
end
end
