import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:getwidget/components/button/gf_icon_button.dart';
import 'package:getwidget/getwidget.dart';

import 'package:syncfusion_flutter_xlsio/xlsio.dart' as excel;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' show AnchorElement;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'package:municipal_tracker_msunduzi/code/ImageUploading/image_upload_meter.dart';
import 'package:municipal_tracker_msunduzi/code/ImageUploading/image_upload_water.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen_prop.dart';
import 'package:municipal_tracker_msunduzi/code/PDFViewer/pdf_api.dart';
import 'package:municipal_tracker_msunduzi/code/PDFViewer/view_pdf.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/push_notification_message.dart';
import 'package:municipal_tracker_msunduzi/code/NoticePages/notice_config_screen.dart';
import 'package:url_launcher/url_launcher.dart';


class ReportBuilderFaults extends StatefulWidget {
  const ReportBuilderFaults({Key? key}) : super(key: key);

  @override
  _ReportBuilderFaultsState createState() => _ReportBuilderFaultsState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
String userID = uid as String;
DateTime now = DateTime.now();

String phoneNum = ' ';

String accountNumberAll = ' ';
String locationGivenAll = ' ';
String eMeterNumber = ' ';
String accountNumberW = ' ';
String locationGivenW = ' ';
String wMeterNumber = ' ';

String propPhoneNum = ' ';

bool visibilityState1 = true;
bool visibilityState2 = false;
bool adminAcc = false;
bool imgUploadCheck = false;

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier{
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async{
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

class _ReportBuilderFaultsState extends State<ReportBuilderFaults> {

  @override
  void initState() {
    if(_searchController.text == ""){
      getFaultStream();
    }
    // getPropertyStream();
    checkAdmin();
    _searchController.addListener(_onSearchChanged);
    super.initState();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    searchText;
    _allFaultResults;
    _allFaultReport;
    super.dispose();
  }

  void checkAdmin() {
    String? emailLogged = user?.email.toString();
    if(emailLogged?.contains("admin") == true){
      adminAcc = true;
    } else {
      adminAcc = false;
    }
  }

  String accountNumberRep = '';
  String locationGivenRep = '';
  int faultStage = 0;
  String reporterCellGiven = '';
  String searchText = '';

  String formattedDate = DateFormat.MMMM().format(now);

  List<String> usersNumbers =[];
  List<String> usersTokens =[];
  List<String> usersRetrieve =[];

  ///Methods and implementation for push notifications with firebase and specific device token saving
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  TextEditingController username = TextEditingController();
  TextEditingController title = TextEditingController();
  TextEditingController body = TextEditingController();
  String? mtoken = " ";

  ///This was made for testing a default message
  String title2 = "Outstanding Utilities Payment";
  String body2 = "Make sure you pay utilities before the end of this month or your services will be disconnected";

  String token = '';
  String notifyToken = '';

  bool visShow = true;
  bool visHide = false;
  bool adminAcc = false;

  int numTokens=0;

  String dropdownValue = 'Select Month';
  List<String> dropdownMonths = ['Select Month','January','February','March','April','May','June','July','August','September','October','November','December'];

  TextEditingController _searchController = TextEditingController();
  List _allFaultResults = [];
  List _allFaultReport = [];

  getFaultStream() async{
    var data = await FirebaseFirestore.instance.collection('faultReporting').get();

    setState(() {
      _allFaultResults = data.docs;
    });
    searchResultsList();
  }

  _onSearchChanged() async {
    searchResultsList();
  }

  searchResultsList() async {
    var showResults = [];
    if(_searchController.text != "") {
      getFaultStream();
      for(var faultSnapshot in _allFaultResults){
        ///Need to build a property model that retrieves property data entirely from the db
        var reference = faultSnapshot['ref'].toString().toLowerCase();

        if(reference.contains(_searchController.text.toLowerCase())) {
          showResults.add(faultSnapshot);
        }
      }
    } else {
      getFaultStream();
      showResults = List.from(_allFaultResults);
    }
    setState(() {
      _allFaultResults = showResults;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Fault Report Generator',style: TextStyle(color: Colors.white),),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.green,
        actions: <Widget>[
          Visibility(
            visible: false,
            child: IconButton(
                onPressed: (){
                  ///Generate Report here
                  showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Generate Live Report"),
                          content: const Text("Generating a report will go through all properties and build an excel Spreadsheet!\n\nThis process will take time based on your internet speed.\n\nAre you ready to proceed? This may take a few minutes."),
                          actions: [
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.cancel, color: Colors.red,),
                            ),
                            IconButton(
                              onPressed: () async {
                                Fluttertoast.showToast(msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
                                reportGeneration();
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.done, color: Colors.green,),
                            ),
                          ],
                        );
                      });
                },
                icon: const Icon(Icons.file_copy_outlined, color: Colors.white,)),),
        ],
      ),
      body: Column(
        children: [
          /// Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0,10.0,10.0,10.0),
            child: SearchBar(
              controller: _searchController,
              padding: const MaterialStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 16.0)),
              leading: const Icon(Icons.search),
              hintText: "Search by Reference Number...",
              onChanged: (value) async{
                setState(() {
                  searchText = value;
                  // print('this is the input text ::: $searchText');
                });
              },
            ),
          ),
          /// Search bar end

