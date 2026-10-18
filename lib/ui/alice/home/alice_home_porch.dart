// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Home: "On your porch" character shelf. Part of alice_home.dart.

part of '../alice_home.dart';

/// "On your porch" horizontal shelf: character cards + new-character card.
extension _AliceHomePorch on _AliceHomeScreenState {
  Widget _buildPorchShelf(
    BuildContext context,
    List<CharacterCard> characters,
  ) {
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: characters.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == characters.length) {
            return _buildNewCharacterCard(context);
          }
          return _buildPorchCard(context, characters[index]);
        },
      ),
    );
  }

  Widget _buildPorchCard(BuildContext context, CharacterCard character) {
    final theme = Theme.of(context);
    final tagline = character.personality.trim().isNotEmpty
        ? character.personality.trim().split('\n').first
        : character.description.trim().split('\n').first;
    return SizedBox(
      width: 184,
      child: InkWell(
        onTap: () => _openCharacter(character),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardOf(context),
            border: Border.all(color: AppColors.borderOf(context)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AliceAvatar(name: character.name, size: 48),
              const SizedBox(height: 10),
              Text(
                character.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  tagline.isEmpty ? 'No description yet.' : tagline,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              const AliceChip(
                label: 'Main Character',
                color: AppColors.porchAmber,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewCharacterCard(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 184,
      child: InkWell(
        onTap: () => Provider.of<AppState>(
          context,
          listen: false,
        ).setIndex(_aliceCreatorIndex),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderOf(context)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderOf(context),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+',
                  style: TextStyle(fontSize: 22, color: theme.hintColor),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'New character',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  'You author the main character — the AI helps with the '
                  'rest of the cast.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              const AliceChip(label: 'Creator'),
            ],
          ),
        ),
      ),
    );
  }
}
