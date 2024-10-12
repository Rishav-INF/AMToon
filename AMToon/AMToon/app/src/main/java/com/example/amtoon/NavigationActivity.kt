package com.example.amtoon

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentTransaction
import com.example.amtoon.R
import com.example.amtoon.fragment.Favourites
import com.example.amtoon.fragment.mangaFragment
import com.google.android.material.bottomnavigation.BottomNavigationView

class NavigationActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.nav_view)
        val nav_view=findViewById<BottomNavigationView>(R.id.bm)
        val favourites= Favourites()
        val mangafr= mangaFragment()
        makeCurrentFragment(mangafr)
        nav_view.setOnNavigationItemSelectedListener {
            when(it.itemId)
            {
                R.id.Manga->makeCurrentFragment(mangafr)
                R.id.Favourites->makeCurrentFragment(favourites)
            }
            true
        }

    }
    private fun makeCurrentFragment(fragment: Fragment): FragmentTransaction =
        supportFragmentManager.beginTransaction().apply {
            replace(R.id.fl_wrapper, fragment).commit()
        }

}