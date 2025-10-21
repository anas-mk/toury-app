// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../cubit/auth_cubit.dart';
// import '../cubit/auth_state.dart';
// import 'login_page.dart';
//
// class ProfilePage extends StatefulWidget {
//   const ProfilePage({super.key});
//
//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }
//
// class _ProfilePageState extends State<ProfilePage> {
//   @override
//   void initState() {
//     super.initState();
//     // Load current user data when page opens
//     context.read<AuthCubit>().getCurrentUser();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile'),
//         actions: [
//           IconButton(
//             onPressed: () => _showLogoutDialog(context),
//             icon: const Icon(Icons.logout),
//             tooltip: 'Logout',
//           ),
//         ],
//       ),
//       body: BlocConsumer<AuthCubit, AuthState>(
//         listener: (context, state) {
//           if (state is AuthError) {
//             ScaffoldMessenger.of(
//               context,
//             ).showSnackBar(SnackBar(content: Text(state.message)));
//           } else if (state is AuthUnauthenticated) {
//             Navigator.pushAndRemoveUntil(
//               context,
//               MaterialPageRoute(builder: (_) => const LoginPage()),
//               (route) => false,
//             );
//           }
//         },
//         builder: (context, state) {
//           if (state is AuthLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (state is AuthAuthenticated) {
//             return _buildProfileContent(state.user);
//           }
//
//           return const Center(child: Text('No user data available'));
//         },
//       ),
//     );
//   }
//
//   Widget _buildProfileContent(user) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Profile Header
//           Center(
//             child: Column(
//               children: [
//                 CircleAvatar(
//                   radius: 50,
//                   backgroundColor: Colors.blue,
//                   child: Text(
//                     user.userName.isNotEmpty
//                         ? user.userName[0].toUpperCase()
//                         : 'U',
//                     style: const TextStyle(
//                       fontSize: 32,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   user.userName,
//                   style: const TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   user.email,
//                   style: const TextStyle(fontSize: 16, color: Colors.grey),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 32),
//
//           // Profile Information
//           const Text(
//             'Profile Information',
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 16),
//
//           _buildInfoCard([
//             _buildInfoRow('Email', user.email),
//             _buildInfoRow('Username', user.userName),
//             _buildInfoRow('Phone', user.phoneNumber),
//             _buildInfoRow('Gender', user.gender),
//             _buildInfoRow('Country', user.country),
//             if (user.birthDate != null)
//               _buildInfoRow(
//                 'Birth Date',
//                 '${user.birthDate!.day}/${user.birthDate!.month}/${user.birthDate!.year}',
//               ),
//           ]),
//
//           const SizedBox(height: 32),
//
//           // Action Buttons
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton.icon(
//               onPressed: () => _showLogoutDialog(context),
//               icon: const Icon(Icons.logout),
//               label: const Text('Logout'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInfoCard(List<Widget> children) {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(children: children),
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 100,
//             child: Text(
//               label,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey,
//               ),
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
//         ],
//       ),
//     );
//   }
//
//   void _showLogoutDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Logout'),
//           content: const Text('Are you sure you want to logout?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 context.read<AuthCubit>().logout();
//               },
//               child: const Text('Logout'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
