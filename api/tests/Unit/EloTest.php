<?php

namespace Tests\Unit;

use App\Support\Elo;
use Tests\TestCase;

class EloTest extends TestCase
{
    public function test_equal_ratings_win_gains_half_k(): void
    {
        $settled = Elo::settle(1000, 1000, 'win');
        $this->assertSame(1016, $settled['rating_a']);
        $this->assertSame(984, $settled['rating_b']);
        $this->assertSame(16, $settled['delta_a']);
        $this->assertSame(-16, $settled['delta_b']);
    }

    public function test_draw_leaves_equal_ratings_unchanged(): void
    {
        $settled = Elo::settle(1000, 1000, 'draw');
        $this->assertSame(1000, $settled['rating_a']);
        $this->assertSame(1000, $settled['rating_b']);
        $this->assertSame(0, $settled['delta_a']);
        $this->assertSame(0, $settled['delta_b']);
    }

    public function test_expected_table_symmetric_at_zero_diff(): void
    {
        $this->assertSame(500, Elo::expectedMillipoints(1200, 1200));
    }
}
