package com.example.hakeem

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Make sure screenshots are allowed for this Activity
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
