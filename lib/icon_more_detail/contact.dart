import 'package:flutter/material.dart';
import '../bar_icon/MorePage.dart';

class Contact extends StatelessWidget {
  const Contact({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Colors.black;
    const tileBg = Color.fromARGB(127, 48, 48, 42); // กล่องเทาเข้ม

    Widget buildTile(String label, String value) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          title: Text( 
            value,
            style: const TextStyle(
              color: Color.fromARGB(179, 201, 201, 201),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        toolbarHeight: 100,
        titleSpacing: 16,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Morepage()),
            );
          },
        ),
        title: const Text(
          'Contract',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 28,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white12),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 50),

              buildTile('Number :', '   08-622-9995'),
              const SizedBox(height: 10),
              buildTile('Facebook :', ' MOVI'),
              const SizedBox(height: 10),
              buildTile('Email :', '       movi43@gmail.com'),

              const SizedBox(height: 150),
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'images/logo_movi.jpg',
                      width: 150,
                      height: 150
                    ),
                    
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
