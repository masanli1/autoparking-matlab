% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function test_recording()
%TEST_RECORDING  Headless end-to-end test of the GUI video recording.
%
%   Builds the real GUI, arms recording, plays a full demo and verifies the
%   MP4/AVI file.  The sample video is kept in results/gui_demo_recording.*.

root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root));

gui = parking_gui('recordtest', true);
f   = gui.videoFile;

assert(exist(f, 'file') == 2, 'recording file was not created');
info = dir(f);
assert(info.bytes > 10000, 'recording file is too small: %d bytes', info.bytes);

fprintf('recording: %s (%.1f KB)\n', f, info.bytes / 1024);
try
    vr = VideoReader(f);
    fprintf('  duration : %.2f s\n', vr.Duration);
    fprintf('  frame rate: %.1f fps\n', vr.FrameRate);
    fprintf('  frames   : %d\n', vr.NumFrames);
catch err
    fprintf('  VideoReader could not inspect the file: %s\n', err.message);
end

fprintf('--------------------------------------------------\n');
fprintf('ALL RECORDING TESTS PASSED\n');
fprintf('--------------------------------------------------\n');
end
