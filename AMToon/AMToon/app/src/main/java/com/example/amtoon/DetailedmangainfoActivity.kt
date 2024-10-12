package com.example.amtoon

import android.content.Intent
import android.os.Bundle
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.bumptech.glide.Glide

class DetailedmangainfoActivity : AppCompatActivity() {
    private lateinit var mangaImageView: ImageView
    private lateinit var mangaTitleTextView: TextView
    private lateinit var mangaCreatorTextView: TextView
    private lateinit var mangaReleaseDateTextView: TextView
    private lateinit var mangaEpisodesTextView: TextView
    private lateinit var mangaReadsTextView: TextView
    private lateinit var mangaDescriptionTextView: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.detailedmangaview) // Set the layout for this activity

        // Initialize views
        mangaImageView = findViewById(R.id.mangaImage)
        mangaTitleTextView = findViewById(R.id.mangaTitle)
        mangaCreatorTextView = findViewById(R.id.mangaCreator)
        mangaReleaseDateTextView = findViewById(R.id.mangaReleaseDate)
        mangaEpisodesTextView = findViewById(R.id.mangaEpisodes)
        mangaReadsTextView = findViewById(R.id.mangaReads)
        mangaDescriptionTextView = findViewById(R.id.mangaDescription)

        // Get the Intent that started this activity and extract the data
        val intent = intent
        val mangaTitle = intent.getStringExtra("MANGA_TITLE")
        val mangaCreator = intent.getStringExtra("MANGA_CREATOR")
        val mangaReleaseDate = intent.getStringExtra("MANGA_RELEASE_DATE")
        val mangaEpisodes = intent.getStringExtra("MANGA_EPISODES")
        val mangaReads = intent.getStringExtra("MANGA_READS")
        val mangaImageLink = intent.getStringExtra("MANGA_IMAGE_LINK")
        val mangaDescription = intent.getStringExtra("MANGA_DESCRIPTION")

        // Set the data to the views
        mangaTitleTextView.text = mangaTitle
        mangaCreatorTextView.text = "By: $mangaCreator"
        mangaReleaseDateTextView.text = "Release Date: $mangaReleaseDate"
        mangaEpisodesTextView.text = "Episodes: $mangaEpisodes"
        mangaReadsTextView.text = "Reads: $mangaReads"
        mangaDescriptionTextView.text = mangaDescription

        // Load the manga image using Glide
        Glide.with(this)
            .load(mangaImageLink)
            .into(mangaImageView)
    }
}
