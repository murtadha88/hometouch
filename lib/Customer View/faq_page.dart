import 'package:flutter/material.dart';

class FAQ extends StatefulWidget {
  const FAQ({super.key});
  @override
  State<FAQ> createState() => _FAQState();
}

class _FAQState extends State<FAQ> {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.09),
        child: AppBar(
          leading: Padding(
            padding: EdgeInsets.only(
                top: screenHeight * 0.025, left: screenWidth * 0.02),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFBF0000),
                ),
                alignment: Alignment.center,
                padding: EdgeInsets.only(
                    top: screenHeight * 0.001, left: screenWidth * 0.02),
                child: Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: screenHeight * 0.025),
              ),
            ),
          ),
          title: Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.02),
            child: Text(
              'FAQs',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: screenHeight * 0.027,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(screenHeight * 0.002),
            child: Divider(
                thickness: screenHeight * 0.001, color: Colors.grey[300]),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: ListView(
          children: List.generate(4, (index) {
            List<String> questions = [
              'Why I cannot pay?',
              'How to schedule an order?',
              'Why I cannot track my order?',
              'Can I pay in cash?'
            ];
            List<String> answers = [
              'Maybe an issue from the application. Please contact us',
              'You can schedule an order from the order settings.',
              'Tracking might be unavailable temporarily.',
              'Yes, cash payments are accepted, as well as pay by card and by points'
            ];
            return Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: screenHeight * 0.015),
              color: Colors.white,
              child: ExpansionTile(
                leading: Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: screenWidth * 0.09,
                    color: const Color(0xFFBF0000),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                title: Text(
                  questions[index],
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing:
                    const Icon(Icons.arrow_drop_down, color: Color(0xFFBF0000)),
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        top: 0,
                        right: screenWidth * 0.06,
                        left: screenWidth * 0.2,
                        bottom: screenHeight * 0.02),
                    child: Text(
                      answers[index],
                      style: TextStyle(
                          color: const Color.fromARGB(255, 87, 87, 87)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
