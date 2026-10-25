<?php

namespace App\Combat;

/**
 * Server port of the Flutter CombatEngine. Integer math only.
 */
final class CombatEngine
{
    public function start(array $playerCards, array $enemyCards, int $maxRounds = 30): array
    {
        $player = [];
        foreach (array_values($playerCards) as $i => $card) {
            $player[] = $this->combatantFromCard($card, 'player', 'P'.$i);
        }
        $enemy = [];
        foreach (array_values($enemyCards) as $i => $card) {
            $enemy[] = $this->combatantFromCard($card, 'enemy', 'E'.$i);
        }

        $state = [
            'player' => $player,
            'enemy' => $enemy,
            'turn_queue' => [],
            'round' => 1,
            'queue_index' => 0,
            'outcome' => 'ongoing',
            'max_rounds' => $maxRounds,
            'log' => [['message' => 'Clash begins.', 'damage' => 0, 'healing' => 0]],
            'seen_action_ids' => [],
        ];
        $this->rebuildQueue($state);

        return $state;
    }

    /**
     * @return array{ok:bool,error_code:?string,events:array<int,array>,state:array}
     */
    public function apply(array $state, array $action): array
    {
        if (($state['outcome'] ?? 'ongoing') !== 'ongoing') {
            return ['ok' => false, 'error_code' => 'MATCH_ENDED', 'events' => [], 'state' => $state];
        }

        $clientActionId = $action['client_action_id'] ?? null;
        if (is_string($clientActionId) && $clientActionId !== '') {
            if (in_array($clientActionId, $state['seen_action_ids'], true)) {
                return ['ok' => true, 'error_code' => 'IDEMPOTENT_REPLAY', 'events' => [], 'state' => $state];
            }
            $state['seen_action_ids'][] = $clientActionId;
        }

        $type = $action['type'] ?? '';
        if ($type === 'concede') {
            $state['outcome'] = 'forfeit_player';
            $ev = ['message' => 'Commander conceded.', 'damage' => 0, 'healing' => 0];
            $state['log'][] = $ev;

            return ['ok' => true, 'error_code' => null, 'events' => [$ev], 'state' => $state];
        }

        $actorId = $action['actor_id'] ?? '';
        $actorIndex = $this->indexById($state, $actorId);
        if ($actorIndex === null) {
            return ['ok' => false, 'error_code' => 'MATCH_ILLEGAL_ACTION', 'events' => [], 'state' => $state];
        }
        [$actorSide, $actorPos] = $actorIndex;
        $actor = &$state[$actorSide][$actorPos];
        if (($actor['hp'] ?? 0) <= 0) {
            return ['ok' => false, 'error_code' => 'MATCH_ILLEGAL_ACTION', 'events' => [], 'state' => $state];
        }

        $current = $this->currentActor($state);
        if ($current === null || ($current['instance_id'] ?? null) !== $actorId) {
            return ['ok' => false, 'error_code' => 'MATCH_NOT_YOUR_TURN', 'events' => [], 'state' => $state];
        }

        $events = [];
        $targetId = $action['target_id'] ?? null;

        if ($type === 'basic_attack') {
            $targetRef = $this->resolveTarget($state, $actor, $targetId);
            if ($targetRef === null) {
                return ['ok' => false, 'error_code' => 'MATCH_ILLEGAL_TARGET', 'events' => [], 'state' => $state];
            }
            $events = array_merge($events, $this->strike($state, $actor, $targetRef, 100));
        } elseif ($type === 'ability') {
            $ability = $actor['ability'];
            if (($actor['ability_cooldown'] ?? 0) > 0 || ($actor['en'] ?? 0) < ($ability['en_cost'] ?? 0)) {
                return ['ok' => false, 'error_code' => 'MATCH_ILLEGAL_ACTION', 'events' => [], 'state' => $state];
            }
            $actor['en'] -= (int) $ability['en_cost'];
            $actor['ability_cooldown'] = (int) $ability['cooldown_turns'];

            if (($ability['heal_percent'] ?? 0) > 0 || ($ability['shield_percent'] ?? 0) > 0) {
                $healTarget = null;
                if ($targetId) {
                    $idx = $this->indexById($state, $targetId);
                    if ($idx === null) {
                        return ['ok' => false, 'error_code' => 'MATCH_ILLEGAL_TARGET', 'events' => [], 'state' => $state];
                    }
                    [$ts, $tp] = $idx;
                    if ($ts !== $actorSide || ($state[$ts][$tp]['hp'] ?? 0) <= 0) {
                        return ['ok' => false, 'error_code' => 'MATCH_ILLEGAL_TARGET', 'events' => [], 'state' => $state];
                    }
                    $healTarget = [&$state[$ts][$tp]];
                } else {
                    $allies = &$state[$actorSide];
                    $bestPos = null;
                    $bestHp = PHP_INT_MAX;
                    foreach ($allies as $i => $c) {
                        if (($c['hp'] ?? 0) <= 0) {
                            continue;
                        }
                        if ($c['hp'] < $bestHp) {
                            $bestHp = $c['hp'];
                            $bestPos = $i;
                        }
                    }
                    if ($bestPos !== null) {
                        $healTarget = [&$state[$actorSide][$bestPos]];
                    }
                }
                if ($healTarget !== null) {
                    $ht = &$healTarget[0];
                    if (($ability['heal_percent'] ?? 0) > 0) {
                        $heal = intdiv($ht['max_hp'] * (int) $ability['heal_percent'], 100);
                        $before = $ht['hp'];
                        $ht['hp'] = min($ht['max_hp'], $ht['hp'] + $heal);
                        $applied = $ht['hp'] - $before;
                        $events[] = [
                            'message' => $actor['name'].' heals '.$ht['name'].' for '.$applied.'.',
                            'healing' => $applied,
                            'damage' => 0,
                            'actor_id' => $actor['instance_id'],
                            'target_id' => $ht['instance_id'],
                        ];
                    }
                    if (($ability['shield_percent'] ?? 0) > 0) {
                        $sh = intdiv($ht['max_hp'] * (int) $ability['shield_percent'], 100);
                        $ht['shield'] = ($ht['shield'] ?? 0) + $sh;
                        $events[] = [
                            'message' => $actor['name'].' shields '.$ht['name'].' for '.$sh.'.',
                            'healing' => 0,
                            'damage' => 0,
                            'actor_id' => $actor['instance_id'],
                            'target_id' => $ht['instance_id'],
                        ];
                    }
                    unset($ht);
                }
            } elseif (! empty($ability['is_aoe'])) {
                $foeSide = $actorSide === 'player' ? 'enemy' : 'player';
                foreach ($state[$foeSide] as $i => $c) {
                    if (($c['hp'] ?? 0) <= 0) {
                        continue;
                    }
                    $events = array_merge(
                        $events,
                        $this->strike($state, $actor, [$foeSide, $i], (int) $ability['multiplier_percent'])
                    );
                }
            } else {
                $targetRef = $this->resolveTarget($state, $actor, $targetId);
                if ($targetRef === null) {
                    return ['ok' => false, 'error_code' => 'MATCH_ILLEGAL_TARGET', 'events' => [], 'state' => $state];
                }
                $events = array_merge(
                    $events,
                    $this->strike($state, $actor, $targetRef, (int) $ability['multiplier_percent'])
                );
            }
        } elseif ($type === 'end_turn') {
            $events[] = [
                'message' => $actor['name'].' ends their turn.',
                'damage' => 0,
                'healing' => 0,
                'actor_id' => $actor['instance_id'],
            ];
        } else {
            return ['ok' => false, 'error_code' => 'MATCH_ILLEGAL_ACTION', 'events' => [], 'state' => $state];
        }

        foreach ($events as $ev) {
            $state['log'][] = $ev;
        }
        unset($actor);
        $this->advanceTurn($state);
        $this->evaluateOutcome($state);

        return ['ok' => true, 'error_code' => null, 'events' => $events, 'state' => $state];
    }

