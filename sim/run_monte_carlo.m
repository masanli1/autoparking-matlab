% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function summary = run_monte_carlo(cfg, n, opts)
%RUN_MONTE_CARLO  Large batch validation of the complete parking controller.
%
%   summary = run_monte_carlo(cfg, n, opts)
%
%   Each case samples a new start pose in the aisle and runs the complete
%   APPROACH -> SHIFT -> REVERSE -> PARKED pipeline.  Results are written to
%   results/monte_carlo_<n>.csv and results/monte_carlo_<n>.mat.

if nargin < 2 || isempty(n), n = cfg.mc.cases; end
if nargin < 3, opts = struct(); end
if ~isfield(opts, 'plot'), opts.plot = cfg.vis.enabled; end
if ~isfield(opts, 'verbose'), opts.verbose = true; end

env = build_parking_env(cfg);
rng(cfg.sim.seed, 'twister');

outdir = cfg.vis.outdir;
if ~exist(outdir, 'dir'), mkdir(outdir); end

side       = zeros(n, 1);
y0         = zeros(n, 1);
R          = zeros(n, 1);
x0         = zeros(n, 1);
theta0     = zeros(n, 1);
success    = false(n, 1);
collision  = false(n, 1);
plan_ok    = false(n, 1);
pos_err    = nan(n, 1);
head_err   = nan(n, 1);
time_s     = nan(n, 1);
steps      = zeros(n, 1);
msg        = cell(n, 1);
samples    = {};

fprintf('================ Monte Carlo: %d cases ================\n', n);
t_start = tic;

for i = 1:n
    c = make_case(env, cfg);

    keep = (i <= 20);
    r = run_parking_sim(env, c.start, cfg, struct('keep_traj', keep, 'verbose', false));

    % Keep a trajectory for failures as well, so they can be inspected.
    if ~r.success && ~keep
        r = run_parking_sim(env, c.start, cfg, struct('keep_traj', true, 'verbose', false));
        keep = true;
    end

    side(i)      = c.side;
    y0(i)        = c.y0;
    R(i)         = c.R;
    x0(i)        = c.start(1);
    theta0(i)    = c.start(3);
    success(i)   = r.success;
    collision(i) = r.collision;
    plan_ok(i)   = r.plan_ok;
    pos_err(i)   = r.pos_err;
    head_err(i)  = r.head_err;
    time_s(i)    = r.time;
    steps(i)     = r.steps;
    msg{i}       = r.msg;

    if keep
        samples{end+1} = r; %#ok<AGROW>
    end

    if opts.verbose && (mod(i, 100) == 0 || i == n)
        elapsed = toc(t_start);
        eta = elapsed / i * (n - i);
        fprintf('  %4d/%4d | success %6.2f%% | %6.1fs elapsed | ETA %6.1fs\n', ...
            i, n, 100 * mean(success(1:i)), elapsed, eta);
    end
end

elapsed = toc(t_start);

% ------------------------------------------------------------- summary ---
summary = struct();
summary.n              = n;
summary.success_rate   = mean(success);
summary.collision_rate = mean(collision);
summary.plan_fail_rate = mean(~plan_ok);
summary.mean_time      = mean(time_s(success));
summary.mean_steps     = mean(steps(success));
if any(success)
    e_sorted = sort(pos_err(success));
    summary.mean_pos_err  = mean(e_sorted);
    summary.max_pos_err   = max(e_sorted);
    summary.p95_pos_err   = e_sorted(max(1, ceil(0.95 * numel(e_sorted))));
    summary.mean_head_err = mean(rad2deg(head_err(success)));
    summary.max_head_err  = max(rad2deg(head_err(success)));
else
    summary.mean_pos_err  = NaN;
    summary.max_pos_err   = NaN;
    summary.p95_pos_err   = NaN;
    summary.mean_head_err = NaN;
    summary.max_head_err  = NaN;
end
summary.wall_time      = elapsed;
summary.env            = env;
summary.cfg            = cfg;

