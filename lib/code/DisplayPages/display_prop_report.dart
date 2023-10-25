import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:getwidget/components/button/gf_icon_button.dart';
import 'package:getwidget/getwidget.dart';
import 'package:open_file/open_file.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as excel;
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


class ReportBuilderProps extends StatefulWidget {
  const ReportBuilderProps({Key? key}) : super(key: key);

  @override
  _ReportBuilderPropsState createState() => _ReportBuilderPropsState();
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

Future<Widget> _getImage(BuildContext context, String imageName) async{
  Image image;
  final value = await FireStorageService.loadImage(context, imageName);

  final imageUrl = await storageRef.child(imageName).getDownloadURL();

  if (imageUrl.contains('.jpg')||imageUrl.contains('.JPG')){
    imgUploadCheck = true;
  } else {
    imgUploadCheck = false;
  }

  ///Check what the app is running on
  if(defaultTargetPlatform == TargetPlatform.android){
    image =Image.network(
      value.toString(),
      fit: BoxFit.fill,
      width: double.infinity,
      height: double.infinity,
    );
  }else{
    // print('The url is::: $imageUrl');
    image =Image.network(
      imageUrl,
      fit: BoxFit.fitHeight,
      width: double.infinity,
      height: double.infinity,
    );
  }
  ///android version display image from firebase
  // image =Image.network(
  //   value.toString(),
  //   fit: BoxFit.fill,
  //   width: double.infinity,
  //   height: double.infinity,
  // );
  return image;
}

Future<Widget> _getImageW(BuildContext context, String imageName2) async{
  Image image2;
  final value = await FireStorageService.loadImage(context, imageName2);

  final imageUrl = await storageRef.child(imageName2).getDownloadURL();

  if (imageUrl.contains('.jpg')||imageUrl.contains('.JPG')){
    imgUploadCheck = true;
  } else {
    imgUploadCheck = false;
  }

  ///Check what the app is running on
  if(defaultTargetPlatform == TargetPlatform.android){
    image2 =Image.network(
      value.toString(),
      fit: BoxFit.fill,
      width: double.infinity,
      height: double.infinity,
    );
  }else{
    // print('The url is::: $imageUrl');
    image2 =Image.network(
      value.toString(),
      fit: BoxFit.fitHeight,
      width: double.infinity,
      height: double.infinity,
    );
  }
  return image2;
}

final CollectionReference _propList =
FirebaseFirestore.instance.collection('properties');

class _ReportBuilderPropsState extends State<ReportBuilderProps> {

