import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen_prop.dart';

import '../Reusable/icon_elevated_button.dart';

class FaultTaskScreenArchive extends StatefulWidget {
  const FaultTaskScreenArchive({Key? key}) : super(key: key);

  @override
  State<FaultTaskScreenArchive> createState() => _FaultTaskScreenArchiveState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
final email = user?.email;
String userID = uid as String;
String userEmail = email as String;

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier{
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async{
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

class _FaultTaskScreenArchiveState extends State<FaultTaskScreenArchive> {

  @override
  void initState() {
    if(_searchController.text == ""){
      getFaultStream();
    }
    _searchController.addListener(_onSearchChanged);
    checkRole();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    searchText;
    getFaultStream();
    searchResultsList();
    super.dispose();
  }

  final _accountNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _commentController = TextEditingController();
  final _deptHandlerController = TextEditingController();
  final _depAllocationController = TextEditingController();
  late bool _faultResolvedController;
  final _dateReportedController = TextEditingController();

  final CollectionReference _faultData =
  FirebaseFirestore.instance.collection('faultReporting');

  String accountNumberRep = '';
  String locationGivenRep = '';
  int faultStage = 0;
  String reporterCellGiven = '';
  String searchText = '';

  String userRole = '';
  List _allUserRolesResults = [];
  bool visShow = true;
  bool visHide = false;
  bool cardShow1 = true;

  bool adminAcc = false;
  bool managerAcc = false;
  bool employeeAcc = false;
  bool visStage1 = false;
  bool visStage2 = false;
  bool visStage3 = false;
  bool visStage4 = false;
  bool visStage5 = false;

  final CollectionReference _listUser =
  FirebaseFirestore.instance.collection('users');

  User? user = FirebaseAuth.instance.currentUser;

  TextEditingController _searchController = TextEditingController();
  List _resultsList =[];
  List _allFaultResults = [];

  getFaultStream() async{
    var data = await FirebaseFirestore.instance.collection('faultReporting').orderBy('dateReported', descending: true).get();

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
        var address = faultSnapshot['address'].toString().toLowerCase();

        if(address.contains(_searchController.text.toLowerCase())) {
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

  void checkRole() {
    getUsersStream();
    if(userRole == 'Admin'|| userRole == 'Administrator'){
      adminAcc = true;
      managerAcc = false;
      employeeAcc = false;
    } else if(userRole == 'Manager'){
      adminAcc = false;
      managerAcc = true;
      employeeAcc = false;
    } else {
      adminAcc = false;
      managerAcc = false;
      employeeAcc = true;
    }
  }

  getUsersStream() async{
    var data = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      _allUserRolesResults = data.docs;
    });
    getUserDetails();
  }

  getUserDetails() async {
    for (var userSnapshot in _allUserRolesResults) {
      ///Need to build a property model that retrieves property data entirely from the db
      var user = userSnapshot['email'].toString();
      var role = userSnapshot['userRole'].toString();

      if (user == userEmail) {
        userRole = role;
        print('My Role is::: $userRole');

        if (userRole == 'Admin' || userRole == 'Administrator') {
          adminAcc = true;
        } else {
          adminAcc = false;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Fault Reports Archive',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        // actions: <Widget>[
        //   Visibility(
        //       visible: adminAcc,
        //       child:
        //       IconButton(
        //           onPressed: (){
        //
        //           },
        //           icon: const Icon(Icons.hourglass_bottom, color: Colors.white,)),),
        // ],
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
                  print('this is the input text ::: $searchText');
                });
              },
            ),
          ),
          /// Search bar end

          ///made the listview card a reusable widget
          // firebaseFaultCard(_faultData),

          Expanded(child: faultCard(),),

          const SizedBox(height: 5,),
        ],
      ),
    );
  }

  //this widget is for displaying the fault report list all together
  Widget faultCard(){
    if (_allFaultResults.isNotEmpty) {
      return ListView.builder(
        itemCount: _allFaultResults.length,
        itemBuilder: (context, index) {

          String status;
          if (_allFaultResults[index]['faultResolved'] == false) {
            status = "Pending";
          } else {
            status = "Completed";
          }

          if (_allFaultResults[index]['faultResolved'] == true) {
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
                        if(_allFaultResults[index]['faultDescription'] != "")...[
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
                        if(_allFaultResults[index]['adminComment'] != "")...[
                          Text(
                            'Admin Comment: ${_allFaultResults[index]['adminComment']}',
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
                      'Resolve State: $status',
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
          } else {
            return const SizedBox();
          }


        },
      );
    }
    return const Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(
          child: CircularProgressIndicator()),
    );

  }

  Future<Widget> _getImage(BuildContext context, String imageName) async{
    Image image;
    final value = await FireStorageService.loadImage(context, imageName);
    image =Image.network(
      value.toString(),
      fit: BoxFit.fill,
    );
    return image;
  }

  //this widget is for displaying a property field of information with an icon next to it, NB. the icon is to make it look good
  //it is called within a listview page widget
  Widget faultItemField(String faultDat) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8,),
      child: Row(
        children: [
          const SizedBox(width: 6,),
          Text(
            faultDat,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  //this widget is for displaying the fault report list all together
  Widget firebaseFaultCard(CollectionReference<Object?> faultDataStream){
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: faultDataStream.orderBy('dateReported', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];

                if(((documentSnapshot['address'].trim()).toLowerCase()).contains((_searchController.text.trim()).toLowerCase())){
                  if(streamSnapshot.data!.docs[index]['faultResolved'] == true || documentSnapshot['faultStage'] >= 5){
                    return Card(
                      margin: const EdgeInsets.fromLTRB(10.0,0.0,10.0,10.0),
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
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            Column(
                              children: [
                                if(documentSnapshot['accountNumber'] != "")...[
                                  Text(
                                    'Reporter Account Number: ${documentSnapshot['accountNumber']}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5,),
                                ] else ...[

                                ],
                              ],
                            ),
                            Text(
                              'Street Address of Fault: ${documentSnapshot['address']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Fault Type: ${documentSnapshot['faultType']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Column(
                              children: [
                                if(documentSnapshot['faultDescription'] != "")...[
                                  Text(
                                    'Fault Description: ${documentSnapshot['faultDescription']}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5,),
                                ] else ...[

                                ],
                              ],
                            ),
                            Column(
                              children: [
                                if(documentSnapshot['handlerCom1'] != "")...[
                                  Text(
                                    'Handler Comment: ${documentSnapshot['handlerCom1']}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5,),
                                ] else ...[

                                ],
                              ],
                            ),
                            Column(
                              children: [
                                if(documentSnapshot['adminComment'] != "")...[
                                  Text(
                                    'Admin Comment: ${documentSnapshot['adminComment']}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5,),
                                ] else ...[

                                ],
                              ],
                            ),
                            Column(
                              children: [
                                if(documentSnapshot['handlerCom2'] != "")...[
                                  Text(
                                    'Handler Final Comment: ${documentSnapshot['handlerCom2']}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5,),
                                ] else ...[

                                ],
                              ],
                            ),
                            Column(
                              children: [
                                if(documentSnapshot['depComment2'] != "")...[
                                  Text(
                                    'Department Final Comment: ${documentSnapshot['depComment2']}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5,),
                                ] else ...[

                                ],
                              ],
                            ),
                            Text(
                              'Resolve State: ${documentSnapshot['faultResolved'].toString()}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              'Date of Fault Report: ${documentSnapshot['dateReported']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            InkWell(
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 5),
                                height: 180,
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
                                          ///Firebase image location must be changed to display image based on the address
                                            context, 'files/faultImages/${documentSnapshot['dateReported']}/${documentSnapshot['address']}'),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasError) {
                                            return const Padding(
                                              padding: EdgeInsets.all(20.0),
                                              child: Text('Image not uploaded for Fault.',),
                                            ); //${snapshot.error} if error needs to be displayed instead
                                          }
                                          if (snapshot.connectionState ==
                                              ConnectionState.done) {
                                            return Container(
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
                            const SizedBox(height: 20,),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        accountNumberRep = documentSnapshot['accountNumber'];
                                        locationGivenRep = documentSnapshot['address'];

                                        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        //     content: Text('$accountNumber $locationGiven ')));

                                        Navigator.push(context,
                                            MaterialPageRoute(
                                                builder: (context) => MapScreenProp(propAddress: locationGivenRep, propAccNumber: accountNumberRep,)
                                            ));
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[350],
                                        fixedSize: const Size(160, 10),),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.map,
                                            color: Colors.green[700],
                                          ),
                                          const SizedBox(width: 2,),
                                          const Text('Location', style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,),),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 5,),
                                    ElevatedButton(
                                      onPressed: () {
                                        faultStage = documentSnapshot['faultStage'];
                                        _updateReport(documentSnapshot);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[350],
                                        fixedSize: const Size(110, 10),),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                          const SizedBox(width: 2,),
                                          const Text('Update', style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,),),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 5,),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) {
                                          return
                                            AlertDialog(
                                              shape: const RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius.all(Radius.circular(16))),
                                              title: const Text("Call Reporter!"),
                                              content: const Text(
                                                  "Would you like to call the individual who logged the fault?"),
                                              actions: [
                                                IconButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  icon: const Icon(
                                                    Icons.cancel,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    reporterCellGiven = documentSnapshot['reporterContact'];

                                                    final Uri _tel = Uri.parse('tel:${reporterCellGiven.toString()}');
                                                    launchUrl(_tel);

                                                    Navigator.of(context).pop();
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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[350],
                                    fixedSize: const Size(150, 10),),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.call,
                                        color: Colors.orange[700],
                                      ),
                                      const SizedBox(width: 2,),
                                      const Text('Call Reporter', style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,),),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5,),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox();
                  }
                }
              },
            );
          } else {
            return const Padding(
              padding: EdgeInsets.all(10.0),
              child: Center(
                  child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }

  //This class is for updating the report stages by the manager and the handler to comment through phases of the report
  Future<void> _updateReport([DocumentSnapshot? documentSnapshot]) async {

    String dropdownValue = 'Electricity';
    int stageNum = documentSnapshot!['faultStage'];

    if (stageNum == 1) {
      visStage1 = true;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 2) {
      visStage1 = false;
      visStage2 = true;
      visStage3 = false;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 3) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = true;
      visStage4 = false;
      visStage5 = false;
    } else if (stageNum == 4) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = true;
      visStage5 = false;
    } else if (stageNum == 5) {
      visStage1 = false;
      visStage2 = false;
      visStage3 = false;
      visStage4 = false;
      visStage5 = true;
    }

    if (documentSnapshot != null) {
      _accountNumberController.text = documentSnapshot['accountNumber'];
      _addressController.text = documentSnapshot['address'];
      _descriptionController.text = documentSnapshot['faultDescription'];
      _commentController.text = '';
      _depAllocationController.text = documentSnapshot['depAllocated'];
      _faultResolvedController = documentSnapshot['faultResolved'];
      _dateReportedController.text = documentSnapshot['dateReported'];
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async{
      showModalBottomSheet(
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
                              visible: visStage1,
                              child: const Text('Department Allocation'),
                            ),
                            Visibility(
                              visible: visStage1,
                              child: DropdownButtonFormField <String>(
                                value: dropdownValue,
                                items: <String>['Electricity', 'Water & Sanitation', 'Roadworks', 'Waste Management']
                                    .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    dropdownValue = newValue!;
                                  });
                                },
                              ),
                            ),
                            Visibility(
                              visible: visStage1,
                              child: TextField(
                                keyboardType: TextInputType.text,
                                controller: _deptHandlerController,
                                decoration: const InputDecoration(
                                  labelText: 'Handler User Allocation',),
                              ),
                            ),
                            Visibility(
                              visible: visShow,
                              child: TextField(
                                keyboardType: TextInputType.text,
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  labelText: 'Comment to Department',),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            Visibility(
                              visible: visStage5,
                              child: const Text('Re-open Fault'),
                            ),
                            Visibility(
                              visible: visStage3 || visStage4 || visStage5,
                              child:
                              Container(
                                height: 50,
                                padding: const EdgeInsets.only(left: 0.0, right: 25.0),
                                child: Row(
                                  children: <Widget>[
                                    const Text('Fault Resolved?', style: TextStyle(fontSize: 16, fontWeight:FontWeight.w400 ),),
                                    const SizedBox(width: 5,),
                                    Checkbox(
                                      checkColor: Colors.white,
                                      fillColor: MaterialStateProperty.all<Color>(
                                          Colors.green),
                                      value: _faultResolvedController,
                                      onChanged: (bool? value) async {
                                        setState(() {
                                          _faultResolvedController = value!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            ElevatedButton(
                              child: const Text('Update'),
                              onPressed: () async {
                                final String reporterNumber = documentSnapshot['reporterContact'];
                                final String userComment = _commentController.text;
                                final String deptUserAllocated = _deptHandlerController.text;
                                final String depSelected = dropdownValue;
                                final bool faultResolved = _faultResolvedController;

                                if (faultStage == 1) {
                                  if (reporterNumber != null) {
                                    if(_deptHandlerController.text != '' || _deptHandlerController.text.isNotEmpty){
                                      await _faultData
                                          .doc(documentSnapshot.id)
                                          .update({
                                        "depComment1": userComment,
                                        "depAllocated": depSelected,
                                        "deptHandler": deptUserAllocated,
                                        "faultStage": 2,
                                      });
                                    } else {

                                      Fluttertoast.showToast(msg: 'Please Assign Handler to the Fault Before Continuing', gravity: ToastGravity.CENTER);
                                    }
                                  }
                                  _accountNumberController.text = '';
                                  _addressController.text = '';
                                  _accountNumberController.text = '';
                                  _addressController.text = '';
                                  _commentController.text = '';
                                  _depAllocationController.text = '';
                                  dropdownValue = '';
                                  _faultResolvedController = false;
                                  _dateReportedController.text = '';

                                  visStage1 = false;
                                  visStage2 = false;
                                  visStage3 = false;
                                  visStage4 = false;
                                  visStage5 = false;

                                  if(context.mounted)Navigator.of(context).pop();

                                } else if (faultStage == 2) {
                                  if (reporterNumber != null) {
                                    await _faultData
                                        .doc(documentSnapshot.id)
                                        .update({
                                      "handlerCom1": userComment,
                                      "faultStage": 3,
                                    });
                                  }
                                  _accountNumberController.text = '';
                                  _addressController.text = '';
                                  _accountNumberController.text = '';
                                  _addressController.text = '';
                                  _commentController.text = '';
                                  _depAllocationController.text = '';
                                  dropdownValue = '';
                                  _faultResolvedController = false;
                                  _dateReportedController.text = '';

                                  visStage1 = false;
                                  visStage2 = false;
                                  visStage3 = false;
                                  visStage4 = false;
                                  visStage5 = false;

                                  Navigator.of(context).pop();

                                } else if (faultStage == 3) {
                                  if (reporterNumber != null) {
                                    await _faultData
                                        .doc(documentSnapshot.id)
                                        .update({
                                      "depComment2": userComment,
                                      "faultResolved": faultResolved,
                                      "faultStage": 4,
                                    });
                                  }
                                  _accountNumberController.text = '';
                                  _addressController.text = '';
                                  _accountNumberController.text = '';
                                  _addressController.text = '';
                                  _commentController.text = '';
                                  _depAllocationController.text = '';
                                  dropdownValue = '';
                                  _faultResolvedController = false;
                                  _dateReportedController.text = '';

                                  visStage1 = false;
                                  visStage2 = false;
                                  visStage3 = false;
                                  visStage4 = false;
                                  visStage5 = false;

                                  if(context.mounted)Navigator.of(context).pop();

                                } else if (faultStage == 5) {
                                  if (reporterNumber != null) {
                                    await _faultData
                                        .doc(documentSnapshot.id)
                                        .update({
                                      "depComment1": userComment,
                                      "faultResolved": faultResolved,
                                      "faultStage": 1,
                                    });
                                  }
                                  _accountNumberController.text = '';
                                  _addressController.text = '';
                                  _accountNumberController.text = '';
                                  _addressController.text = '';
                                  _commentController.text = '';
                                  _depAllocationController.text = '';
                                  dropdownValue = '';
                                  _faultResolvedController = false;
                                  _dateReportedController.text = '';

                                  visStage1 = false;
                                  visStage2 = false;
                                  visStage3 = false;
                                  visStage4 = false;
                                  visStage5 = false;

                                  if(context.mounted)Navigator.of(context).pop();

                                } else if (faultStage == 4) {
                                  if (reporterNumber != null) {
                                    await _faultData
                                        .doc(documentSnapshot.id)
                                        .update({
                                      "handlerCom2": userComment,
                                      "faultResolved": faultResolved,
                                      "faultStage": 5,
                                    });
                                  }
                                  _accountNumberController.text = '';
                                  _addressController.text = '';
                                  _accountNumberController.text = '';
                                  _addressController.text = '';
                                  _commentController.text = '';
                                  _depAllocationController.text = '';
                                  dropdownValue = '';
                                  _faultResolvedController = false;
                                  _dateReportedController.text = '';

                                  visStage1 = false;
                                  visStage2 = false;
                                  visStage3 = false;
                                  visStage4 = false;
                                  visStage5 = false;

                                  if(context.mounted)Navigator.of(context).pop();

                                }

                              },
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

}
