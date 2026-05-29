package com.roua.trading

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class RouaApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Initialize any global components
    }
}
