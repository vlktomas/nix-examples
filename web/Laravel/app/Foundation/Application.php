<?php

namespace App\Foundation;

class Application extends \Illuminate\Foundation\Application
{
    public function __construct($basePath = null)
    {
        parent::__construct($basePath);
        // set the storage path
        $this->afterLoadingEnvironment(function () {
            $this->useStoragePath(realpath(env('APP_STORAGE_PATH', 'storage')));
        });
    }
}