  @override
  void initState() {
    if(_searchController.text == ""){
      getPropertyStream();
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
    _allPropertyResults;
    _allPropertyReport;
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

  // text fields' controllers
  final _accountNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaCodeController = TextEditingController();
  final _meterNumberController = TextEditingController();
  final _meterReadingController = TextEditingController();
  final _waterMeterController = TextEditingController();
  final _waterMeterReadingController = TextEditingController();
  final _cellNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idNumberController = TextEditingController();

  String searchText = '';

  String formattedDate = DateFormat.MMMM().format(now);

  final CollectionReference _listUserTokens =
  FirebaseFirestore.instance.collection('UserToken');

  final CollectionReference _listNotifications =
  FirebaseFirestore.instance.collection('Notifications');

  final _headerController = TextEditingController();
  final _messageController = TextEditingController();

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
  List _allPropertyResults = [];
  List _allPropertyReport = [];

  getPropertyStream() async{
    var data = await FirebaseFirestore.instance.collection('properties').get();

    setState(() {
      _allPropertyResults = data.docs;
    });

    _allPropertyReport = data.docs;

    searchResultsList();
  }

  _onSearchChanged() async {
    searchResultsList();
  }

  searchResultsList() async {
    var showResults = [];
    getPropertyStream();
    if(_searchController.text != "") {
      for(var propSnapshot in _allPropertyResults){
        ///Need to build a property model that retrieves property data entirely from the db
        var address = propSnapshot['address'].toString().toLowerCase();

        if(address.contains(_searchController.text.toLowerCase())) {
          showResults.add(propSnapshot);
        }
      }
    } else {
      getPropertyStream();
      showResults = List.from(_allPropertyResults);
    }
    setState(() {
      getPropertyStream();
      _allPropertyResults = showResults;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Report Generator',style: TextStyle(color: Colors.white),),
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
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.red,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                Fluttertoast.showToast(msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
                                reportGeneration();
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.done,
                                color: Colors.green,
                              ),
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
              hintText: "Search by Address...",
              onChanged: (value) async{
                setState(() {
                  searchText = value;
                  // print('this is the input text ::: $searchText');
                });
              },
            ),
          ),
          /// Search bar end

          // firebasePropertyCard(_propList),

          Expanded(
              child: propertyCard(),
          ),

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
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.red,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          Fluttertoast.showToast(
                              msg: "Now generating report\nPlease wait till prompted to open Spreadsheet!");
                          reportGeneration();
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.done,
                          color: Colors.green,
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

  Widget propertyCard() {
    if (_allPropertyResults.isNotEmpty) {
    return ListView.builder(
      ///this call is to display all details for all users but is only displaying for the current user account.
      ///it can be changed to display all users for the staff to see if the role is set to all later on.
      itemCount: _allPropertyResults.length,
      itemBuilder: (context, index) {

        eMeterNumber = _allPropertyResults[index]['meter number'];
        wMeterNumber = _allPropertyResults[index]['water meter number'];
        propPhoneNum = _allPropertyResults[index]['cell number'];
        
        bool vis$index = false;

        String billMessage;///A check for if payment is outstanding or not
        if(_allPropertyResults[index]['eBill'] != '' ||
            _allPropertyResults[index]['eBill'] != 'R0,000.00' ||
            _allPropertyResults[index]['eBill'] != 'R0.00' ||
            _allPropertyResults[index]['eBill'] != 'R0' ||
            _allPropertyResults[index]['eBill'] != '0'
        ){
          billMessage = 'Utilities bill outstanding: ${_allPropertyResults[index]['eBill']}';
        } else {
          billMessage = 'No outstanding payments';
        }

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
                      'Property Information',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 10,),
                  Text(
                    'Account Number: ${_allPropertyResults[index]['account number']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'Street Address: ${_allPropertyResults[index]['address']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'Area Code: ${_allPropertyResults[index]['area code']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'Meter Number: ${_allPropertyResults[index]['meter number']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'Meter Reading: ${_allPropertyResults[index]['meter reading']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'Water Meter Number: ${_allPropertyResults[index]['water meter number']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'Water Meter Reading: ${_allPropertyResults[index]['water meter reading']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'Phone Number: ${_allPropertyResults[index]['cell number']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'First Name: ${_allPropertyResults[index]['first name']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'Surname: ${_allPropertyResults[index]['last name']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    'ID Number: ${_allPropertyResults[index]['id number']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5,),
                  Text(
                    billMessage,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 10,),

                ],
              ),
            ),
          );
      },
    );
    } return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Future<void> updateImgCheckE(bool imgCheck, [DocumentSnapshot? documentSnapshot]) async{
    if (documentSnapshot != null) {
      await _propList
          .doc(documentSnapshot.id)
          .update({
        "imgStateE": imgCheck,
      });
    }
    imgCheck = false;
  }

  Future<void> updateImgCheckW(bool imgCheck, [DocumentSnapshot? documentSnapshot]) async{
    if (documentSnapshot != null) {
      await _propList
          .doc(documentSnapshot.id)
          .update({
        "imgStateW": imgCheck,
      });
    }
    imgCheck = false;
  }

  Future<void> _notifyThisUser([DocumentSnapshot? documentSnapshot]) async {

    if (documentSnapshot != null) {
      username.text = documentSnapshot.id;
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async{
      Future<void> future = showModalBottomSheet(
          context: context,
          builder: await showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (BuildContext ctx) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: 20,
                            left: 20,
                            right: 20,
                            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Visibility(
                              visible: visShow,
                              child: TextField(
                                controller: title,
                                decoration: const InputDecoration(
                                    labelText: 'Message Header'),
                              ),
                            ),
                            Visibility(
                              visible: visShow,
                              child: TextField(
                                controller: body,
                                decoration: const InputDecoration(
                                    labelText: 'Message'),
                              ),
                            ),

                            const SizedBox(
                              height: 10,
                            ),
                            ElevatedButton(
                                child: const Text('Send Notification'),
                                onPressed: () async {

                                  DateTime now = DateTime.now();
                                  String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);



                                  final String tokenSelected = notifyToken;
                                  final String? userNumber = documentSnapshot?.id;
                                  final String notificationTitle = title.text;
                                  final String notificationBody = body.text;
                                  final String notificationDate = formattedDate;
                                  const bool readStatus = false;

                                  if (tokenSelected != null) {
                                    if(title.text != '' || title.text.isNotEmpty || body.text != '' || body.text.isNotEmpty) {
                                      await _listNotifications.add({
                                        "token": tokenSelected,
                                        "user": userNumber,
                                        "title": notificationTitle,
                                        "body": notificationBody,
                                        "read": readStatus,
                                        "date": notificationDate,
                                        "level": 'severe',
                                      });

                                      ///It can be changed to the firebase notification
                                      String titleText = title.text;
                                      String bodyText = body.text;

                                      ///gets users phone token to send notification to this phone
                                      if (userNumber != "") {
                                        DocumentSnapshot snap = await FirebaseFirestore.instance.collection("UserToken").doc(userNumber).get();
                                        String token = snap['token'];
                                        print('The phone number is retrieved as ::: $userNumber');
                                        print('The token is retrieved as ::: $token');
                                        sendPushMessage(token, titleText, bodyText);
                                        Fluttertoast.showToast(msg: 'The user has been sent the notification!', gravity: ToastGravity.CENTER);
                                      }
                                    } else {
                                      Fluttertoast.showToast(msg: 'Please Fill Header and Message of the notification!', gravity: ToastGravity.CENTER);
                                    }
                                  }

                                  username.text =  '';
                                  title.text =  '';
                                  body.text =  '';
                                  _headerController.text =  '';
                                  _messageController.text =  '';

                                  if(context.mounted)Navigator.of(context).pop();

                                }
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              }));
    }

    _createBottomSheet();

  }


  Widget firebasePropertyCard(CollectionReference<Object?> propertiesDataStream) {
    return Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: propertiesDataStream.snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
            if (streamSnapshot.hasData) {
              return ListView.builder(
                ///this call is to display all details for all users but is only displaying for the current user account.
                ///it can be changed to display all users for the staff to see if the role is set to all later on.
                itemCount: streamSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final DocumentSnapshot documentSnapshot =
                  streamSnapshot.data!.docs[index];

                  eMeterNumber = documentSnapshot['meter number'];
                  wMeterNumber = documentSnapshot['water meter number'];
                  propPhoneNum = documentSnapshot['cell number'];

                  String billMessage;///A check for if payment is outstanding or not
                  if(documentSnapshot['eBill'] != '' ||
                      documentSnapshot['eBill'] != 'R0,000.00' ||
                      documentSnapshot['eBill'] != 'R0.00' ||
                      documentSnapshot['eBill'] != 'R0' ||
                      documentSnapshot['eBill'] != '0'
                  ){
                    billMessage = 'Utilities bill outstanding: ${documentSnapshot['eBill']}';
                  } else {
                    billMessage = 'No outstanding payments';
                  }

                  if(((documentSnapshot['address'].trim()).toLowerCase()).contains((_searchController.text.trim()).toLowerCase())){
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
                                'Property Information',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            Text(
                              'Account Number: ${documentSnapshot['account number']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Street Address: ${documentSnapshot['address']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Area Code: ${documentSnapshot['area code']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Meter Number: ${documentSnapshot['meter number']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Meter Reading: ${documentSnapshot['meter reading']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Water Meter Number: ${documentSnapshot['water meter number']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Water Meter Reading: ${documentSnapshot['water meter reading']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Phone Number: ${documentSnapshot['cell number']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'First Name: ${documentSnapshot['first name']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Surname: ${documentSnapshot['last name']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'ID Number: ${documentSnapshot['id number']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 20,),

                            const Center(
                              child: Text(
                                'Electricity Meter Reading Photo',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 5,),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        eMeterNumber = documentSnapshot['meter number'];
                                        propPhoneNum = documentSnapshot['cell number'];
                                        showDialog(
                                            barrierDismissible: false,
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text("Upload Electricity Meter"),
                                                content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
                                                actions: [
                                                  IconButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    icon: const Icon(
                                                      Icons.cancel,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () async {
                                                      Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
                                                      Navigator.push(context,
                                                          MaterialPageRoute(builder: (context) => ImageUploadMeter(userNumber: propPhoneNum, meterNumber: eMeterNumber,)));
                                                    },
                                                    icon: const Icon(
                                                      Icons.done,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            });
                                      },
                                      labelText: 'Photo',
                                      fSize: 16,
                                      faIcon: const FaIcon(Icons.camera_alt,),
                                      fgColor: Colors.black38,
                                      btSize: const Size(100, 38),
                                    ),
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        _updateE(documentSnapshot);
                                      },
                                      labelText: 'Capture',
                                      fSize: 16,
                                      faIcon: const FaIcon(Icons.edit,),
                                      fgColor: Theme.of(context).primaryColor,
                                      btSize: const Size(100, 38),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            ///Image display item needs to get the reference from the firestore using the users uploaded meter connection
                            InkWell(
                              ///onTap allows to open image upload page if user taps on the image.
                              ///Can be later changed to display the picture zoomed in if user taps on it.
                              onTap: () {
                                eMeterNumber = documentSnapshot['meter number'];
                                propPhoneNum = documentSnapshot['cell number'];
                                showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text("Upload Electricity Meter"),
                                    content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
                                    actions: [
                                      IconButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        icon: const Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
                                          Navigator.push(context,
                                              MaterialPageRoute(builder: (context) => ImageUploadMeter(userNumber: propPhoneNum, meterNumber: eMeterNumber,)));
                                        },
                                        icon: const Icon(
                                          Icons.done,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  );
                                });
                              },

                              child: Center(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 5),
                                  // height: 300,
                                  // width: 300,
                                  child: Center(
                                    child: Card(
                                      color: Colors.grey,
                                      semanticContainer: true,
                                      clipBehavior: Clip.antiAliasWithSaveLayer,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                      elevation: 0,
                                      margin: const EdgeInsets.all(10.0),
                                      child: FutureBuilder(
                                          future: _getImage(
                                            ///Firebase image location must be changed to display image based on the meter number
                                              context, 'files/meters/$formattedDate/$propPhoneNum/electricity/$eMeterNumber.jpg'),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasError) {
                                              imgUploadCheck = false;
                                              updateImgCheckE(imgUploadCheck,documentSnapshot);
                                              return const Padding(
                                                padding: EdgeInsets.all(20.0),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text('Image not yet uploaded.',),
                                                    SizedBox(height: 10,),
                                                    FaIcon(Icons.camera_alt,),
                                                  ],
                                                ),
                                              );
                                            }
                                            if (snapshot.connectionState ==
                                                ConnectionState.done) {
                                              // imgUploadCheck = true;
                                              updateImgCheckE(imgUploadCheck,documentSnapshot);
                                              return Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(
                                                    height: 300,
                                                    width: 300,
                                                    child: snapshot.data,
                                                  ),
                                                ],
                                              );
                                            }
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Container(
                                                child: const CircularProgressIndicator(),);
                                            }
                                            return Container();
                                          }
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10,),

                            const Center(
                              child: Text(
                                'Water Meter Reading Photo',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 5,),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        wMeterNumber = documentSnapshot['water meter number'];
                                        propPhoneNum = documentSnapshot['cell number'];
                                        showDialog(
                                            barrierDismissible: false,
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text("Upload Water Meter"),
                                                content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
                                                actions: [
                                                  IconButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    icon: const Icon(
                                                      Icons.cancel,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () async {
                                                      Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
                                                      Navigator.push(context,
                                                          MaterialPageRoute(builder: (context) => ImageUploadWater(userNumber: propPhoneNum, meterNumber: wMeterNumber,)));
                                                    },
                                                    icon: const Icon(
                                                      Icons.done,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            });
                                      },
                                      labelText: 'Photo',
                                      fSize: 16,
                                      faIcon: const FaIcon(Icons.camera_alt,),
                                      fgColor: Colors.black38,
                                      btSize: const Size(100, 38),
                                    ),
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        _updateW(documentSnapshot);
                                      },
                                      labelText: 'Capture',
                                      fSize: 16,
                                      faIcon: const FaIcon(Icons.edit,),
                                      fgColor: Theme.of(context).primaryColor,
                                      btSize: const Size(100, 38),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            InkWell(
                              ///onTap allows to open image upload page if user taps on the image.
                              ///Can be later changed to display the picture zoomed in if user taps on it.
                              onTap: () {
                                wMeterNumber = documentSnapshot['water meter number'];
                                propPhoneNum = documentSnapshot['cell number'];
                                showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text("Upload Water Meter"),
                                    content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
                                    actions: [
                                      IconButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        icon: const Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
                                          Navigator.push(context,
                                              MaterialPageRoute(builder: (context) => ImageUploadWater(userNumber: propPhoneNum, meterNumber: wMeterNumber,)));
                                        },
                                        icon: const Icon(
                                          Icons.done,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  );
                                });
                              },

                              child: Center(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 5),
                                  // height: 300,
                                  // width: 300,
                                  child: Center(
                                    child: Card(
                                      color: Colors.grey,
                                      semanticContainer: true,
                                      clipBehavior: Clip.antiAliasWithSaveLayer,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                      elevation: 0,
                                      margin: const EdgeInsets.all(10.0),
                                      child: FutureBuilder(
                                          future: _getImageW(
                                            ///Firebase image location must be changed to display image based on the meter number
                                              context, 'files/meters/$formattedDate/$propPhoneNum/water/$wMeterNumber.jpg'),//$meterNumber
                                          builder: (context, snapshot) {
                                            if (snapshot.hasError) {
                                              imgUploadCheck = false;
                                              updateImgCheckW(imgUploadCheck,documentSnapshot);
                                              return const Padding(
                                                padding: EdgeInsets.all(20.0),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text('Image not yet uploaded.',),
                                                    SizedBox(height: 10,),
                                                    FaIcon(Icons.camera_alt,),
                                                  ],
                                                ),
                                              );
                                            }
                                            if (snapshot.connectionState ==
                                                ConnectionState.done) {
                                              // imgUploadCheck = true;
                                              updateImgCheckW(imgUploadCheck,documentSnapshot);
                                              return Container(
                                                height: 300,
                                                width: 300,
                                                child: snapshot.data,
                                              );
                                            }
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Container(
                                                child: const CircularProgressIndicator(),);
                                            }
                                            return Container();
                                          }
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            Text(
                              billMessage,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),

                            const SizedBox(height: 10,),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        Fluttertoast.showToast(
                                            msg: "Now downloading your statement!\nPlease wait a few seconds!");

                                        String accountNumberPDF = documentSnapshot['account number'];
                                        print('The acc number is ::: $accountNumberPDF');

                                        final storageRef = FirebaseStorage.instance.ref().child("pdfs/$formattedDate");
                                        final listResult = await storageRef.listAll();
                                        for (var prefix in listResult.prefixes) {
                                          print('The ref is ::: $prefix');
                                          // The prefixes under storageRef.
                                          // You can call listAll() recursively on them.
                                        }
                                        for (var item in listResult.items) {
                                          print('The item is ::: $item');
                                          // The items under storageRef.
                                          if (item.toString().contains(accountNumberPDF)) {
                                            final url = item.fullPath;
                                            print('The url is ::: $url');
                                            final file = await PDFApi.loadFirebase(url);
                                            try {
                                              if(context.mounted)openPDF(context, file);
                                              Fluttertoast.showToast(
                                                  msg: "Download Successful!");
                                            } catch (e) {
                                              Fluttertoast.showToast(msg: "Unable to download statement.");
                                            }
                                          } else {
                                            Fluttertoast.showToast(msg: "Unable to download statement.");
                                          }
                                        }
                                      },
                                      labelText: 'Invoice',
                                      fSize: 16,
                                      faIcon: const FaIcon(Icons.picture_as_pdf,),
                                      fgColor: Colors.orangeAccent,
                                      btSize: const Size(100, 38),
                                    ),
                                    BasicIconButtonGrey(
                                      onPress: () async {
                                        accountNumberAll = documentSnapshot['account number'];
                                        locationGivenAll = documentSnapshot['address'];


                                        Navigator.push(context,
                                            MaterialPageRoute(builder: (context) => MapScreenProp(propAddress: locationGivenAll, propAccNumber: accountNumberAll,)
                                            ));
                                      },
                                      labelText: 'Map',
                                      fSize: 16,
                                      faIcon: const FaIcon(Icons.map,),
                                      fgColor: Colors.green,
                                      btSize: const Size(100, 38),
                                    ),
                                    const SizedBox(width: 5,),
                                  ],
                                ),
                                const SizedBox(height: 5,),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return null;
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

