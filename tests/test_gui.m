% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function test_gui()
%TEST_GUI  Headless smoke test for the interactive demo and click placement.
%
%   Run with:  test_gui

root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root));

% Builds the real GUI, places a fixed car, runs the simulation and writes
% results/gui_preview.png, then closes the window.
parking_gui('selftest', true);

cfg = default_config();
env = build_parking_env(cfg);

pts = [ 5.0, 7.0;
       10.0, 8.0;
       20.0, 6.0;
       25.0, 7.0;
       14.0, 5.0 ];

for i = 1:size(pts, 1)
    [start, ok, msg] = click_to_start(env, cfg, pts(i,:)); %#ok<ASGLU>
    assert(ok, 'click placement failed at (%.1f, %.1f): %s', ...
        pts(i,1), pts(i,2), msg);

    r = run_parking_sim(env, start, cfg, struct('keep_traj', false));
    assert(r.success, 'click placement run failed at (%.1f, %.1f): %s', ...
        pts(i,1), pts(i,2), r.msg);
end

% A click outside the drivable band must be rejected.
[~, ok] = click_to_start(env, cfg, [29.0, 7.0]); %#ok<ASGLU>
assert(~ok, 'out-of-bounds click should be rejected');

fprintf('--------------------------------------------------\n');
fprintf('ALL GUI TESTS PASSED\n');
fprintf('  selftest preview : results/gui_preview.png\n');
fprintf('  click placements : %d/%d successful\n', size(pts,1), size(pts,1));
fprintf('--------------------------------------------------\n');
end
