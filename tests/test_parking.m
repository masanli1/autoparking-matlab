% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function test_parking()
%TEST_PARKING  Unit and integration checks for the parking simulator.
%
%   Run with:  parking_main('mode','test')

root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root));

cfg = default_config();
cfg.vis.enabled = false;
cfg.sim.verbose = false;

env = build_parking_env(cfg);

% 1) Environment: the target slot is free, an occupied slot is blocked.
pose_target = [env.target.final_pose; 0];
assert(~check_vehicle_collision(env, pose_target, 'dense'), ...
    'target slot should be collision-free');

s1 = env.slots.top(1);
pose_parked = [s1.x_center; s1.y_entrance + s1.depth/2; 0; 0];
assert(check_vehicle_collision(env, pose_parked, 'dense'), ...
    'a parked slot should be occupied');

% 2) Kinematics: one second straight at 1 m/s.
S = [5; 6; 0; 0];
for k = 1:50
    S = vehicle_step(S, 0, 1.0, cfg.ctrl.dt, cfg.veh);
end
assert(abs(S(1) - 6.0) < 1e-6 && abs(S(2) - 6.0) < 1e-9, ...
    'straight-line kinematics are wrong');

% 3) Path planning: approach and reverse path both valid.
start = [3; 6.5; 0; 0];
ap = plan_approach(env, start, cfg);
assert(ap.ok, 'approach planning failed: %s', ap.msg);

rp = plan_reverse_path(env, ap.stage, ap.R, cfg);
assert(rp.ok, 'reverse planning failed: %s', rp.msg);
assert(norm(rp.path.P(:,end) - env.target.final_pose(1:2)) < 1e-9, ...
    'reverse path does not end at the target');
assert(abs(wrap_pi(rp.path.theta(end) + pi/2)) < 1e-9, ...
    'reverse path does not end perpendicular to the slot');

% 4) Full single run.
r = run_parking_sim(env, start, cfg, struct('keep_traj', true));
assert(r.success, 'single run failed: %s', r.msg);
assert(r.pos_err < 0.15 && r.head_err < deg2rad(3), ...
    'single run final pose is outside tolerance');

% 5) Small Monte Carlo smoke test.
rng(cfg.sim.seed, 'twister');
n = 20;
ok = false(n, 1);
for i = 1:n
    c = make_case(env, cfg);
    res = run_parking_sim(env, c.start, cfg, struct('keep_traj', false));
    ok(i) = res.success;
end
rate = mean(ok);
assert(rate >= 0.90, 'Monte Carlo smoke test success rate too low: %.1f%%', 100*rate);

fprintf('--------------------------------------------------\n');
fprintf('ALL TESTS PASSED\n');
fprintf('  single run     : pos=%.4f m, head=%.3f deg, t=%.1f s\n', ...
    r.pos_err, rad2deg(r.head_err), r.time);
fprintf('  smoke test     : %d/%d = %.1f%% success\n', sum(ok), n, 100*rate);
fprintf('--------------------------------------------------\n');
end
