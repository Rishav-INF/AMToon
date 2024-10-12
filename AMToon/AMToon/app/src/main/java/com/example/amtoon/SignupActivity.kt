package com.example.amtoon

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.textfield.TextInputEditText
import com.google.firebase.auth.FirebaseAuth
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext

class SignupActivity : AppCompatActivity() {
    var auth  = FirebaseAuth.getInstance()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.signup)

        val newusername = findViewById<TextInputEditText>(R.id.signupnametext)
        val newuserpass = findViewById<TextInputEditText>(R.id.signuppasswordtext)
        val signupcomp = findViewById<Button>(R.id.signupcompletionbtn)



        signupcomp.setOnClickListener {
            val username = newusername.text.toString()
            val password = newuserpass.text.toString()

            if (username.isNotEmpty() && password.isNotEmpty()) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        auth.createUserWithEmailAndPassword(username, password).await()
                        withContext(Dispatchers.Main) {
                            Toast.makeText(this@SignupActivity, "Signup successful, You are logged in now", Toast.LENGTH_LONG).show()
                            val intent = Intent(this@SignupActivity,LoginActivity::class.java)
                            startActivity((intent))
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            Toast.makeText(this@SignupActivity, e.message, Toast.LENGTH_SHORT).show()
                        }
                    }
                }
            } else {
                Toast.makeText(this, "Please fill in all fields", Toast.LENGTH_SHORT).show()
            }
        }
    }
}
