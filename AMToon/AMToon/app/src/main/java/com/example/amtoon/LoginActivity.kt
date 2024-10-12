package com.example.amtoon

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import android.widget.VideoView
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.textfield.TextInputEditText
import com.google.firebase.auth.FirebaseAuth
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext

class LoginActivity : AppCompatActivity() {
    var auth  = FirebaseAuth.getInstance()
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.login)

        //logo video section

        val video= findViewById<VideoView>(R.id.video)
        val videoUri = Uri.parse("android.resource://" + packageName + "/" + R.raw.videoamtlogo)
        video.setVideoURI(videoUri)
        video.setOnPreparedListener()
            {
                Handler(Looper.getMainLooper()).postDelayed(
                    {
                video.start()}
                    ,4000)
            }
        video.setOnCompletionListener {
            video.start()
        }

        //logo video section end

        //Login start
        var loginname = findViewById<TextInputEditText>(R.id.loginname)
        var loginpass = findViewById<TextInputEditText>(R.id.loginpassword)
        val signin = findViewById<Button>(R.id.loginbtn)

        signin.setOnClickListener()
        {
            val username = loginname.text.toString()
            val password = loginpass.text.toString()

            if (username.isNotEmpty() && password.isNotEmpty()) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        auth.signInWithEmailAndPassword(username, password).await()
                        Log.d("LoginActivity", "User logged in: ${auth.currentUser?.email}")
                        withContext(Dispatchers.Main) {
                            Toast.makeText(this@LoginActivity, "Login successful", Toast.LENGTH_SHORT).show()
                            checkloggedinstate()
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            Toast.makeText(this@LoginActivity, e.message, Toast.LENGTH_SHORT).show()
                        }
                    }
                }
            } else {
                Toast.makeText(this, "Please fill in all fields", Toast.LENGTH_SHORT).show()
            }
        }

        val signup = findViewById<Button>(R.id.signupbtn)

        signup.setOnClickListener()
        {
            val intent = Intent(this,SignupActivity :: class.java)
            startActivity(intent)
        }




    }

    override fun onStart() {
        super.onStart()
        checkloggedinstate()
    }
    fun checkloggedinstate(){
        if(auth.currentUser!=null)
        {
            val intent = Intent(this@LoginActivity,NavigationActivity::class.java)
            startActivity(intent)
            finish()
        }
    }
}


