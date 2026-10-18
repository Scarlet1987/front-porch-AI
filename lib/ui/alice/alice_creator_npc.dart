// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Character Creator: the NPC pane — the slim one. The user gives
// the spark (name, role, one-line concept, relationship); the AI drafts
// the full card via CharacterGenService.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/services/character_gen_service.dart';
import 'package:front_porch_ai/services/character_repository.dart';
import 'package:front_porch_ai/services/llm_provider.dart';
import 'package:front_porch_ai/services/llm_service.dart';
import 'package:front_porch_ai/ui/alice/alice_creator_draft.dart';
import 'package:front_porch_ai/ui/alice/alice_creator_fields.dart';
import 'package:front_porch_ai/ui/alice/alice_widgets.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

/// The NPC pane: supporting cast, drafted by the AI.
class NpcPane extends StatelessWidget {
  final AliceCreatorDraft draft;

  const NpcPane({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AliceSectionHead(
          title: 'NPCs — supporting cast',
          subtitle: 'The AI writes your NPCs — you just give the spark.',
          barColor: AppColors.porchHoneyOf(context),
        ),
        const SizedBox(height: 8),
        Text(
          'That\u2019s the whole job here — the AI fills in appearance, '
          'personality and the rest when it drafts the card.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AliceTextField(
                label: 'Name',
                controller: draft.npcName,
                hint: 'Name this NPC…',
              ),
            ),
            const SizedBox(width: 8),
            AliceButton(
              label: draft.npcNaming ? 'Naming…' : 'Let the AI name them',
              ghost: true,
              small: true,
              onPressed: draft.npcNaming
                  ? null
                  : () => draft.suggestNpcName(context),
            ),
          ],
        ),
        if (draft.showAllFields) ...[
          const SizedBox(height: 10),
          Text('Role in the story', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: draft.npcRole,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final r in kNpcRoles)
                DropdownMenuItem(value: r, child: Text(r)),
            ],
            onChanged: (r) {
              if (r != null) draft.setNpcRole(r);
            },
          ),
        ],
        const SizedBox(height: 10),
        AliceTextField(
          label: 'One-line concept — the spark; one line is plenty',
          controller: draft.npcConcept,
          hint: 'e.g. the ferry master who knows more than she\u2019ll say',
        ),
        if (draft.showAllFields) ...[
          const SizedBox(height: 10),
          AliceTextField(
            label: 'Relationship to the Main Character',
            controller: draft.npcRelationship,
          ),
        ],
        const SizedBox(height: 12),
        AliceButton(
          label: draft.npcDrafting ? 'Drafting…' : 'Draft this NPC with AI',
          onPressed: draft.npcDrafting ? null : () => draft.draftNpc(context),
          block: true,
        ),
        if (draft.npcDraft != null) ...[
          const SizedBox(height: 12),
          _DraftOutput(draft: draft),
        ],
        const SizedBox(height: 12),
        AlicePeekButton(
          showingAll: draft.showAllFields,
          onToggle: draft.toggleShowAllFields,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// The drafted card, shown after a successful draft run.
class _DraftOutput extends StatelessWidget {
  final AliceCreatorDraft draft;

  const _DraftOutput({required this.draft});

  @override
  Widget build(BuildContext context) {
    final card = draft.npcDraft;
    if (card == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return AliceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Draft ready',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            draft.showAllFields
                ? 'Review what the AI filled in, then save the card.'
                : 'Save it as-is, or show every field to review the details.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 8),
          AliceKeyValue(label: 'Name', value: card.name),
          if (card.scenario.trim().isNotEmpty)
            AliceKeyValue(
              label: 'Opening scene',
              value: _shorten(card.scenario),
            ),
          if (draft.showAllFields) ...[
            if (card.description.trim().isNotEmpty)
              AliceKeyValue(
                label: 'Appearance (AI draft)',
                value: _shorten(card.description),
              ),
            if (card.personality.trim().isNotEmpty)
              AliceKeyValue(
                label: 'Personality (AI draft)',
                value: _shorten(card.personality),
              ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AliceButton(
                  label: 'Save NPC card',
                  onPressed: () => draft.saveNpcCard(context),
                ),
              ),
              const SizedBox(width: 10),
              AliceButton(
                label: 'Draft again',
                ghost: true,
                onPressed: draft.npcDrafting
                    ? null
                    : () => draft.draftNpc(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _shorten(String s) {
    final oneLine = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return oneLine.length > 220 ? '${oneLine.substring(0, 220)}…' : oneLine;
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

/// NPC drafting actions on the shared draft: AI naming, full-card draft
/// via the existing chargen service, and saving the drafted card.
extension NpcDraftActions on AliceCreatorDraft {
  /// "Let the AI name them": one short generation, name only.
  Future<void> suggestNpcName(BuildContext context) async {
    final llm = context.read<LLMProvider>().activeService;
    if (!llm.isReady) {
      _snack(
        context,
        'No AI backend is ready. Start one in Settings, then try again.',
      );
      return;
    }
    npcNaming = true;
    touch();
    try {
      final concept = npcConcept.text.trim();
      final prompt =
          'Suggest one fitting name for a roleplay NPC. Role: $npcRole.'
          '${concept.isEmpty ? '' : ' Concept: $concept'}'
          ' Reply with ONLY the name — no quotes, no explanation.';
      final buf = StringBuffer();
      await for (final chunk in llm.generateStream(
        GenerationParams(prompt: prompt, maxLength: 24, temperature: 0.9),
      )) {
        buf.write(chunk);
        if (buf.length > 80) break;
      }
      final name = buf
          .toString()
          .trim()
          .split('\n')
          .first
          .trim()
          .replaceAll(RegExp('^["\u201c]|["\u201d.\$]'), '');
      if (name.isNotEmpty) npcName.text = name;
    } catch (_) {
      // Naming is a nicety — the draft button below still works.
    } finally {
      npcNaming = false;
      touch();
    }
  }

  /// "Draft this NPC with AI": full card via the existing chargen service.
  Future<void> draftNpc(BuildContext context) async {
    final llm = context.read<LLMProvider>().activeService;
    if (!llm.isReady) {
      _snack(
        context,
        'No AI backend is ready. Start one in Settings, then draft your NPC.',
      );
      return;
    }
    npcDrafting = true;
    npcDraft = null;
    touch();
    try {
      final name = npcName.text.trim();
      final conceptBits = <String>[
        'Supporting NPC.',
        'Role: $npcRole.',
        npcConcept.text.trim(),
      ].where((s) => s.trim().isNotEmpty).join(' ');
      final card = await CharacterGenService(llm).generateCharacter(
        name: name.isEmpty ? 'A new NPC' : name,
        concept: conceptBits,
        relationship: npcRelationship.text.trim(),
        generateLorebook: false,
        altGreetingCount: 1,
      );
      npcDraft = card;
      if (card == null && context.mounted) {
        _snack(context, 'The AI could not draft that NPC. Try again.');
      }
    } finally {
      npcDrafting = false;
      touch();
    }
  }

  /// Persist the drafted NPC card.
  Future<void> saveNpcCard(BuildContext context) async {
    final card = npcDraft;
    if (card == null) return;
    final repo = Provider.of<CharacterRepository>(context, listen: false);
    await repo.addCharacter(card);
    if (context.mounted) {
      _snack(context, 'NPC card saved.');
      npcDraft = null;
      touch();
    }
  }
}
