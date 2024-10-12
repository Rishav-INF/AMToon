package com.example.amtoon.fragment

import android.annotation.SuppressLint
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.denzcoskun.imageslider.ImageSlider
import com.denzcoskun.imageslider.models.SlideModel
import com.example.amtoon.MangaitemAdapter
import com.example.amtoon.R
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.DatabaseReference
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.ValueEventListener
import mangaitemdataclass

class mangaFragment : Fragment() {

    private lateinit var dbrefong: DatabaseReference
    private lateinit var dbrefongurl: DatabaseReference
    private val mangadatalist = mutableListOf<mangaitemdataclass>()
    private lateinit var mangarecycler: RecyclerView
    private lateinit var adaptertwo: MangaitemAdapter

    var url1: String? = null
    var url2: String? = null
    var url3: String? = null

    @SuppressLint("MissingInflatedId")
    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        val view = inflater.inflate(R.layout.mangafragment, container, false)

        val imageSlider = view.findViewById<ImageSlider>(R.id.image_slider)
        val imageList = ArrayList<SlideModel>() // Create image list


        // Inflate the layout for this fragment
        mangarecycler = view.findViewById(R.id.mangarecycler)
        mangarecycler.setHasFixedSize(true)
        mangarecycler.layoutManager = LinearLayoutManager(requireContext(), RecyclerView.VERTICAL, false)
        adaptertwo = MangaitemAdapter(mangadatalist)
        mangarecycler.adapter = adaptertwo

        dbrefongurl = FirebaseDatabase.getInstance().getReference("urls")
        dbrefongurl.addValueEventListener(object : ValueEventListener {
            override fun onDataChange(dataSnapshot: DataSnapshot) {
                if (dataSnapshot.exists()) {
                    // Assign URLs to variables
                    url1 = dataSnapshot.child("url1").getValue(String::class.java)
                    url2 = dataSnapshot.child("url2").getValue(String::class.java)
                    url3 = dataSnapshot.child("url3").getValue(String::class.java)

                    imageList.clear()

                    url1?.let { imageList.add(SlideModel(it)) }
                    url2?.let { imageList.add(SlideModel(it)) }
                    url3?.let { imageList.add(SlideModel(it)) }

                    // Set the image list to the slider
                    imageSlider.setImageList(imageList)
                } else {
                    Log.d("FirebaseURL", "No URLs found in the 'urls' node.")
                }
            }

            override fun onCancelled(databaseError: DatabaseError) {
                Log.e("FirebaseURL", "Failed to read URLs", databaseError.toException())
            }
        })

        getuserdataong()
        return view
    }

    private fun getuserdataong() {
        dbrefong = FirebaseDatabase.getInstance().getReference("best_action_fantasy_manhwa")
        dbrefong.addValueEventListener(object : ValueEventListener {
            override fun onDataChange(snapshot: DataSnapshot) {
                mangadatalist.clear()
                if (snapshot.exists()) {
                    for (userSnapshot in snapshot.children) {
                        val event = userSnapshot.getValue(mangaitemdataclass::class.java)
                        event?.let { mangadatalist.add(event) }
                    }
                    adaptertwo.notifyDataSetChanged()
                }
            }

            override fun onCancelled(error: DatabaseError) {
                // Handle error if needed
            }
        })
    }
}
