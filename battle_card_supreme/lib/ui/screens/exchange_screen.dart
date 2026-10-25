import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/api/api_client.dart';
import '../../state/collection_controller.dart';
import '../../state/progress_controller.dart';
import '../../state/session_controller.dart';
import '../../theme/aetherium_theme.dart';
import '../widgets/chest_open_overlay.dart';

class ExchangeScreen extends ConsumerStatefulWidget {
  const ExchangeScreen({super.key, required this.onNeedLogin});

  final VoidCallback onNeedLogin;

  @override
  ConsumerState<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends ConsumerState<ExchangeScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _busy = false;
  String? _lastResult;

  static const _keyArt = {
    'iron': 'assets/brand/keys/key_iron.png',
    'silver': 'assets/brand/keys/key_silver.png',
    'gold': 'assets/brand/keys/key_gold.png',
  };

  static const _chestArt = {
    'dock_crate': 'assets/brand/chests/chest_dock_crate.jpg',
    'brine_cache': 'assets/brand/chests/chest_brine_cache.jpg',
    'gale_reliquary': 'assets/brand/chests/chest_gale_reliquary.jpg',
    'eclipse_casket': 'assets/brand/chests/chest_eclipse_casket.jpg',
    'sovereign_reliquary': 'assets/brand/chests/chest_sovereign_reliquary.jpg',
  };

  static const _marksArt = 'assets/brand/currency/icon_rift_marks.jpg';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final session = ref.read(sessionProvider).value;
    if (session?.isAuthenticated != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data =
          await ref.read(sessionProvider.notifier).client.exchangeChests();
      if (!mounted) return;
      setState(() => _data = data);
      await ref.read(progressProvider.notifier).refresh();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Exchange unreachable.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _buyKey(String code) async {
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider.notifier).client.buyKey(
            keyCode: code,
            clientPurchaseId:
                'key-$code-${DateTime.now().microsecondsSinceEpoch}',
          );
      await _load();
      await ref.read(collectionProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchased $code key.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openChest(String code, String title) async {
    setState(() => _busy = true);
    try {
      final body = await ref.read(sessionProvider.notifier).client.openChest(
            chestCode: code,
            clientOpenId: 'chest-$code-${DateTime.now().microsecondsSinceEpoch}',
          );
      await _load();
      await ref.read(collectionProvider.notifier).refresh();
      final results = ((body['results'] as List?) ?? const [])
          .whereType<Map>()
          .map((r) => r.cast<String, dynamic>())
          .toList();
      final summary = results.map((r) {
        final card = r['card'] as Map?;
        final name = card?['name'] ?? 'Card';
        final neu = r['was_new'] == true ? 'NEW' : 'COPY';
        return '$name ($neu)';
      }).join(', ');
      if (!mounted) return;
      setState(() => _lastResult = summary);
      await showChestOpenOverlay(
        context: context,
        chestCode: code,
        chestTitle: title,
        results: results,
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;
    final progress = ref.watch(progressProvider).value;

    if (session?.isAuthenticated != true) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sign in to use the Astral Exchange.',
                style: GoogleFonts.plusJakartaSans(
                  color: AetheriumColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: widget.onNeedLogin,
                child: const Text('COMMANDER ACCESS'),
              ),
            ],
          ),
        ),
      );
    }

    final keys = (_data?['keys'] as Map?)?.cast<String, dynamic>() ?? {};
    final chests = (_data?['chests'] as List?) ?? const [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          Text(
            'ASTRAL EXCHANGE',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.06,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Buy keys with Rift Marks. Open chests to unlock and level relics.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AetheriumColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (progress != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _currencyChip(
                  art: _marksArt,
                  label: 'MARKS',
                  value: '${progress.riftMarks}',
                ),
                _chip('Æ', '${progress.aether}'),
                _currencyChip(
                  art: _keyArt['iron']!,
                  label: 'IRON',
                  value: '${progress.keyIron}',
                ),
                _currencyChip(
                  art: _keyArt['silver']!,
                  label: 'SILVER',
                  value: '${progress.keySilver}',
                ),
                _currencyChip(
                  art: _keyArt['gold']!,
                  label: 'GOLD',
                  value: '${progress.keyGold}',
                ),
              ],
            ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AetheriumColors.error)),
          ],
          const SizedBox(height: 18),
          Text(
            'RIFT KEYS',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AetheriumColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...['iron', 'silver', 'gold'].map((code) {
            final k = (keys[code] as Map?)?.cast<String, dynamic>() ?? {};
            return _keyCard(code, k);
          }),
          const SizedBox(height: 18),
          Text(
            'CHESTS',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AetheriumColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...chests.whereType<Map>().map((c) {
            final m = c.cast<String, dynamic>();
            return _chestCard(m);
          }),
          if (_lastResult != null) ...[
            const SizedBox(height: 16),
            Text(
              'LAST OPEN',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AetheriumColors.secondary,
              ),
            ),
            Text(
              _lastResult!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AetheriumColors.onSurfaceVariant,
              ),
            ),
          ],
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AetheriumColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AetheriumColors.outlineVariant),
      ),
      child: Text(
        '$label $value',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AetheriumColors.secondary,
        ),
      ),
    );
  }

  Widget _currencyChip({
    required String art,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AetheriumColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AetheriumColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            art,
            width: 18,
            height: 18,
            errorBuilder: (_, __, ___) => const SizedBox(width: 18, height: 18),
          ),
          const SizedBox(width: 6),
          Text(
            '$label $value',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AetheriumColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _keyCard(String code, Map<String, dynamic> k) {
    final cost = k['shop_cost_amount'] ?? '?';
    final owned = k['owned'] ?? 0;
    final title = k['title'] ?? code;
    final desc = k['description'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AetheriumColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AetheriumColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            _keyArt[code]!,
            width: 56,
            height: 56,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.vpn_key, color: AetheriumColors.tertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                ),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AetheriumColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Owned $owned  ·  $cost Marks',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    color: AetheriumColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: _busy ? null : () => _buyKey(code),
            child: const Text('BUY'),
          ),
        ],
      ),
    );
  }

  Widget _chestCard(Map<String, dynamic> c) {
    final code = c['code'] as String? ?? '';
    final title = c['title'] as String? ?? code;
    final desc = c['description'] as String? ?? '';
    final keyCode = c['key_code'] as String? ?? 'iron';
    final need = c['keys_required'] ?? 1;
    final pulls = c['pull_count'] ?? 3;
    final art = _chestArt[code];
    final rates = ((c['probability_disclosure'] as Map?)?['rates_percent']
            as Map?)
        ?.cast<String, dynamic>();
    final rateText = rates == null
        ? ''
        : rates.entries
            .where((e) => (e.value as num) > 0)
            .map((e) =>
                '${e.key[0].toUpperCase()}${e.key.substring(1)} ${e.value}%')
            .take(4)
            .join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AetheriumColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AetheriumColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (art != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    art,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 72,
                      height: 72,
                      child: Icon(Icons.inventory_2,
                          color: AetheriumColors.tertiary),
                    ),
                  ),
                ),
              if (art != null) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${c['tier']}'.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AetheriumColors.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AetheriumColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$need ${keyCode.toUpperCase()} key(s)  ·  $pulls pulls',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AetheriumColors.secondary,
            ),
          ),
          if (rateText.isNotEmpty)
            Text(
              rateText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AetheriumColors.outline,
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _busy ? null : () => _openChest(code, title),
              child: const Text('OPEN'),
            ),
          ),
        ],
      ),
    );
  }
}
