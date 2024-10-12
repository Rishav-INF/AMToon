package com.example.amtoon

import android.annotation.SuppressLint
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.firebase.auth.FirebaseAuth

class AfterLogin : AppCompatActivity() {

    @SuppressLint("MissingInflatedId")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.afterlogin)
         val logout = findViewById<Button>(R.id.logoutbtn)
        logout.setOnClickListener()
        {
            FirebaseAuth.getInstance().signOut()
            Toast.makeText(this, "loged out",Toast.LENGTH_SHORT).show()
            val intent  = Intent(this@AfterLogin,LoginActivity::class.java)
            startActivity(intent)
        }


    }
}