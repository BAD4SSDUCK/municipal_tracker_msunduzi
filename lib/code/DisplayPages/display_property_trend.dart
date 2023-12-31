import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:municipal_tracker_msunduzi/code/DisplayPages/display_info.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:municipal_tracker_msunduzi/code/PDFViewer/pdf_api.dart';
import 'package:municipal_tracker_msunduzi/code/PDFViewer/view_pdf.dart';
import 'package:municipal_tracker_msunduzi/code/Chat/chat_screen_finance.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/icon_elevated_button.dart';


class PropertyTrend extends StatefulWidget {
  PropertyTrend({Key? key, required this.addressTarget}) : super(key: key);

  final String addressTarget;

  @override
  _PropertyTrendState createState() => _PropertyTrendState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

DateTime now = DateTime.now();
int monthNum = 1;

final User? user = auth.currentUser;
final uid = user?.uid;
final phone = user?.phoneNumber;
final email = user?.email;
String userID = uid as String;

String locationGiven = ' ';

bool visibilityState1 = true;
bool visibilityState2 = false;

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier{
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async{
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

class _PropertyTrendState extends State<PropertyTrend> {

  final user = FirebaseAuth.instance.currentUser!;

  String formattedMonth = DateFormat.MMMM().format(now);//format for full Month by name
  String formattedDateMonth = DateFormat.MMMMd().format(now);//format for Day Month only

  final CollectionReference _propList =
  FirebaseFirestore.instance.collection('properties');

  String formattedDate = DateFormat.MMMM().format(now);

  String dropdownValue = 'Select Month';
  List<String> dropdownMonths = ['Select Month','January','February','March','April','May','June','July','August','September','October','November','December'];
  List<String> consumptionMonthRetrieve =[];
  List<String> consumptionElectricityReadings =[];
  List<String> consumptionWaterReadings =[];
  late String consumptionProp;
  List<String> consumptionPropRetrieve =[];
  List _allPropertyConsumption = [];

  @override
  void initState() {
    if(defaultTargetPlatform == TargetPlatform.android){
      String userPhone = phone as String;
    } else {
      String userEmail = email as String;
    }
    setMonthLimits(formattedDate);
    getCollectionData();
    loadConsumptionData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Property Reading Trend',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
      Column(
        children: [
          const SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0.0,horizontal: 15.0),
            child: Column(
                children: [
                  SizedBox(
                    width: 400,
                    height: 50,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Center(
                        child: TextField(
                          ///Input decoration here had to be manual because dropdown button uses suffix icon of the textfield
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    30),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                )
                            ),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    30),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                )
                            ),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    30),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                )
                            ),
                            disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    30),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                )
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6
                            ),
                            fillColor: Colors.white,
                            filled: true,
                            suffixIcon: DropdownButtonFormField <String>(
                              value: dropdownValue,
                              items: dropdownMonths
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
                                    child: Text(
                                      value,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  dropdownValue = newValue!;
                                });
                              },
                              icon: const Padding(
                                padding: EdgeInsets.only(left: 10, right: 10),
                                child: Icon(Icons.arrow_circle_down_sharp),
                              ),
                              iconEnabledColor: Colors.green,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18
                              ),
                              dropdownColor: Colors.grey[50],
                              isExpanded: true,

                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]
            ),
          ),

          const SizedBox(height: 5,),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: SfCartesianChart(
                  // series: <ChartSeries>[
                  //   LineSeries<ConsumptionData, double>(dataSource: _allPropertyConsumption,
                  //   xValueMapper: (ConsumptionData consumption, _) => consumption.address,
                  //   yValueMapper: (ConsumptionData consumption, _) => consumption.meterReading)
                  // ],


                ),
              ),
            ),
          ),

          firebasePropertyCard(_propList),

          // propertyConsumptionCard(),

        ],
      ),
    );
  }

  Widget firebasePropertyCard(CollectionReference<Object?> propertyDataStream){
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: propertyDataStream.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              ///this call is to display all details for all users but is only displaying for the current user account.
              ///it can be changed to display all users for the staff to see if the role is set to all later on.
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];

                ///Check for only user information, this displays only for the users details and not all users in the database.
                if(streamSnapshot.data!.docs[index]['address'] == widget.addressTarget) {
                  return Card(
                    margin: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Property Data',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            Text(
                              'Account Number: ${documentSnapshot['account number']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Street Address: ${documentSnapshot['address']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Area Code: ${documentSnapshot['area code']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 20,),

                          ]
                      ),
                    ),
                  );
                }///end of single user information display.
                else {
                  return const SizedBox(height: 0, width: 0,);
                }
              },
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  ///To add the card
  Widget propertyConsumptionCard(){

    // final CollectionReference _propMonthReadings = FirebaseFirestore.instance
    //     .collection('consumption').doc(formattedMonth)
    //     .collection('address').doc(widget.addressTarget) as CollectionReference<Object?>;
    // final propertyRef = FirebaseFirestore.instance.collectionGroup('consumption').get();

    return Expanded(
      child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('consumption')
            .doc(formattedMonth)
            .collection('address').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data!.docs.isEmpty) {
              return const Card(
                margin: EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 5),
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Readings not taken for this month',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              );
            } else if (snapshot.hasData) {

              // print(snapshot);
              return Card(
                margin: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Property Readings for ${snapshot.data?.docs[monthNum][formattedMonth]}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 10,),
                        Text(
                          'Address: ${snapshot.data?.docs[monthNum]['address']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5,),
                        Text(
                          'Electricity Meter Reading Address: ${snapshot.data?.docs[monthNum]['address']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5,),
                        Text(
                          'Area Code: ${snapshot.data?.docs[monthNum]['area code']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 20,),

                      ]
                  ),
                ),

              );
            }
          }
          return const SizedBox(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }


  Future getCollectionData() async {

    loadConsumptionData();

    for(var propSnapshot in _allPropertyConsumption){

      await FirebaseFirestore.instance
          .collection('consumption')
          .doc().collection('address')
          .get()
          .then((QuerySnapshot snapshot) {
        final docs = snapshot.docs;
        for (var data in docs) {
          consumptionMonthRetrieve.add(data.id);
          _allPropertyConsumption.add(docs.single);

          print('Retrieved consumption test::: $consumptionMonthRetrieve');
          print('Retrieved consumption test2::: $_allPropertyConsumption');
          print('Retrieved month id test::: ${data.id}');
        }

      });

      ///Need to build a property model that retrieves property data entirely from the db
      var electricity = propSnapshot['meter reading'].toString();
      var water = propSnapshot['water meter reading'].toString();

      print('Retrieved reading :::: $electricity');

      consumptionElectricityReadings.add(electricity);
      consumptionWaterReadings.add(water);

    }

    print('Retrieved consumption ID/month:::: $consumptionMonthRetrieve');
    print('Retrieved consumption address:::: $consumptionPropRetrieve');
    print('Retrieved consumption Electricity:::: $consumptionElectricityReadings');
    print('Retrieved consumption Water:::: $consumptionWaterReadings');

  }

  loadConsumptionData() async {
      List consumptionPropRetrieve = await FirebaseFirestore.instance.collection("consumption")
          .get()
          .then((val) => val.docs);
      for (int i=0; i<dropdownMonths.length; i++)
      {
        FirebaseFirestore.instance.collection("consumption").doc(
            consumptionPropRetrieve[i].toString()).collection(widget.addressTarget).snapshots().listen(CreateListofCconsumption);
      }
  }

  CreateListofCconsumption(QuerySnapshot snapshot) async {
    var docs = snapshot.docs;
    for (var Doc in docs)
    {
      _allPropertyConsumption.add(ConsumptionData.fromFireStore(Doc));
    }

    print('hhi $_allPropertyConsumption');
  }

  void setMonthLimits(String currentMonth) {
    String month1 = 'January';
    String month2 = 'February';
    String month3 = 'March';
    String month4 = 'April';
    String month5 = 'May';
    String month6 = 'June';
    String month7 = 'July';
    String month8 = 'August';
    String month9 = 'September';
    String month10 = 'October';
    String month11 = 'November';
    String month12 = 'December';


    switch(formattedMonth){
      case 'January': monthNum = 1; break;
      case 'February': monthNum = 2; break;
      case 'March': monthNum = 3; break;
      case 'April': monthNum = 4; break;
      case 'May': monthNum = 5; break;
      case 'June': monthNum = 6; break;
      case 'July': monthNum = 7; break;
      case 'August': monthNum = 8; break;
      case 'September': monthNum = 9; break;
      case 'October': monthNum = 10; break;
      case 'November': monthNum = 11; break;
      case 'December': monthNum = 12; break;
    }

    print('current month numbered is:::: $monthNum');

    if (currentMonth.contains(month1)) {
      dropdownMonths = ['Select Month', month10,month11,month12,currentMonth,];
    } else if (currentMonth.contains(month2)) {
      dropdownMonths = ['Select Month', month11,month12,month1,currentMonth,];
    } else if (currentMonth.contains(month3)) {
      dropdownMonths = ['Select Month', month12,month1,month2,currentMonth,];
    } else if (currentMonth.contains(month4)) {
      dropdownMonths = ['Select Month', month1,month2,month3,currentMonth,];
    } else if (currentMonth.contains(month5)) {
      dropdownMonths = ['Select Month', month2,month3,month4,currentMonth,];
    } else if (currentMonth.contains(month6)) {
      dropdownMonths = ['Select Month', month3,month4,month5,currentMonth,];
    } else if (currentMonth.contains(month7)) {
      dropdownMonths = ['Select Month', month4,month5,month6,currentMonth,];
    } else if (currentMonth.contains(month8)) {
      dropdownMonths = ['Select Month', month5,month6,month7,currentMonth,];
    } else if (currentMonth.contains(month9)) {
      dropdownMonths = ['Select Month', month6,month7,month8,currentMonth,];
    } else if (currentMonth.contains(month10)) {
      dropdownMonths = ['Select Month', month7,month8,month9,currentMonth,];
    } else if (currentMonth.contains(month11)) {
      dropdownMonths = ['Select Month', month8,month9,month10,currentMonth,];
    } else if (currentMonth.contains(month12)) {
      dropdownMonths = ['Select Month', month9,month10,month11,currentMonth,];
    } else {
      dropdownMonths = [
        'Select Month',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
    }
  }

}

class ConsumptionData {

  final String month;
  final String address;
  final String meterReading;
  final String waterReading;

  ConsumptionData({required this.month, required this.address, required this.meterReading, required this.waterReading});
  factory ConsumptionData.fromFireStore(DocumentSnapshot doc) {

    Map data = doc.data as Map<String, dynamic> ;
    return ConsumptionData(
        month: doc.id,
        address: data['address'],
        meterReading: data['meter reading'],
        waterReading: data['water meter reading'],
    );

  }
}