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
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'package:flutter/foundation.dart';

import 'image_gen_service.dart';
import 'kobold_service.dart';

/// Tracks per-user server login sessions and tears down their engine
/// resources.
///
/// Server edition: each login starts a session slice (character card,
/// context slot, queued generations scoped to the user). When a user's
/// last session ends, their slice is torn down — waiting queue entries
/// are dropped. When the last active user logs out, the engines fully
/// unload so the server idles at near-zero overhead; the next login or
/// local request loads them back transparently.
///
/// Sessions are refcounted per user: a user logged in on phone and tablet
/// holds two sessions, and neither logout tears down the slice until the
/// last one ends.
class EngineSessionTracker extends ChangeNotifier {
  /// Active login sessions per user id.
  final Map<String, int> _sessionsByUser = {};

  ImageGenService? _imageGenService;
  KoboldService? _koboldService;

  /// Wire collaborators. Follows the setImageGenService pattern.
  void setImageGenService(ImageGenService service) =>
      _imageGenService = service;
  void setKoboldService(KoboldService service) => _koboldService = service;

  /// Total active login sessions across all users.
  int get activeSessionCount =>
      _sessionsByUser.values.fold(0, (a, b) => a + b);

  /// True while at least one user is logged in.
  bool get hasActiveSessions => _sessionsByUser.isNotEmpty;

  /// Active session count for one user.
  int sessionsFor(String userId) => _sessionsByUser[userId] ?? 0;

  /// Record a login. Each login adds one session.
  void sessionStarted(String userId) {
    _sessionsByUser[userId] = (_sessionsByUser[userId] ?? 0) + 1;
    debugPrint(
      '[Sessions] $userId logged in '
      '(${_sessionsByUser[userId]} session(s)).',
    );
    notifyListeners();
  }

  /// Record a logout or session revoke. When the user's last session ends,
  /// their waiting queue entries are dropped. When no sessions remain at
  /// all, the engines fully unload.
  Future<void> sessionEnded(String userId) async {
    final remaining = (_sessionsByUser[userId] ?? 0) - 1;
    if (remaining <= 0) {
      _sessionsByUser.remove(userId);
      // Last session for this user: tear down their slice.
      _imageGenService?.teardownEngineSession(userId);
      debugPrint('[Sessions] $userId logged out (last session).');
    } else {
      _sessionsByUser[userId] = remaining;
      debugPrint(
        '[Sessions] $userId logged out ($remaining session(s) remain).',
      );
    }
    await _unloadIfIdle();
    notifyListeners();
  }

  /// End ALL sessions for a user at once (e.g. "sign out all devices").
  /// Tears down their slice and, if nobody remains, unloads the engines.
  Future<void> revokeAllSessions(String userId) async {
    if (!_sessionsByUser.containsKey(userId)) return;
    _sessionsByUser.remove(userId);
    _imageGenService?.teardownEngineSession(userId);
    debugPrint('[Sessions] $userId revoked all sessions.');
    await _unloadIfIdle();
    notifyListeners();
  }

  /// When no sessions remain at all, unload the engines fully. The next
  /// request — local or a fresh login — loads them back transparently.
  Future<void> _unloadIfIdle() async {
    if (_sessionsByUser.isNotEmpty) return;
    debugPrint('[Sessions] last session ended: unloading engines.');
    await _koboldService?.unloadForEngineHandoff();
    await _imageGenService?.parkWeightsForSessionEnd();
  }
}