    public function chooseAiAction(array $state, int $seed = 7): array
    {
        $actor = $this->currentActor($state);
        if ($actor === null || ($actor['side'] ?? '') !== 'enemy') {
            throw new \RuntimeException('AI called off enemy turn');
        }

        $foes = array_values(array_filter($state['player'], fn ($c) => ($c['hp'] ?? 0) > 0));
        if ($foes === []) {
            return [
                'type' => 'end_turn',
                'actor_id' => $actor['instance_id'],
                'client_action_id' => 'ai-'.$state['round'].'-'.$state['queue_index'].'-end',
            ];
        }
        usort($foes, fn ($a, $b) => $a['hp'] <=> $b['hp']);
        $target = $foes[0];
        $ability = $actor['ability'];
        $canAbility = ($actor['ability_cooldown'] ?? 0) <= 0
            && ($actor['en'] ?? 0) >= ($ability['en_cost'] ?? 0);
        $prefer = $canAbility && (((int) ($ability['multiplier_percent'] ?? 0) >= 140) || (($seed + $state['round']) % 2 === 0));

        if ($prefer) {
            $support = (($ability['heal_percent'] ?? 0) > 0) || (($ability['shield_percent'] ?? 0) > 0);

            return [
                'type' => 'ability',
                'actor_id' => $actor['instance_id'],
                'target_id' => $support ? null : $target['instance_id'],
                'client_action_id' => 'ai-'.$state['round'].'-'.$state['queue_index'].'-'.$actor['instance_id'],
            ];
        }

        return [
            'type' => 'basic_attack',
            'actor_id' => $actor['instance_id'],
            'target_id' => $target['instance_id'],
            'client_action_id' => 'ai-'.$state['round'].'-'.$state['queue_index'].'-'.$actor['instance_id'].'-atk',
        ];
    }