  Future<void> _create([DocumentSnapshot? documentSnapshot]) async {
    _accountNumberController.text = '';
    _addressController.text = '';
    _areaCodeController.text = '';
    _meterNumberController.text = '';
    _meterReadingController.text = '';
    _waterMeterController.text = '';
    _waterMeterReadingController.text = '';
    _cellNumberController.text = '';
    _firstNameController.text = '';
    _lastNameController.text = '';
    _idNumberController.text = '';

    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery
                      .of(ctx)
                      .viewInsets
                      .bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _areaCodeController,
                      decoration: const InputDecoration(labelText: 'Area Code',),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _meterNumberController,
                      decoration: const InputDecoration(labelText: 'Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _meterReadingController,
                      decoration: const InputDecoration(labelText: 'Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _waterMeterReadingController,
                      decoration: const InputDecoration(labelText: 'Water Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _idNumberController,
                      decoration: const InputDecoration(labelText: 'ID Number'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    child: const Text('Create'),
                    onPressed: () async {
                      final String accountNumber = _accountNumberController.text;
                      final String address = _addressController.text;
                      final String areaCode = _areaCodeController.text;
                      final String meterNumber = _meterNumberController.text;
                      final String meterReading = _meterReadingController.text;
                      final String waterMeterNumber = _waterMeterController.text;
                      final String waterMeterReading = _waterMeterReadingController.text;
                      final String cellNumber = _cellNumberController.text;
                      final String firstName = _firstNameController.text;
                      final String lastName = _lastNameController.text;
                      final String idNumber = _idNumberController.text;
                      if (accountNumber != null) {
                        await _propList.add({
                          "account number": accountNumber,
                          "address": address,
                          "area code": areaCode,
                          "meter number": meterNumber,
                          "meter reading": meterReading,
                          "water meter number": waterMeterNumber,
                          "water meter reading": waterMeterReading,
                          "cell number": cellNumber,
                          "first name": firstName,
                          "last name": lastName,
                          "id number": idNumber
                        });
                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _areaCodeController.text = '';
                        _meterNumberController.text = '';
                        _meterReadingController.text = '';
                        _waterMeterController.text = '';
                        _waterMeterReadingController.text = '';
                        _cellNumberController.text = '';
                        _firstNameController.text = '';
                        _lastNameController.text = '';
                        _idNumberController.text = '';

                        if(context.mounted)Navigator.of(context).pop();
                      }
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  /// on update the only info necessary to change should be meter reading
  Future<void> _update([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _accountNumberController.text = documentSnapshot['account number'];
      _addressController.text = documentSnapshot['address'];
      _areaCodeController.text = documentSnapshot['area code'].toString();
      _meterNumberController.text = documentSnapshot['meter number'];
      _meterReadingController.text = documentSnapshot['meter reading'];
      _waterMeterController.text = documentSnapshot['water meter number'];
      _waterMeterReadingController.text = documentSnapshot['water meter reading'];
      _cellNumberController.text = documentSnapshot['cell number'];
      _firstNameController.text = documentSnapshot['first name'];
      _lastNameController.text = documentSnapshot['last name'];
      _idNumberController.text = documentSnapshot['id number'];
      userID = documentSnapshot['user id'];
    }
    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery
                      .of(ctx)
                      .viewInsets
                      .bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _areaCodeController,
                      decoration: const InputDecoration(labelText: 'Area Code',),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _meterNumberController,
                      decoration: const InputDecoration(labelText: 'Electricity Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _meterReadingController,
                      decoration: const InputDecoration(labelText: 'Electricity Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _waterMeterReadingController,
                      decoration: const InputDecoration(labelText: 'Water Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _idNumberController,
                      decoration: const InputDecoration(labelText: 'ID Number'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    child: const Text('Update'),
                    onPressed: () async {
                      final String accountNumber = _accountNumberController.text;
                      final String address = _addressController.text;
                      final int areaCode = int.parse(_areaCodeController.text);
                      final String meterNumber = _meterNumberController.text;
                      final String meterReading = _meterReadingController.text;
                      final String waterMeterNumber = _waterMeterController.text;
                      final String waterMeterReading = _waterMeterReadingController.text;
                      final String cellNumber = _cellNumberController.text;
                      final String firstName = _firstNameController.text;
                      final String lastName = _lastNameController.text;
                      final String idNumber = _idNumberController.text;

                      if (accountNumber != null) {
                        await _propList
                            .doc(documentSnapshot!.id)
                            .update({
                          "account number": accountNumber,
                          "address": address,
                          "area code": areaCode,
                          "meter number": meterNumber,
                          "meter reading": meterReading,
                          "water meter number": waterMeterNumber,
                          "water meter reading": waterMeterReading,
                          "cell number": cellNumber,
                          "first name": firstName,
                          "last name": lastName,
                          "id number": idNumber,
                          "user id" : userID,
                        });

                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _areaCodeController.text = '';
                        _meterNumberController.text = '';
                        _meterReadingController.text = '';
                        _waterMeterController.text = '';
                        _waterMeterReadingController.text = '';
                        _cellNumberController.text = '';
                        _firstNameController.text = '';
                        _lastNameController.text = '';
                        _idNumberController.text = '';

                        if(context.mounted)Navigator.of(context).pop();
                        ///Added open the image upload straight after inputting the meter reading
                        // if(context.mounted) {
                        //   Navigator.push(context,
                        //       MaterialPageRoute(builder: (context) => ImageUploadMeter(userNumber: cellNumber, meterNumber: meterNumber,)));
                        // }

                      }
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  Future<void> _updateE([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _accountNumberController.text = documentSnapshot['account number'];
      _addressController.text = documentSnapshot['address'];
      _areaCodeController.text = documentSnapshot['area code'].toString();
      _meterNumberController.text = documentSnapshot['meter number'];
      _meterReadingController.text = documentSnapshot['meter reading'];
      _waterMeterController.text = documentSnapshot['water meter number'];
      _waterMeterReadingController.text = documentSnapshot['water meter reading'];
      _cellNumberController.text = documentSnapshot['cell number'];
      _firstNameController.text = documentSnapshot['first name'];
      _lastNameController.text = documentSnapshot['last name'];
      _idNumberController.text = documentSnapshot['id number'];
      userID = documentSnapshot['user id'];
    }
    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery
                      .of(ctx)
                      .viewInsets
                      .bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _areaCodeController,
                      decoration: const InputDecoration(labelText: 'Area Code',),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _meterNumberController,
                      decoration: const InputDecoration(labelText: 'Electricity Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: _meterReadingController,
                      decoration: const InputDecoration(labelText: 'Electricity Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: _waterMeterReadingController,
                      decoration: const InputDecoration(labelText: 'Water Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _idNumberController,
                      decoration: const InputDecoration(labelText: 'ID Number'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    child: const Text('Update'),
                    onPressed: () async {
                      final String accountNumber = _accountNumberController.text;
                      final String address = _addressController.text;
                      final int areaCode = int.parse(_areaCodeController.text);
                      final String meterNumber = _meterNumberController.text;
                      final String meterReading = _meterReadingController.text;
                      final String waterMeterNumber = _waterMeterController.text;
                      final String waterMeterReading = _waterMeterReadingController.text;
                      final String cellNumber = _cellNumberController.text;
                      final String firstName = _firstNameController.text;
                      final String lastName = _lastNameController.text;
                      final String idNumber = _idNumberController.text;

                      if (accountNumber != null) {
                        await _propList
                            .doc(documentSnapshot!.id)
                            .update({
                          "account number": accountNumber,
                          "address": address,
                          "area code": areaCode,
                          "meter number": meterNumber,
                          "meter reading": meterReading,
                          "water meter number": waterMeterNumber,
                          "water meter reading": waterMeterReading,
                          "cell number": cellNumber,
                          "first name": firstName,
                          "last name": lastName,
                          "id number": idNumber,
                          "user id" : userID,
                        });

                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _areaCodeController.text = '';
                        _meterNumberController.text = '';
                        _meterReadingController.text = '';
                        _waterMeterController.text = '';
                        _waterMeterReadingController.text = '';
                        _cellNumberController.text = '';
                        _firstNameController.text = '';
                        _lastNameController.text = '';
                        _idNumberController.text = '';

                        if(context.mounted)Navigator.of(context).pop();
                        ///Added open the image upload straight after inputting the meter reading
                        // if(context.mounted) {
                        //   Navigator.push(context,
                        //       MaterialPageRoute(builder: (context) => ImageUploadMeter(userNumber: cellNumber, meterNumber: meterNumber,)));
                        // }

                      }
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  Future<void> _updateW([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _accountNumberController.text = documentSnapshot['account number'];
      _addressController.text = documentSnapshot['address'];
      _areaCodeController.text = documentSnapshot['area code'].toString();
      _meterNumberController.text = documentSnapshot['meter number'];
      _meterReadingController.text = documentSnapshot['meter reading'];
      _waterMeterController.text = documentSnapshot['water meter number'];
      _waterMeterReadingController.text = documentSnapshot['water meter reading'];
      _cellNumberController.text = documentSnapshot['cell number'];
      _firstNameController.text = documentSnapshot['first name'];
      _lastNameController.text = documentSnapshot['last name'];
      _idNumberController.text = documentSnapshot['id number'];
      userID = documentSnapshot['user id'];
    }
    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery
                      .of(ctx)
                      .viewInsets
                      .bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Street Address'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      controller: _areaCodeController,
                      decoration: const InputDecoration(labelText: 'Area Code',),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _meterNumberController,
                      decoration: const InputDecoration(labelText: 'Electricity Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: _meterReadingController,
                      decoration: const InputDecoration(labelText: 'Electricity Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _waterMeterController,
                      decoration: const InputDecoration(labelText: 'Water Meter Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: _waterMeterReadingController,
                      decoration: const InputDecoration(labelText: 'Water Meter Reading'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _cellNumberController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _idNumberController,
                      decoration: const InputDecoration(labelText: 'ID Number'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    child: const Text('Update'),
                    onPressed: () async {
                      final String accountNumber = _accountNumberController.text;
                      final String address = _addressController.text;
                      final int areaCode = int.parse(_areaCodeController.text);
                      final String meterNumber = _meterNumberController.text;
                      final String meterReading = _meterReadingController.text;
                      final String waterMeterNumber = _waterMeterController.text;
                      final String waterMeterReading = _waterMeterReadingController.text;
                      final String cellNumber = _cellNumberController.text;
                      final String firstName = _firstNameController.text;
                      final String lastName = _lastNameController.text;
                      final String idNumber = _idNumberController.text;

                      if (accountNumber != null) {
                        await _propList
                            .doc(documentSnapshot!.id)
                            .update({
                          "account number": accountNumber,
                          "address": address,
                          "area code": areaCode,
                          "meter number": meterNumber,
                          "meter reading": meterReading,
                          "water meter number": waterMeterNumber,
                          "water meter reading": waterMeterReading,
                          "cell number": cellNumber,
                          "first name": firstName,
                          "last name": lastName,
                          "id number": idNumber,
                          "user id" : userID,
                        });

                        _accountNumberController.text = '';
                        _addressController.text = '';
                        _areaCodeController.text = '';
                        _meterNumberController.text = '';
                        _meterReadingController.text = '';
                        _waterMeterController.text = '';
                        _waterMeterReadingController.text = '';
                        _cellNumberController.text = '';
                        _firstNameController.text = '';
                        _lastNameController.text = '';
                        _idNumberController.text = '';

                        if(context.mounted)Navigator.of(context).pop();
                        ///Added open the image upload straight after inputting the meter reading
                        // if(context.mounted) {
                        //   Navigator.push(context,
                        //       MaterialPageRoute(builder: (context) => ImageUploadMeter(userNumber: cellNumber, meterNumber: waterMeterNumber,)));
                        // }
                      }
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  Future<void> _delete(String users) async {
    await _propList.doc(users).delete();

    if(context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have successfully deleted an account')));
    }
  }

  Future<void> reportGeneration() async {
    final excel.Workbook workbook = excel.Workbook();
    final excel.Worksheet sheet = workbook.worksheets[0];

    // var data = await FirebaseFirestore.instance.collection('properties').get();
    //
    // _allPropertyReport = data.docs;

    String column = "A";
    int row = 0;

    for(var reportSnapshot in _allPropertyReport){
      ///Need to build a property model that retrieves property data entirely from the db
      while(row <= _allPropertyReport.length) {

        var accountNum = reportSnapshot['account number'].toString();
        var address = reportSnapshot['address'].toString();
        var eBill = reportSnapshot['area code'].toString();
        var areaCode = reportSnapshot['eBill'].toString();
        var meterNumber = reportSnapshot['meter number'].toString();
        var meterReading = reportSnapshot['meter reading'].toString();
        var uploadedLatestE = reportSnapshot['imgStateE'].toString();
        var waterMeterNum = reportSnapshot['water meter number'].toString();
        var waterMeterReading = reportSnapshot['water meter reading'].toString();
        var uploadedLatestW = reportSnapshot['imgStatew'].toString();
        var firstName = reportSnapshot['first name'].toString();
        var lastName = reportSnapshot['last name'].toString();
        var idNumber = reportSnapshot['id number'].toString();
        var phoneNumber = reportSnapshot['cell number'].toString();

        sheet.getRangeByName('A$row').setText(accountNum);
        sheet.getRangeByName('B$row').setText(address);
        sheet.getRangeByName('C$row').setText(areaCode);
        sheet.getRangeByName('D$row').setText(eBill);
        sheet.getRangeByName('E$row').setText(meterNumber);
        sheet.getRangeByName('F$row').setText(meterReading);
        sheet.getRangeByName('G$row').setText(uploadedLatestE);
        sheet.getRangeByName('H$row').setText(waterMeterNum);
        sheet.getRangeByName('I$row').setText(waterMeterReading);
        sheet.getRangeByName('J$row').setText(uploadedLatestW);
        sheet.getRangeByName('K$row').setText(firstName);
        sheet.getRangeByName('L$row').setText(lastName);
        sheet.getRangeByName('M$row').setText(idNumber);
        sheet.getRangeByName('N$row').setText(phoneNumber);

        // const Center(
        //   child: Padding(
        //     padding: EdgeInsets.all(5.0),
        //     child: CircularProgressIndicator(),
        //   ),);

        row+=1;
      }
    }

    final Directory? directory = await getExternalStorageDirectory();
    //Get directory path
    final String? path = directory?.path;
    //Create an empty file to write Excel data
    final File file = File('$path/Msunduzi Property Reports.xlsx');

    final List<int> bytes = workbook.saveAsStream();
    //Write Excel data
    await file.writeAsBytes(bytes, flush: true);
    //Launch the file (used open_file package)
    await OpenFile.open('$path/Msunduzi Property Reports.xlsx');

    File('Msunduzi Property Reports.xlsx').writeAsBytes(bytes);

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