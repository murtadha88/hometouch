import 'package:flutter/material.dart';

class SubscriptionDialog extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;

  SubscriptionDialog({required this.screenWidth, required this.screenHeight});

  @override
  _SubscriptionDialogState createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<SubscriptionDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.screenWidth,
      height: widget.screenHeight * 0.47,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(55),
          topRight: Radius.circular(55),
        ),
        border: Border(
          top: BorderSide(color: Color(0xFFBF0000), width: 4),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: widget.screenWidth * 0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
                left: widget.screenWidth * 0.05,
                top: widget.screenHeight * 0.03),
            child: Text(
              'Premium',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: widget.screenHeight * 0.03,
                fontWeight: FontWeight.bold,
                color: Color(0xFFBF0000),
              ),
            ),
          ),
          SizedBox(height: widget.screenHeight * 0.005),
          Padding(
            padding: EdgeInsets.only(left: widget.screenWidth * 0.05),
            child: Row(
              children: [
                Text(
                  '3.5BHD',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: widget.screenHeight * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFBF0000),
                  ),
                ),
                SizedBox(width: widget.screenWidth * 0.02),
                Text(
                  '/mo',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: widget.screenHeight * 0.03,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFBF0000),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: widget.screenHeight * 0.006),
          _buildSubscriptionFeature(
            widget.screenHeight,
            widget.screenWidth,
            'Free Delivery (3 times)',
          ),
          SizedBox(height: widget.screenHeight * 0.006),
          _buildSubscriptionFeature(
            widget.screenHeight,
            widget.screenWidth,
            '3 Vouchers (10%)',
          ),
          SizedBox(height: widget.screenHeight * 0.006),
          _buildSubscriptionFeature(
            widget.screenHeight,
            widget.screenWidth,
            'Data Analysis Feature',
          ),
          SizedBox(height: widget.screenHeight * 0.02),
          _buildSubscribeButton(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionFeature(
      double screenHeight, double screenWidth, String feature) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.01, horizontal: screenWidth * 0.13),
      child: Row(
        children: [
          Container(
            width: screenHeight * 0.025,
            height: screenHeight * 0.025,
            decoration: BoxDecoration(
              color: Color(0xFFBF0000),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: screenHeight * 0.018,
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Text(
            feature,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: screenHeight * 0.020,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton() {
    return Center(
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFBF0000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: widget.screenWidth * 0.24,
                  vertical: widget.screenHeight * 0.015,
                ),
              ),
              child: Text(
                'Subscribe',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: widget.screenHeight * 0.02,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
