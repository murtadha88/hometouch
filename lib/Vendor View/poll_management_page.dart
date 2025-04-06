import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'vendor_side_bar.dart';
import 'poll_structure_dialog.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PollPage(),
    );
  }
}

class PollPage extends StatefulWidget {
  const PollPage({super.key});

  @override
  _PollPageState createState() => _PollPageState();
}

class _PollPageState extends State<PollPage> {
  int currentMenuIndex = 0;
  Poll? activePoll;

  final TextEditingController _titleController = TextEditingController();
  List<TextEditingController> _choiceControllers = [TextEditingController()];
  final TextEditingController _questionController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 1));

  String restaurantImage = 'https://via.placeholder.com/150';
  String restaurantName = '';

  List<String> menuItems = [];

  @override
  void initState() {
    super.initState();
    fetchVendorInfo();
    fetchActivePoll().then((poll) {
      setState(() {
        activePoll = poll;
      });
    });
  }

  Future<void> fetchVendorInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final vendorDoc = await FirebaseFirestore.instance
        .collection('vendor')
        .doc(user.uid)
        .get();

    if (vendorDoc.exists) {
      final data = vendorDoc.data()!;
      setState(() {
        restaurantName = data['Name'] ?? 'My Restaurant';
        restaurantImage = data['Logo'] ?? 'https://via.placeholder.com/150';
      });
    }
  }

  void _addChoice() {
    if (_choiceControllers.length < 4) {
      setState(() {
        _choiceControllers.add(TextEditingController());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum of 4 choices allowed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeChoice(int index) {
    setState(() {
      _choiceControllers[index].dispose();
      _choiceControllers.removeAt(index);
    });
  }

  Future<void> _createPoll() async {
    if (_titleController.text.isEmpty ||
        _questionController.text.isEmpty ||
        _choiceControllers.any((c) => c.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_choiceControllers.length > 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum of 4 choices allowed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must be logged in to create a poll'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      List<Map<String, dynamic>> choices = _choiceControllers.map((controller) {
        return {
          'choice': controller.text,
          'votes': 0,
        };
      }).toList();

      await FirebaseFirestore.instance.collection('poll').add({
        'Vendor_ID': user.uid,
        'Title': _titleController.text,
        'Question': _questionController.text,
        'Choices': choices,
        'Start_Date': Timestamp.fromDate(_startDate),
        'End_Date': Timestamp.fromDate(_endDate),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Poll created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _titleController.clear();
      _questionController.clear();
      for (var c in _choiceControllers) {
        c.clear();
      }
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(Duration(days: 1));
      setState(() {
        _choiceControllers = [TextEditingController()];
        fetchActivePoll().then((poll) {
          setState(() {
            activePoll = poll;
          });
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating poll: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Poll?> fetchActivePoll() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final now = DateTime.now();
    final pollQuery = await FirebaseFirestore.instance
        .collection('poll')
        .where('Vendor_ID', isEqualTo: user.uid)
        .where('Start_Date', isLessThanOrEqualTo: now)
        .where('End_Date', isGreaterThanOrEqualTo: now)
        .limit(1)
        .get();

    if (pollQuery.docs.isNotEmpty) {
      final doc = pollQuery.docs.first;
      final pollData = doc.data();
      final choicesData = pollData['Choices'] as List<dynamic>;

      List<PollData> parsedChoices = choicesData.map((choice) {
        return PollData(choice['choice'], choice['votes']);
      }).toList();

      return Poll(
        id: doc.id,
        title: pollData['Title'],
        question: pollData['Question'],
        choices: parsedChoices,
      );
    }
    return null;
  }

  void _deletePoll() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final pollQuery = await FirebaseFirestore.instance
        .collection('poll')
        .where('Vendor_ID', isEqualTo: user.uid)
        .where('Start_Date', isLessThanOrEqualTo: now)
        .where('End_Date', isGreaterThanOrEqualTo: now)
        .limit(1)
        .get();

    if (pollQuery.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No active poll found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pollId = pollQuery.docs.first.id;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 25, horizontal: 20),
          title: Text(
            'Delete Poll',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFBF0000),
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              Container(
                alignment: Alignment.center,
                child: Text(
                  'Are you sure you want to delete the current poll?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Color(0xFFBF0000)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('poll')
                              .doc(pollId)
                              .delete();

                          setState(() {
                            activePoll = null;
                            menuItems = [];
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Poll deleted successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error deleting poll: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Yes',
                        style: TextStyle(
                          color: Color(0xFFBF0000),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFBF0000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'No',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPollDialog(BuildContext context) {
    if (activePoll == null) return;
    showDialog(
      context: context,
      builder: (context) => PollPopOut(
        restaurantName: restaurantName,
        restaurantImage: restaurantImage,
        pollQuestion: activePoll!.question,
        choices: activePoll!.choices.map((e) => e.option).toList(),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    DateTime initialDate = isStart ? _startDate : _endDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != initialDate) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFBF0000),
                ),
                alignment: Alignment.center,
                padding: EdgeInsets.only(
                  top: screenHeight * 0.001,
                  left: screenWidth * 0.02,
                ),
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: screenHeight * 0.025,
                ),
              ),
            ),
          ),
          title: Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.02),
            child: Text(
              'Poll Management',
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
              thickness: screenHeight * 0.001,
              color: Colors.grey[300],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.only(
            bottom: screenHeight * 0.02,
            left: screenWidth * 0.04,
            right: screenWidth * 0.04),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.02),
              Text("Current Poll",
                  style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: screenHeight * 0.02),
              activePoll != null
                  ? Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(screenWidth * 0.03),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: screenHeight * 0.06,
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        activePoll!.title,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.045,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Color(0xFFBF0000),
                                            size: screenWidth * 0.06),
                                        onPressed: _deletePoll,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                activePoll!.question,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              SizedBox(
                                height: screenHeight * 0.3,
                                child: SfCartesianChart(
                                  plotAreaBorderColor: Colors.white,
                                  primaryXAxis: CategoryAxis(
                                    majorTickLines: MajorTickLines(width: 0),
                                    axisLine:
                                        AxisLine(width: 1, color: Colors.white),
                                    majorGridLines: MajorGridLines(width: 0),
                                  ),
                                  primaryYAxis: NumericAxis(
                                    majorGridLines: MajorGridLines(width: 0),
                                    axisLine:
                                        AxisLine(width: 1, color: Colors.white),
                                    majorTickLines: MajorTickLines(width: 0),
                                  ),
                                  series: <CartesianSeries<PollData, String>>[
                                    ColumnSeries<PollData, String>(
                                      dataSource: activePoll!.choices,
                                      xValueMapper: (PollData data, _) =>
                                          data.option,
                                      yValueMapper: (PollData data, _) =>
                                          data.votes,
                                      dataLabelSettings:
                                          DataLabelSettings(isVisible: true),
                                      color: Color(0xFFBF0000),
                                      borderRadius: BorderRadius.circular(
                                          screenWidth * 0.03),
                                      width: 0.2,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              ElevatedButton(
                                onPressed: () => _showPollDialog(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFBF0000),
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        screenWidth * 0.03),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.02,
                                      horizontal: screenWidth * 0.04),
                                ),
                                child: Text(
                                  "Show Poll Structure",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.04),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    )
                  : Text("No active poll available.",
                      style: TextStyle(
                          color: Color(0xFFBF0000),
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.04)),
              SizedBox(height: screenHeight * 0.03),
              Text("Create Poll",
                  style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: screenHeight * 0.02),
              activePoll == null
                  ? Column(
                      children: [
                        _buildPollTextField(
                          label: 'Poll Title',
                          controller: _titleController,
                        ),
                        _buildPollTextField(
                          label: 'Poll Question',
                          controller: _questionController,
                        ),
                        ..._choiceControllers.asMap().entries.map((entry) {
                          int index = entry.key;
                          TextEditingController controller = entry.value;

                          return Padding(
                            padding:
                                EdgeInsets.only(bottom: screenHeight * 0.02),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildPollTextField(
                                    label: 'Choice ${index + 1}',
                                    controller: controller,
                                  ),
                                ),
                                if (_choiceControllers.length > 1)
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: screenWidth * 0.02),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.remove_circle,
                                        color: Color(0xFFBF0000),
                                      ),
                                      iconSize: screenWidth * 0.06,
                                      onPressed: () => _removeChoice(index),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add,
                              color: Colors.white, size: screenWidth * 0.06),
                          label: Text(
                            'Add Choice',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04),
                          ),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFBF0000),
                              padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.02,
                                  horizontal: screenWidth * 0.04)),
                          onPressed: _addChoice,
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildPollTextField(
                                    label: 'Start Date',
                                    controller: TextEditingController(
                                        text: DateFormat('yyyy-MM-dd')
                                            .format(_startDate)),
                                    isNumeric: true,
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFBF0000),
                                        padding: EdgeInsets.symmetric(
                                            vertical: screenHeight * 0.02,
                                            horizontal: screenWidth * 0.04)),
                                    child: Text('Select Start Date',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: screenWidth * 0.04)),
                                    onPressed: () => _selectDate(context, true),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildPollTextField(
                                    label: 'End Date',
                                    controller: TextEditingController(
                                        text: DateFormat('yyyy-MM-dd')
                                            .format(_endDate)),
                                    isNumeric: true,
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFBF0000),
                                        padding: EdgeInsets.symmetric(
                                            vertical: screenHeight * 0.02,
                                            horizontal: screenWidth * 0.04)),
                                    child: Text('Select End Date',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: screenWidth * 0.04)),
                                    onPressed: () =>
                                        _selectDate(context, false),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.04),
                        ElevatedButton.icon(
                          icon: Icon(Icons.poll,
                              color: Colors.white, size: screenWidth * 0.06),
                          label: Text(
                            'Create Poll',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04),
                          ),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFBF0000),
                              padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.02,
                                  horizontal: screenWidth * 0.04)),
                          onPressed: _createPoll,
                        ),
                        SizedBox(height: screenHeight * 0.04),
                      ],
                    )
                  : Container(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 246, 214, 217),
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      child: Center(
                        child: Text(
                          "Dear user, if you want to create a poll, you need to delete the current poll or wait until the duration period ends.",
                          style: TextStyle(
                              color: Color(0xFFBF0000),
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
      drawer: DrawerScreen(
        selectedIndex: currentMenuIndex,
        onItemTapped: (index) {
          setState(() {
            currentMenuIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildPollTextField({
    required String label,
    required TextEditingController controller,
    bool isNumeric = false,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: screenHeight * 0.01),
          child: Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
              color: Color(0xFFBF0000),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.02),
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
      ],
    );
  }
}

class Poll {
  final String id;
  final String title;
  final String question;
  final List<PollData> choices;

  Poll({
    required this.id,
    required this.title,
    required this.question,
    required this.choices,
  });
}

class PollData {
  final String option;
  final int votes;

  PollData(this.option, this.votes);
}