          Expanded(child: faultCard(),),

          const SizedBox(height: 5,),
        ],
      ),
      /// Add new account, removed because it was not necessary for non-staff users.
        floatingActionButton: FloatingActionButton(
          onPressed: () => {
            ///Generate Report here
            showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Generate Live Report"),
                    content: const Text(
                        "Generating a report will go through all properties and build an excel Spreadsheet!\n\nThis process will take time based on your internet speed.\n\nAre you ready to proceed? This may take a few minutes."),
                    actions: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.cancel, color: Colors.red,),
                      ),
                      IconButton(
                        onPressed: () async {
                          Fluttertoast.showToast(
                              msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
                          reportGeneration();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.done, color: Colors.green,
                        ),
                      ),
                    ],
                  );
                })
          },
          backgroundColor: Colors.green,
          child: const Icon(Icons.file_copy_outlined, color: Colors.white,),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat

    );
  }

  Widget faultCard(){
    if (_allFaultResults.isNotEmpty) {
      return ListView.builder(
        itemCount: _allFaultResults.length,
        itemBuilder: (context, index) {
          return Card(margin: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Fault Information',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 10,),

                  Text(
                    'Reference Number: ${_allFaultResults[index]['ref']}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),

                  Column(
                    children: [
                      if(_allFaultResults[index]['accountNumber'] !=
                          "")...[
                        Text(
                          'Reporter Account Number: ${_allFaultResults[index]['accountNumber']}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5,),
                      ] else
                        ...[
                        ],
                    ],
                  ),
                  Text(
                    'Street Address of Fault: ${_allFaultResults[index]['address']}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'Fault Type: ${_allFaultResults[index]['faultType']}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Column(
                    children: [
                      if(_allFaultResults[index]['faultDescription'] !=
                          "")...[
                        Text(
                          'Fault Description: ${_allFaultResults[index]['faultDescription']}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5,),
                      ] else
                        ...[
                        ],
                    ],
                  ),
                  Column(
                    children: [
                      if(_allFaultResults[index]['handlerCom1'] != "")...[
                        Text(
                          'Handler Comment: ${_allFaultResults[index]['handlerCom1']}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5,),
                      ] else
                        ...[
                        ],
                    ],
                  ),
                  Column(
                    children: [
                      if(_allFaultResults[index]['depComment1'] != "")...[
                        Text(
                          'Department Comment 1: ${_allFaultResults[index]['depComment1']}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5,),
                      ] else
                        ...[
                        ],
                    ],
                  ),
                  Column(
                    children: [
                      if(_allFaultResults[index]['handlerCom2'] != "")...[
                        Text(
                          'Handler Final Comment: ${_allFaultResults[index]['handlerCom2']}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5,),
                      ] else
                        ...[
                        ],
                    ],
                  ),
                  Column(
                    children: [
                      if(_allFaultResults[index]['depComment2'] != "")...[
                        Text(
                          'Department Final Comment: ${_allFaultResults[index]['depComment2']}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5,),
                      ] else
                        ...[
                        ],
                    ],
                  ),
                  Text(
                    'Resolve State: ${_allFaultResults[index]['faultResolved'].toString()}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'Date of Fault Report: ${_allFaultResults[index]['dateReported']}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 20,),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              accountNumberRep = _allFaultResults[index]['accountNumber'];
                              locationGivenRep = _allFaultResults[index]['address'];

                              Navigator.push(context, MaterialPageRoute(builder: (context) =>
                                          MapScreenProp(propAddress: locationGivenRep, propAccNumber: accountNumberRep,)
                              ));
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[350], fixedSize: const Size(140, 10),),
                            child: Row(
                              children: [
                                Icon(Icons.map, color: Colors.green[700],),
                                const SizedBox(width: 2,),
                                const Text(
                                  'Location', style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,),),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5,),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (context) {
                                    return
                                      AlertDialog(
                                        shape: const RoundedRectangleBorder(borderRadius:BorderRadius.all(Radius.circular(16))),
                                        title: const Text("Call Reporter!"),
                                        content: const Text("Would you like to call the individual who logged the fault?"),
                                        actions: [
                                          IconButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            icon: const Icon(Icons.cancel, color: Colors.red,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              reporterCellGiven = _allFaultResults[index]['reporterContact'];

                                              final Uri _tel = Uri.parse('tel:${reporterCellGiven.toString()}');
                                              launchUrl(_tel);

                                              Navigator.of(context).pop();
                                            },
                                            icon: const Icon(Icons.done, color: Colors.green,),
                                          ),
                                        ],
                                      );
                                  });
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[350], fixedSize: const Size(140, 10),),
                            child: Row(
                              children: [
                                Icon(Icons.call, color: Colors.orange[700],),
                                const SizedBox(width: 2,),
                                const Text('Call User', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black,),),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5,),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    return const Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(
          child: CircularProgressIndicator()),
    );

  }

  Future<void> reportGeneration() async {
    final excel.Workbook workbook = excel.Workbook();
    final excel.Worksheet sheet = workbook.worksheets[0];

    var data = await FirebaseFirestore.instance.collection('faultReporting').get();

    _allFaultReport = data.docs;

    String column = "A";
    int excelRow = 1;
    int listRow = 0;

    for(var reportSnapshot in _allFaultReport){
      ///Need to build a property model that retrieves property data entirely from the db
      while(excelRow <= _allFaultReport.length) {

        print('Report Lists:::: ${_allFaultReport[listRow]['address']}');
        String referenceNum     = _allFaultReport[listRow]['ref'].toString();
        String accountNum       = _allFaultReport[listRow]['accountNumber'].toString();
        String address          = _allFaultReport[listRow]['address'].toString();
        String faultDate        = _allFaultReport[listRow]['dateReported'].toString();
        String faultType        = _allFaultReport[listRow]['faultType'].toString();
        String faultDescription = _allFaultReport[listRow]['faultDescription'].toString();
        String faultHandler     = _allFaultReport[listRow]['deptHandler'].toString();
        String faultStage       = _allFaultReport[listRow]['faultStage'].toString();
        String resolveStatus    = _allFaultReport[listRow]['faultResolved'].toString();
        String phoneNumber      = _allFaultReport[listRow]['reporterContact'].toString();
        String depCom1          = _allFaultReport[listRow]['depComment1'].toString();
        String handlerCom1      = _allFaultReport[listRow]['handlerCom1'].toString();
        String depCom2          = _allFaultReport[listRow]['depComment2'].toString();
        String handlerCom2      = _allFaultReport[listRow]['handlerCom2'].toString();
        String depCom3          = _allFaultReport[listRow]['depComment3'].toString();

        sheet.getRangeByName('A$excelRow').setText(referenceNum);
        sheet.getRangeByName('B$excelRow').setText(accountNum);
        sheet.getRangeByName('C$excelRow').setText(address);
        sheet.getRangeByName('D$excelRow').setText(faultDate);
        sheet.getRangeByName('E$excelRow').setText(faultType);
        sheet.getRangeByName('F$excelRow').setText(faultDescription);
        sheet.getRangeByName('G$excelRow').setText(faultHandler);
        sheet.getRangeByName('H$excelRow').setText(faultStage);
        sheet.getRangeByName('I$excelRow').setText(resolveStatus);
        sheet.getRangeByName('J$excelRow').setText(phoneNumber);
        sheet.getRangeByName('K$excelRow').setText(depCom1);
        sheet.getRangeByName('L$excelRow').setText(handlerCom1);
        sheet.getRangeByName('M$excelRow').setText(depCom2);
        sheet.getRangeByName('N$excelRow').setText(handlerCom2);
        sheet.getRangeByName('O$excelRow').setText(depCom3);

        excelRow+=1;
        listRow+=1;
      }
    }

    final List<int> bytes = workbook.saveAsStream();
    ///File path managing on android
    // final Directory? directory = await getExternalStorageDirectory();
    //Get directory path
    // final String? path = directory?.path;

    if(kIsWeb){
      AnchorElement(href: 'data:application/ocelot-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
          ..setAttribute('download', 'Msunduzi Faults Report $formattedDate.xlsx')
          ..click();

    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      final String filename = Platform.isWindows ? '$path\\Msunduzi Faults Report $formattedDate.xlsx' : '$path/Msunduzi Faults Report $formattedDate.xlsx';
      final File file = File(filename);
      final List<int> bytes = workbook.saveAsStream();
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open('$path/Msunduzi Faults Report $formattedDate.xlsx');
    }

    // final String path = (await getApplicationSupportDirectory()).path;
    // //Create an empty file to write Excel data
    // final File file = File('$path/Msunduzi Property Reports.xlsx');
    // //Write Excel data
    // await file.writeAsBytes(bytes, flush: true);
    // //Launch the file (used open_file package)
    // await OpenFile.open('$path/Msunduzi Property Reports.xlsx');
    // File('Msunduzi Property Reports.xlsx').writeAsBytes(bytes);

    workbook.dispose();

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

  ///pdf view loader getting file name onPress/onTap that passes pdf filename to this class.
  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
  );
}