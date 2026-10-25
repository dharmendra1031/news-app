<?php

namespace App\Traits;

use Illuminate\Database\Eloquent\Builder;

trait HasSafeOrder
{
    /**
     * Scope a query to apply safe dynamic ordering.
     *
     * This scope:
     * - Checks if the requested column exists in $orderable (if defined)
     * - Falls back to the model's default sort column if invalid or $orderable not set
     * - Ensures direction is only ASC or DESC (defaults to DESC)
     *
     * Usage:
     * --------------------------------------------------
     * In your model:
     *
     *   use HasSafeOrder;
     *
     *   protected array $orderable = ['created_at', 'title', 'status'];
     *
     * In your controller:
     *
     *   Model::safeOrder(
     *       $request->input('order_column'),
     *       $request->input('order_by')
     *   )->get();
     *
     * --------------------------------------------------
     *
     * @param  Builder      $query
     * @param  string|null  $column     Column name requested for sorting
     * @param  string       $direction  Sort direction (ASC or DESC)
     * @return Builder
     */
    public function scopeSafeOrder(Builder $query, ?string $column = null, string $direction = 'DESC'): Builder
    {
        // Determine allowed columns
        $allowedColumns = property_exists($this, 'orderable') && is_array($this->orderable)
                            ? $this->orderable
                            : [];

        // Use provided column if valid, otherwise fallback to default
        $column = in_array($column, $allowedColumns, true)
            ? $column
            : $this->defaultOrderColumn();

        // Normalize direction (only allow ASC, fallback to DESC)
        $direction = strtoupper($direction) === 'ASC' ? 'ASC' : 'DESC';

        return $query->orderBy($column, $direction);
    }

    /**
     * Get the model's default sort column.
     *
     * - If $orderable exists and has columns, use the first one.
     * - Otherwise, fallback to the model's primary key (usually 'id').
     *
     * @return string
     */
    protected function defaultOrderColumn(): string
    {
        if (property_exists($this, 'orderable') && is_array($this->orderable) && count($this->orderable) > 0) {
            return $this->orderable[0];
        }

        // Fallback to primary key (usually 'id')
        return $this->getKeyName();
    }
}
