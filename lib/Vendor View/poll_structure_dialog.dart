import 'package:flutter/material.dart';

class PollPopOut extends StatefulWidget {
  final String restaurantName;
  final String restaurantImage;
  final String pollQuestion;
  final List<String> choices;

  const PollPopOut({
    super.key,
    required this.restaurantName,
    required this.restaurantImage,
    required this.pollQuestion,
    required this.choices,
  });

  @override
  _PollPopOutState createState() => _PollPopOutState();
}

class _PollPopOutState extends State<PollPopOut> {
  int? _selectedChoice;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AlertDialog(
      backgroundColor: Colors.white,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(widget.restaurantImage),
                radius: screenWidth * 0.06,
              ),
              SizedBox(width: screenWidth * 0.03),
              Text(
                widget.restaurantName,
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: screenHeight * 0.02,
              right: screenWidth * 0.02,
            ),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(
                Icons.close,
                color: Color(0xFFBF0000),
                size: screenWidth * 0.06,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: screenWidth * 0.8,
        height: screenHeight * 0.35,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.pollQuestion,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Expanded(
              child: ListView.builder(
                itemCount: widget.choices.length,
                itemBuilder: (context, index) {
                  return _buildChoiceTile(
                    index + 1,
                    widget.choices[index],
                    screenWidth,
                    screenHeight,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Center(
          child: Container(
            width: screenWidth * 0.4,
            decoration: BoxDecoration(
              color: _selectedChoice != null
                  ? Color(0xFFBF0000)
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
            ),
            child: TextButton(
              onPressed: _selectedChoice != null
                  ? () => Navigator.of(context).pop()
                  : null,
              child: Text(
                'Close',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.04,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceTile(
      int number, String label, double screenWidth, double screenHeight) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChoice = number;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
        decoration: BoxDecoration(
          color:
              _selectedChoice == number ? Color(0xFFBF0000) : Colors.grey[200],
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
        ),
        child: ListTile(
          leading: Text(
            number.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              color:
                  _selectedChoice == number ? Colors.white : Color(0xFFBF0000),
              fontWeight: FontWeight.bold,
            ),
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: _selectedChoice == number ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