fprintf('\n---------------- summary ----------------\n');
fprintf('cases            : %d\n', n);
fprintf('success          : %d (%.2f%%)\n', sum(success), 100*summary.success_rate);
fprintf('collision        : %d (%.2f%%)\n', sum(collision), 100*summary.collision_rate);
fprintf('planning failure : %d (%.2f%%)\n', sum(~plan_ok), 100*summary.plan_fail_rate);
fprintf('mean final error : %.4f m / %.3f deg\n', summary.mean_pos_err, summary.mean_head_err);
fprintf('max final error  : %.4f m / %.3f deg\n', summary.max_pos_err, summary.max_head_err);
fprintf('P95 final error  : %.4f m\n', summary.p95_pos_err);
fprintf('mean sim time    : %.1f s (%.0f steps)\n', summary.mean_time, summary.mean_steps);
fprintf('wall time        : %.2f s\n', elapsed);
fprintf('-----------------------------------------\n');

% ----------------------------------------------------------- table/CSV ---
T = table((1:n)', side, x0, y0, rad2deg(theta0), R, success, collision, ...
    plan_ok, pos_err, rad2deg(head_err), time_s, steps, msg, ...
    'VariableNames', {'case_id','side','x0_m','y0_m','theta0_deg','R_m', ...
    'success','collision','plan_ok','pos_err_m','head_err_deg','time_s','steps','message'});
csv_name = fullfile(outdir, sprintf('monte_carlo_%d.csv', n));
writetable(T, csv_name);

mat_name = fullfile(outdir, sprintf('monte_carlo_%d.mat', n));
save(mat_name, 'summary', 'T', 'samples', '-v7.3');

% --------------------------------------------------------------- plots ---
if opts.plot
    plot_summary(env, T, summary, samples, outdir, n);
end

summary.csv_file = csv_name;
summary.mat_file = mat_name;
end

% =========================================================================
function plot_summary(env, T, summary, samples, outdir, n)
%PLOT_SUMMARY  Three diagnostic figures for the batch run.

% 1) start positions, success/failure
fig1 = figure('Color','w','Position',[80 80 1000 650]);
ax = axes(fig1);
plot_environment(env, ax);
ok = T.success;
h_ok = scatter(ax, T.x0_m(ok), T.y0_m(ok), 18, [0.1 0.7 0.2], 'filled', 'MarkerFaceAlpha', 0.55);
h_bad = [];
if any(~ok)
    h_bad = scatter(ax, T.x0_m(~ok), T.y0_m(~ok), 45, 'r', 'x', 'LineWidth', 1.8);
end
title(ax, sprintf('Start poses: %d/%d success (%.2f%%)', sum(ok), height(T), 100*summary.success_rate));
if isempty(h_bad)
    legend(ax, h_ok, {'success'}, 'Location','northoutside');
else
    legend(ax, [h_ok h_bad], {'success','failure'}, 'Location','northoutside');
end
exportgraphics(fig1, fullfile(outdir, sprintf('mc_%d_starts.png', n)), 'Resolution', 130);

% 2) error / time histograms
fig2 = figure('Color','w','Position',[80 80 1200 380]);
tiledlayout(fig2, 1, 3, 'Padding','compact');
nexttile; histogram(T.pos_err_m(T.success), 25, 'FaceColor',[0.2 0.55 0.85]); grid on;
xlabel('final position error [m]'); ylabel('cases'); title('Position error');
nexttile; histogram(T.head_err_deg(T.success), 25, 'FaceColor',[0.85 0.55 0.2]); grid on;
xlabel('final heading error [deg]'); ylabel('cases'); title('Heading error');
nexttile; histogram(T.time_s(T.success), 25, 'FaceColor',[0.4 0.7 0.4]); grid on;
xlabel('simulated manoeuvre time [s]'); ylabel('cases'); title('Manoeuvre time');
exportgraphics(fig2, fullfile(outdir, sprintf('mc_%d_errors.png', n)), 'Resolution', 130);

% 3) sample trajectories
fig3 = figure('Color','w','Position',[80 80 1000 650]);
ax = axes(fig3);
plot_environment(env, ax);
cols = lines(max(1, numel(samples)));
for k = 1:numel(samples)
    tr = samples{k}.traj;
    plot(ax, tr(1,:), tr(2,:), '-', 'Color', [cols(k,:) 0.55], 'LineWidth', 1.0);
end
title(ax, sprintf('Sample trajectories (first 20 + failures) | success %.1f%%', 100*summary.success_rate));
exportgraphics(fig3, fullfile(outdir, sprintf('mc_%d_samples.png', n)), 'Resolution', 130);
end
