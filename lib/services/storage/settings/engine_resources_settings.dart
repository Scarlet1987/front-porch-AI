// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'settings_base.dart';

/// Where an engine keeps its heavyweight memory.
enum EngineMemoryPlacement {
  /// The app picks the best placement for the detected hardware.
  auto,

  /// Keep it on the graphics card (fastest, uses VRAM).
  vram,

  /// Keep it in system RAM (frees VRAM for active compute).
  ram,
}

/// Presentation copy for [EngineMemoryPlacement].
extension EngineMemoryPlacementLabel on EngineMemoryPlacement {
  String get label => switch (this) {
    EngineMemoryPlacement.auto => 'Auto',
    EngineMemoryPlacement.vram => 'Graphics card (VRAM)',
    EngineMemoryPlacement.ram => 'System RAM',
  };

  static EngineMemoryPlacement fromName(String? name) =>
      EngineMemoryPlacement.values.firstWhere(
        (v) => v.name == name,
        orElse: () => EngineMemoryPlacement.auto,
      );
}

/// Dual-engine memory policy: how the text (KoboldCpp) and image engines
/// share the machine's memory. The knobs are persisted here; the engines
/// themselves apply them at launch. Stability first: generations queue with
/// backpressure instead of being dropped.
class EngineResourcesSettings with SettingsBase {
  /// Where the text engine keeps its KV cache / context memory.
  EngineMemoryPlacement _textKvCache = EngineMemoryPlacement.auto;

  /// Where the image engine parks model weights between generations
  /// (streamed to VRAM while generating).
  EngineMemoryPlacement _imageWeights = EngineMemoryPlacement.auto;

  /// Never drop a generation: queue work with backpressure instead.
  bool _queueWithBackpressure = true;

  /// Micro-model role routing (Advanced): model ID for NPC dialogue/chatter
  /// (small, fast) vs MC narrative and scene generation (main, larger).
  /// Empty = use the default model for both.
  String _npcRoleModelId = '';
  String _mcRoleModelId = '';

  /// VRAM budget in MB for both engines combined. 0 = auto (conservative
  /// split with safety headroom).
  int _vramBudgetMb = 0;

  EngineMemoryPlacement get textKvCache => _textKvCache;
  EngineMemoryPlacement get imageWeights => _imageWeights;
  bool get queueWithBackpressure => _queueWithBackpressure;
  String get npcRoleModelId => _npcRoleModelId;
  String get mcRoleModelId => _mcRoleModelId;
  int get vramBudgetMb => _vramBudgetMb;

  void load() {
    _textKvCache = EngineMemoryPlacementLabel.fromName(
      prefs?.getString(k('engine_text_kv_cache')),
    );
    _imageWeights = EngineMemoryPlacementLabel.fromName(
      prefs?.getString(k('engine_image_weights')),
    );
    _queueWithBackpressure =
        prefs?.getBool(k('engine_queue_backpressure')) ?? true;
    _npcRoleModelId = prefs?.getString(k('engine_npc_model')) ?? '';
    _mcRoleModelId = prefs?.getString(k('engine_mc_model')) ?? '';
    _vramBudgetMb = prefs?.getInt(k('engine_vram_budget_mb')) ?? 0;
  }

  Future<void> setTextKvCache(EngineMemoryPlacement value) async {
    if (_textKvCache == value) return;
    _textKvCache = value;
    await prefs?.setString(k('engine_text_kv_cache'), value.name);
    notify();
  }

  Future<void> setImageWeights(EngineMemoryPlacement value) async {
    if (_imageWeights == value) return;
    _imageWeights = value;
    await prefs?.setString(k('engine_image_weights'), value.name);
    notify();
  }

  Future<void> setQueueWithBackpressure(bool value) async {
    if (_queueWithBackpressure == value) return;
    _queueWithBackpressure = value;
    await prefs?.setBool(k('engine_queue_backpressure'), value);
    notify();
  }

  Future<void> setNpcRoleModelId(String value) async {
    if (_npcRoleModelId == value) return;
    _npcRoleModelId = value;
    await prefs?.setString(k('engine_npc_model'), value);
    notify();
  }

  Future<void> setMcRoleModelId(String value) async {
    if (_mcRoleModelId == value) return;
    _mcRoleModelId = value;
    await prefs?.setString(k('engine_mc_model'), value);
    notify();
  }

  Future<void> setVramBudgetMb(int value) async {
    final v = value.clamp(0, 131072);
    if (_vramBudgetMb == v) return;
    _vramBudgetMb = v;
    await prefs?.setInt(k('engine_vram_budget_mb'), v);
    notify();
  }
}
