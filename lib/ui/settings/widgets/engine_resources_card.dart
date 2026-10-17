// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/services/storage/storage.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/theme/porch_design.dart';

/// Settings → Backend: the Engine resources card.
///
/// Dual-engine memory policy, surfaced as knobs: where the text engine keeps
/// its KV cache / context memory and where the image engine parks model
/// weights between generations, over auto-detected VRAM/RAM. Stability
/// first: generations queue with backpressure instead of being dropped.
/// The knobs persist here; the engines apply them at launch.
class EngineResourcesCard extends StatelessWidget {
  const EngineResourcesCard({super.key});

  static String _gb(int mb) {
    if (mb <= 0) return 'unknown';
    final gb = mb / 1024;
    return gb >= 10
        ? '${gb.round()} GB'
        : '${gb.toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final engines = storage.engineResourcesSettings;
    final hw = Provider.of<HardwareService>(context).hardwareInfo;

    return PorchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PorchSectionHeader(
            title: 'Engine resources',
            helper:
                'How the text and image engines share your machine\u2019s '
                'memory. Applies the next time each engine starts.',
          ),
          // Auto-detected hardware line.
          Container(
            padding: const EdgeInsets.all(PorchSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.sunkenSurfaceOf(context),
              borderRadius: BorderRadius.circular(PorchRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.memory_outlined,
                  size: 20,
                  color: AppColors.porchAmberOf(context),
                ),
                const SizedBox(width: PorchSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hw == null
                            ? 'Detecting hardware…'
                            : '${hw.gpuName} · ${_gb(hw.vramMb)} VRAM',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hw == null
                            ? ''
                            : '${_gb(hw.ramMb)} system RAM · auto-detected',
                        style: PorchType.caption(context),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PorchSpacing.sm,
                    vertical: PorchSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bondHighOf(context).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(PorchRadius.pill),
                  ),
                  child: Text(
                    'Auto-detect',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bondHighOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PorchSpacing.lg),
          _PlacementRow(
            title: 'Text engine — KV cache',
            helper:
                'Where the model keeps conversation memory. System RAM frees '
                'VRAM for active compute.',
            value: engines.textKvCache,
            onChanged: engines.setTextKvCache,
          ),
          const SizedBox(height: PorchSpacing.md),
          _PlacementRow(
            title: 'Image engine — model weights',
            helper:
                'Where image weights park between generations. Parked weights '
                'stream to VRAM while generating.',
            value: engines.imageWeights,
            onChanged: engines.setImageWeights,
          ),
          const SizedBox(height: PorchSpacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Never drop a generation',
              style: TextStyle(color: AppColors.textPrimary(context)),
            ),
            subtitle: Text(
              'Queue work with backpressure instead of failing when both '
              'engines are busy. Stability first, speed second.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary(context),
              ),
            ),
            value: engines.queueWithBackpressure,
            onChanged: engines.setQueueWithBackpressure,
          ),
        ],
      ),
    );
  }
}

class _PlacementRow extends StatelessWidget {
  const _PlacementRow({
    required this.title,
    required this.helper,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String helper;
  final EngineMemoryPlacement value;
  final ValueChanged<EngineMemoryPlacement> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(helper, style: PorchType.caption(context)),
            ],
          ),
        ),
        const SizedBox(width: PorchSpacing.md),
        DropdownButton<EngineMemoryPlacement>(
          value: value,
          dropdownColor: AppColors.surfaceContainerOf(context),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 13,
          ),
          underline: const SizedBox.shrink(),
          items: [
            for (final p in EngineMemoryPlacement.values)
              DropdownMenuItem(value: p, child: Text(p.label)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
