<?php

namespace App\Scramble;

use Dedoc\Scramble\Support\Generator\Operation;
use Dedoc\Scramble\Support\Generator\SecurityRequirement;
use Dedoc\Scramble\Support\RouteInfo;

class OptionalAuthTransformer
{
    public function __invoke(
        Operation $operation,
        RouteInfo $routeInfo
    ): void {
        $middleware = $routeInfo->route->gatherMiddleware();

        if (!in_array('auth.optional', $middleware, true)) {
            return;
        }

        $operation->security = [
            new SecurityRequirement([
                'http' => [],
            ]),
            new SecurityRequirement([]),
        ];
    }
}