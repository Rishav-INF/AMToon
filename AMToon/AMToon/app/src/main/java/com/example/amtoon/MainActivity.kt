package com.example.amtoon

import android.content.Intent
import android.os.Bundle
import android.os.Looper
import android.view.animation.AlphaAnimation
import android.widget.ImageView
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import com.airbnb.lottie.LottieAnimationView
import com.example.amtoon.ui.theme.AMToonTheme
import java.util.logging.Handler

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.splash)
        val animationlogo = findViewById<LottieAnimationView>(R.id.animationView)
        android.os.Handler(Looper.getMainLooper()).postDelayed({
            // Create a fade-in animation
            val fadeIn = AlphaAnimation(0f, 1f)
            fadeIn.duration = 1000 // 1 second

            // Apply the animation to the ImageView
            animationlogo.startAnimation(fadeIn)
            // Make the ImageView visible
            animationlogo.visibility = ImageView.VISIBLE

        }, 1000)
        android.os.Handler(Looper.getMainLooper()).postDelayed(
            {
                val intent = Intent(this,LoginActivity::class.java)
                startActivity(intent)
            },2000
        )

        }
    }



