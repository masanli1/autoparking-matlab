% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function run_all()
%RUN_ALL  Run the complete test suite (core + GUI + recording).
%
%   run_all

root = fileparts(mfilename('fullpath'));
addpath(genpath(root));

fprintf('=== AutoParking MATLAB test suite ===\n');
parking_main('mode', 'test');
test_gui;
test_recording;
fprintf('\nAll suites finished.\n');
end
