# 0029. Live pictures while dragging

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M2

## Context
The panel of ADR 0024 shows still pictures, so a video or animation stands still during a drag. The owner asks for live pictures, with a choice of frame rate. ADR 0014 rejected live video as too costly for a short drag, before the panel existed. The place of the panel and what it shows are separate, so a live picture does not slow the moving. The open question is whether an app goes on drawing with its window parked.

## Decision
- While the panel shows, a ScreenCaptureKit stream of each window updates its picture. The still picture shows until a stream's first frame arrives.
- The app's window sets the frame rate: still, 15, 30 or 60 frames a second. It starts at 30.
- The streams stop when the panel comes down. A stream that fails leaves the last picture standing, and the drag goes on.
- The report and log hold how many frames per window differed from the one before at the window's centre. The system also sends frames of a window that has not changed (a still Finder window got as many as an animated one), so counting frames says nothing. Few changes from a moving window mean its app stopped drawing.
- The stress test (ADR 0027) gets a second part: it drags beside a helper window of its own that animates, and writes down the frames that arrived.

## Alternatives
- **Starting the streams at the press:** there sooner, but every click would start them.
- **Leaving the real windows in place under the panel, in case apps stop drawing when parked:** they would show around the pictures. Kept for if parking proves the problem.
- **One stream for both windows:** a filter for one window at a time is what keeps other windows out of the picture.

## Consequences
- Positive: moving content stays alive during a drag, at a cost the owner can choose.
- Negative / risks: an app may stop drawing while parked, and this can differ per app, so a real video is still judged by hand. A stream takes a moment to start, and starting and running it costs more than a still.
- Changes now: `WindowStandIn`, the report, the panel, a stream type, the capture, the model, the app's window and strings, the stress test.
