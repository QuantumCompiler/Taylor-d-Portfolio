import '../Profile/ProfileUtils.dart';

Profile myProfile = Profile(name: 'FlurdBop');

void main() {
  print(myProfile.name);
  print(myProfile.education);
  myProfile.name = 'Flurd Bopping';
  myProfile.education = 'Education';
  print(myProfile.name);
  print(myProfile.education);
}