    public function drainEnemyTurns(array $state, int $seed = 7): array
    {
        $allEvents = [];
        $guard = 0;
        while (($state['outcome'] ?? '') === 'ongoing'
            && ($this->currentActor($state)['side'] ?? null) === 'enemy'
            && $guard < 40) {
            $action = $this->chooseAiAction($state, $seed + $guard);
            $result = $this->apply($state, $action);
            $state = $result['state'];
            $allEvents = array_merge($allEvents, $result['events']);
            $guard++;
        }

        return ['state' => $state, 'events' => $allEvents];
    }

    public function publicState(array $state): array
    {
        return [
            'round' => $state['round'],
            'queue_index' => $state['queue_index'],
            'outcome' => $state['outcome'],
            'max_rounds' => $state['max_rounds'],
            'turn_queue' => $state['turn_queue'],
            'current_actor_id' => $this->currentActor($state)['instance_id'] ?? null,
            'is_player_turn' => (($this->currentActor($state)['side'] ?? null) === 'player'),
            'player' => array_map([$this, 'publicCombatant'], $state['player']),
            'enemy' => array_map([$this, 'publicCombatant'], $state['enemy']),
            'log' => array_slice($state['log'], -40),
        ];
    }

    private function publicCombatant(array $c): array
    {
        return [
            'instance_id' => $c['instance_id'],
            'card_code' => $c['card_code'],
            'name' => $c['name'],
            'side' => $c['side'],
            'hp' => $c['hp'],
            'max_hp' => $c['max_hp'],
            'atk' => $c['atk'],
            'def' => $c['def'],
            'spd' => $c['spd'],
            'en' => $c['en'],
            'max_en' => $c['max_en'],
            'shield' => $c['shield'],
            'ability_cooldown' => $c['ability_cooldown'],
            'ability' => $c['ability'],
            'is_alive' => ($c['hp'] ?? 0) > 0,
        ];
    }

