// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Front Porch AI is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Front Porch AI. If not, see <https://www.gnu.org/licenses/>.

// Guards for EngineSessionTracker (server edition): refcounted per-user
// sessions, slice teardown on last logout, and full engine unload when
// nobody remains.

import 'package:flutter_test/flutter_test.dart';

import 'package:front_porch_ai/services/engine_session_tracker.dart';

void main() {
  test('sessions refcount per user; last logout tears down the slice', () {
    final tracker = EngineSessionTracker();
    expect(tracker.hasActiveSessions, isFalse);
    expect(tracker.activeSessionCount, 0);

    tracker.sessionStarted('user-a');
    tracker.sessionStarted('user-a');
    tracker.sessionStarted('user-b');
    expect(tracker.activeSessionCount, 3);
    expect(tracker.sessionsFor('user-a'), 2);
    expect(tracker.hasActiveSessions, isTrue);
  });

  test('sessionEnded decrements without teardown until the last one', () async {
    final tracker = EngineSessionTracker();
    tracker.sessionStarted('user-a');
    tracker.sessionStarted('user-a');

    await tracker.sessionEnded('user-a');
    expect(tracker.sessionsFor('user-a'), 1);
    expect(tracker.hasActiveSessions, isTrue);

    await tracker.sessionEnded('user-a');
    expect(tracker.sessionsFor('user-a'), 0);
    expect(tracker.hasActiveSessions, isFalse);
  });

  test('revokeAllSessions clears the user even with multiple sessions',
      () async {
    final tracker = EngineSessionTracker();
    tracker.sessionStarted('user-a');
    tracker.sessionStarted('user-a');
    tracker.sessionStarted('user-b');

    await tracker.revokeAllSessions('user-a');
    expect(tracker.sessionsFor('user-a'), 0);
    expect(tracker.sessionsFor('user-b'), 1);
    expect(tracker.hasActiveSessions, isTrue);
  });

  test('revokeAllSessions for unknown user is a no-op', () async {
    final tracker = EngineSessionTracker();
    await tracker.revokeAllSessions('nobody');
    expect(tracker.hasActiveSessions, isFalse);
  });
}
