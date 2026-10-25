import 'package:battle_card_supreme/domain/modes/mode_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builtin catalog includes survival with three waves', () {
    final survival = modeByCode('survival_challenge');
    expect(survival, isNotNull);
    expect(survival!.available, isTrue);
    expect(survival.waves, 3);
    expect(survival.maxRounds, 20);
    expect(survival.healBetweenWavesPercent, 25);
    expect(survival.isOfflineOnly, isTrue);
  });

  test('between-wave heal uses integer missing-HP percent', () {
    var hp = 40;
    var en = 1;
    applyBetweenWaveHeal(
      currentHp: hp,
      maxHp: 100,
      healPercent: 25,
      setHp: (v) => hp = v,
      setEn: (v) => en = v,
      currentEn: en,
      maxEn: 5,
    );
    // missing 60 -> 25% = 15
    expect(hp, 55);
    expect(en, 3);
  });

  test('survival enemy ids escalate by wave offset', () {
    final roster = List.generate(12, (i) => 'c$i');
    final w1 = survivalEnemyIds(wave: 1, rosterIds: roster, teamSize: 3);
    final w2 = survivalEnemyIds(wave: 2, rosterIds: roster, teamSize: 3);
    expect(w1.length, 3);
    expect(w2.length, 3);
    expect(w1, isNot(equals(w2)));
  });

  test('ModeRules.fromJson mirrors API payload', () {
    final parsed = ModeRules.fromJson({
      'code': 'survival_challenge',
      'title': 'Survival Challenge',
      'subtitle': 'Waves',
      'available': true,
      'rule_version': 1,
      'rules': {
        'team_size': 3,
        'max_rounds': 20,
        'waves': 3,
        'heal_between_waves_percent': 25,
        'ownership_required': true,
        'ranking_eligible': false,
        'opponent': 'ai',
        'channel': 'offline',
      },
    });
    expect(parsed.waves, 3);
    expect(parsed.channel, 'offline');
  });
}