    private function combatantFromCard(array $card, string $side, string $instanceId): array
    {
        return [
            'instance_id' => $instanceId,
            'card_code' => $card['code'],
            'name' => $card['name'],
            'side' => $side,
            'hp' => (int) $card['hp'],
            'max_hp' => (int) $card['hp'],
            'atk' => (int) $card['atk'],
            'def' => (int) $card['def'],
            'spd' => (int) $card['spd'],
            'en' => (int) $card['en'],
            'max_en' => (int) $card['en'],
            'shield' => 0,
            'ability_cooldown' => 0,
            'ability' => [
                'id' => $card['ability_id'],
                'name' => $card['ability_name'],
                'en_cost' => (int) $card['ability_en_cost'],
                'cooldown_turns' => (int) $card['ability_cooldown'],
                'multiplier_percent' => (int) $card['ability_multiplier'],
                'heal_percent' => (int) $card['ability_heal_percent'],
                'shield_percent' => (int) $card['ability_shield_percent'],
                'is_aoe' => (bool) $card['ability_is_aoe'],
            ],
        ];
    }

    private function currentActor(array $state): ?array
    {
        if (($state['outcome'] ?? '') !== 'ongoing' || ($state['turn_queue'] ?? []) === []) {
            return null;
        }
        $id = $state['turn_queue'][$state['queue_index'] % count($state['turn_queue'])];
        $idx = $this->indexById($state, $id);
        if ($idx === null) {
            return null;
        }
        [$side, $pos] = $idx;

        return $state[$side][$pos];
    }

    /** @return array{0:string,1:int}|null */
    private function indexById(array $state, string $id): ?array
    {
        foreach (['player', 'enemy'] as $side) {
            foreach ($state[$side] as $i => $c) {
                if (($c['instance_id'] ?? null) === $id) {
                    return [$side, $i];
                }
            }
        }

        return null;
    }

    /** @return array{0:string,1:int}|null */
    private function resolveTarget(array $state, array $actor, ?string $targetId): ?array
    {
        $foeSide = $actor['side'] === 'player' ? 'enemy' : 'player';
        if ($targetId) {
            $idx = $this->indexById($state, $targetId);
            if ($idx === null) {
                return null;
            }
            [$side, $pos] = $idx;
            if ($side === $actor['side'] || ($state[$side][$pos]['hp'] ?? 0) <= 0) {
                return null;
            }

            return [$side, $pos];
        }
        $best = null;
        $bestHp = PHP_INT_MAX;
        foreach ($state[$foeSide] as $i => $c) {
            if (($c['hp'] ?? 0) <= 0) {
                continue;
            }
            if ($c['hp'] < $bestHp) {
                $bestHp = $c['hp'];
                $best = [$foeSide, $i];
            }
        }

        return $best;
    }

    private function strike(array &$state, array $actor, array $targetRef, int $multiplierPercent): array
    {
        [$side, $pos] = $targetRef;
        $target = &$state[$side][$pos];
        $raw = intdiv($actor['atk'] * $multiplierPercent, 100);
        $mitigated = $raw - intdiv($target['def'] * 50, 100);
        $damage = $mitigated < 1 ? 1 : $mitigated;
        $remaining = $damage;
        if (($target['shield'] ?? 0) > 0) {
            $absorbed = min($remaining, $target['shield']);
            $target['shield'] -= $absorbed;
            $remaining -= $absorbed;
        }
        if ($remaining > 0) {
            $target['hp'] -= $remaining;
            if ($target['hp'] < 0) {
                $target['hp'] = 0;
            }
        }
        $events = [[
            'message' => $actor['name'].' hits '.$target['name'].' for '.$damage.' damage.',
            'damage' => $damage,
            'healing' => 0,
            'actor_id' => $actor['instance_id'],
            'target_id' => $target['instance_id'],
        ]];
        if ($target['hp'] <= 0) {
            $events[] = [
                'message' => $target['name'].' is defeated.',
                'damage' => 0,
                'healing' => 0,
                'actor_id' => $actor['instance_id'],
                'target_id' => $target['instance_id'],
            ];
        }
        unset($target);

        return $events;
    }

