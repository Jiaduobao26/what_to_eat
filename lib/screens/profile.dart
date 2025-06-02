import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/authentication_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/user_preference_repository.dart';
import '../models/preference.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditDialog(BuildContext context, String currentName) {
    final nameController = TextEditingController(text: currentName);
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'New Password (optional)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (passwordController.text.isNotEmpty && value != passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // Update Firestore
                    await FirebaseFirestore.instanceFor(
                      app: FirebaseFirestore.instance.app,
                      databaseId: 'userinfo',
                    ).collection('userinfo').doc(user.uid).update({
                      'name': nameController.text,
                    });

                    // updateirebaseAuth displayName
                    await user.updateDisplayName(nameController.text);

                    // Update password if provided
                    if (passwordController.text.isNotEmpty) {
                      await user.updatePassword(passwordController.text);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated successfully')),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating profile: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authState = context.watch<AuthenticationBloc>().state;
    final isGuest = authState.isGuest;
    return Scaffold(
      backgroundColor: Colors.white, 
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'My profile',
              style: TextStyle(
                color: Colors.black,
                fontSize: 34,
                fontFamily: 'SF Pro Text',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            if (!isGuest && user != null) ...[
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instanceFor(
                  app: FirebaseFirestore.instance.app,
                  databaseId: 'userinfo',
                ).collection('userinfo').doc(user.uid).snapshots(),
                builder: (context, snapshot) {
                  String name = user.displayName ?? 'User Name';
                  String email = user.email ?? 'user@email.com';
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data != null) {
                      name = data['name'] as String? ?? name;
                      email = data['email'] as String? ?? email;
                    }
                  }
                  return _ProfileHeader(name: name, email: email);
                },
              ),
            ] else ...[
              _ProfileHeader(
                name: 'Anonymous',
                email: 'anonymous@email.com',
              ),
            ],
            const SizedBox(height: 32),
            if (!isGuest) ...[
              _ProfileItem(
                title: 'Personal details',
                trailing: 'change',
                onTap: () {
                  final nameFuture = (FirebaseFirestore.instanceFor(
                    app: FirebaseFirestore.instance.app,
                    databaseId: 'userinfo',
                  ).collection('userinfo').doc(user?.uid).get() as Future<DocumentSnapshot>)
                      .then((doc) => doc.get('name') as String? ?? 'User Name');
                  nameFuture.then((currentName) => _showEditDialog(context, currentName));
                },
              ),
              const SizedBox(height: 16),
            ],
            _ProfileItem(
              title: 'Preference',
              trailing: 'manage',
              onTap: () {
                try {
                  print('Attempting to navigate to /preference-manage');
                  context.push('/preference-manage');
                } catch (e) {
                  print('Navigation error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Navigation error: $e')),
                  );
                }
              },            ),            const SizedBox(height: 16),
            _ProfileItem(title: 'History'),
            const SizedBox(height: 16),
            _ProfileItem(title: 'Help'),
            const Spacer(),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFA270C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                onPressed: () {
                  context.read<AuthenticationBloc>().add(AuthenticationLogoutRequested());
                  GoRouter.of(context).go('/login');
                },
                child: Text(isGuest ? 'Log In' : 'Logout', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  
  const _ProfileItem({
    required this.title,
    this.trailing,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0x07000000),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(
                  color: Color(0xFFFA4A0C),
                  fontSize: 15,
                  fontFamily: 'SF Pro Text',
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  
  const _ProfileHeader({
    required this.name,
    required this.email,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: const SizedBox(
            width: 91,
            height: 100,
            child: Icon(Icons.image, size: 60, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: 0.5,
              child: Text(
                email,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'SF Pro Text',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}