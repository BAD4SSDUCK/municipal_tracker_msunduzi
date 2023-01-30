import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:municipal_track/code/Users/fragments/home_fragment_screen.dart';
import 'package:municipal_track/code/Users/fragments/photo_fragment_screen.dart';
import 'package:municipal_track/code/Users/fragments/profile_fragment_screen.dart';
import 'package:municipal_track/code/Users/fragments/property_fragment_screen.dart';
import 'package:municipal_track/code/Users/userPreferences/current_user.dart';
import 'package:municipal_track/code/login/citizen_otp_page.dart';

///This dashboard is only for testing and will in the future use the firebase dashboard already built but with the sql connection instead
///I may use this dashboard if the design is better but input all the build pages in the fragment screens

class DashboardOfFragments extends StatelessWidget {

  CurrentUser _rememberCurrentUser = Get.put(CurrentUser());

  List<Widget> _fragmentScreens =[
    HomeFragmentScreen(),
    PropertyFragmentScreen(),
    PhotoFragmentScreen(),
    RegisterScreen(),//for the chat we will still used firebase because it is the easist for tracking chats so the user will just otp login to firebase
    ProfileFragmentScreen(),
  ];

  List _navigationButtonsPropterties =[
    {
      "active_icon": Icons.home,
      "non_active_icon": Icons.home_outlined,
      "label": "Home",
    },
    {
      "active_icon": Icons.house,
      "non_active_icon": Icons.home_outlined,
      "label": "Properties",
    },
    {
      "active_icon": Icons.camera_alt,
      "non_active_icon": Icons.camera_alt_outlined,
      "label": "Upload",
    },
    {
      "active_icon": Icons.chat_bubble,
      "non_active_icon": Icons.chat_bubble_outline,
      "label": "Chat",
    },
    {
      "active_icon": Icons.person,
      "non_active_icon": Icons.person_outline,
      "label": "Profile",
    },
  ];

  RxInt _indexNumber = 0.obs;


  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: CurrentUser(),
      initState: (currentState) {
        _rememberCurrentUser.getUserInfo();
      },
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.grey,
          body: SafeArea(
            child: Obx(
                ()=> _fragmentScreens[_indexNumber.value],
            ),
          ),
          bottomNavigationBar: Obx(
              ()=> BottomNavigationBar(
                  currentIndex: _indexNumber.value,
                onTap: (value){
                    _indexNumber.value = value;
                },
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white10,
                items: List.generate(5, (index) {
                  var navBtnProperty = _navigationButtonsPropterties[index];
                  return BottomNavigationBarItem(
                      backgroundColor: Colors.black,
                      icon: Icon(navBtnProperty["non_active_icon"]),
                      activeIcon: Icon(navBtnProperty["active_icon"]),
                      label: navBtnProperty["label"],
                  );
                }),
              ),
          ),

        );
      },
    );
  }
}