    private function advanceTurn(array &$state): void
    {
        if (($state['outcome'] ?? '') !== 'ongoing') {
            return;
        }
        $actedId = $this->currentActor($state)['instance_id'] ?? null;
        foreach (['player', 'enemy'] as $side) {
            foreach ($state[$side] as $i => $c) {
                if (($c['instance_id'] ?? null) === $actedId) {
                    continue;
                }
                if (($c['ability_cooldown'] ?? 0) > 0) {
                    $state[$side][$i]['ability_cooldown']--;
                }
            }
        }

        $aliveIds = [];
        foreach (array_merge($state['player'], $state['enemy']) as $c) {
            if (($c['hp'] ?? 0) > 0) {
                $aliveIds[$c['instance_id']] = true;
            }
        }
        if ($aliveIds === []) {
            $state['outcome'] = 'draw';

            return;
        }

        $guard = 0;
        do {
            $state['queue_index']++;
            if ($state['queue_index'] >= count($state['turn_queue'])) {
                $state['queue_index'] = 0;
                $state['round']++;
                $this->rebuildQueue($state);
                if ($state['round'] > $state['max_rounds']) {
                    $state['outcome'] = 'draw';
                    $state['log'][] = ['message' => 'Turn limit reached. Draw.', 'damage' => 0, 'healing' => 0];

                    return;
                }
            }
            $guard++;
        } while (! isset($aliveIds[$state['turn_queue'][$state['queue_index']]]) && $guard < 64);

        $next = $this->currentActor($state);
        if ($next !== null) {
            $idx = $this->indexById($state, $next['instance_id']);
            if ($idx !== null) {
                [$side, $pos] = $idx;
                $state[$side][$pos]['en'] = min(
                    $state[$side][$pos]['max_en'],
                    $state[$side][$pos]['en'] + 1
                );
            }
        }
    }

    private function rebuildQueue(array &$state): void
    {
        $living = [];
        foreach (array_merge($state['player'], $state['enemy']) as $c) {
            if (($c['hp'] ?? 0) > 0) {
                $living[] = $c;
            }
        }
        usort($living, function ($a, $b) {
            $spd = $b['spd'] <=> $a['spd'];
            if ($spd !== 0) {
                return $spd;
            }

            return strcmp($a['instance_id'], $b['instance_id']);
        });
        $state['turn_queue'] = array_map(fn ($c) => $c['instance_id'], $living);
        if ($state['queue_index'] >= count($state['turn_queue'])) {
            $state['queue_index'] = 0;
        }
    }

    private function evaluateOutcome(array &$state): void
    {
        if (($state['outcome'] ?? '') !== 'ongoing') {
            return;
        }
        $playerAlive = false;
        foreach ($state['player'] as $c) {
            if (($c['hp'] ?? 0) > 0) {
                $playerAlive = true;
                break;
            }
        }
        $enemyAlive = false;
        foreach ($state['enemy'] as $c) {
            if (($c['hp'] ?? 0) > 0) {
                $enemyAlive = true;
                break;
            }
        }
        if (! $playerAlive && ! $enemyAlive) {
            $state['outcome'] = 'draw';
            $state['log'][] = ['message' => 'Mutual defeat. Draw.', 'damage' => 0, 'healing' => 0];
        } elseif (! $playerAlive) {
            $state['outcome'] = 'victory_enemy';
            $state['log'][] = ['message' => 'Defeat.', 'damage' => 0, 'healing' => 0];
        } elseif (! $enemyAlive) {
            $state['outcome'] = 'victory_player';
            $state['log'][] = ['message' => 'Victory.', 'damage' => 0, 'healing' => 0];
        }
    }
}
