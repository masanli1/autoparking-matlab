% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function parking_main(varargin)
%PARKING_MAIN  Entry point for the complete automatic-parking simulator.
%
%   parking_main                         % fixed demo, print + save figure
%   parking_main('mode','demo','animate',true)
%   parking_main('mode','single')        % random start, one run
%   parking_main('mode','monte-carlo','cases',1000)
%   parking_main('mode','test')          % unit + integration tests
%
%   Name-value options:
%       'mode'     'demo' | 'single' | 'monte-carlo' | 'gui' | 'test'
%       'cases'    number of Monte Carlo cases (default 1000)
%       'seed'     RNG seed
%       'slot'     target slot index (1..8)
%       'animate'  play back a demo manoeuvre
%       'plot'     write figures to results/ (default true)
%       'start'    explicit 4x1 start pose

root = fileparts(mfilename('fullpath'));
addpath(genpath(root));

cfg = default_config();

p = inputParser;
p.addParameter('mode', 'demo');
p.addParameter('cases', cfg.mc.cases);
p.addParameter('seed', []);
p.addParameter('slot', []);
p.addParameter('animate', false);
p.addParameter('plot', true);
p.addParameter('start', []);
p.parse(varargin{:});
opt = p.Results;

if ~isempty(opt.seed),  cfg.sim.seed      = opt.seed;  end
if ~isempty(opt.slot),  cfg.slots.target  = opt.slot;  end
cfg.vis.animate = logical(opt.animate);
cfg.vis.enabled = logical(opt.plot);

outdir = cfg.vis.outdir;
if ~exist(outdir, 'dir'), mkdir(outdir); end

switch lower(char(opt.mode))
    case {'demo', 'single'}
        env = build_parking_env(cfg);
        if ~isempty(opt.start)
            start = opt.start(:);
        elseif strcmpi(char(opt.mode), 'demo')
            if cfg.slots.target <= 4
                start = [3.0; 6.5; 0.0; 0.0];       % approach from the left
            else
                start = [27.0; 6.5; pi; 0.0];      % approach from the right
            end
        else
            rng(cfg.sim.seed, 'twister');
            c = make_case(env, cfg);
            start = c.start;
        end

        fprintf('================ single parking run ================\n');
        fprintf('start   : [%.2f, %.2f, %.2f deg]\n', ...
            start(1), start(2), rad2deg(start(3)));
        fprintf('target  : slot %d, final [%.2f, %.2f, %.2f deg]\n', ...
            cfg.slots.target, env.target.final_pose(1), ...
            env.target.final_pose(2), rad2deg(env.target.final_pose(3)));

        res = run_parking_sim(env, start, cfg, ...
            struct('keep_traj', true, 'verbose', true));

        fprintf('result  : %s | success=%d | pos=%.3f m | head=%.2f deg | t=%.1f s\n', ...
            res.msg, res.success, res.pos_err, rad2deg(res.head_err), res.time);

        if cfg.vis.enabled
            fname = fullfile(outdir, 'demo_result.png');
            plot_result(env, res, cfg, fname);
            fprintf('figure  : %s\n', fname);
        end
        if cfg.vis.animate
            animate_result(env, res, cfg);
        end

    case 'monte-carlo'
        summary = run_monte_carlo(cfg, opt.cases, struct('plot', cfg.vis.enabled));
        fprintf('CSV     : %s\n', summary.csv_file);
        fprintf('MAT     : %s\n', summary.mat_file);

    case 'gui'
        parking_gui('slot', cfg.slots.target);

    case 'test'
        test_parking();

    otherwise
        error('parking_main:unknownMode', 'Unknown mode "%s".', char(opt.mode));
end
end
