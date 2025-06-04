import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class MapPopup extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String? restaurantName;
  final VoidCallback? onAppleMapSelected;
  final VoidCallback? onGoogleMapSelected;

  const MapPopup({
    super.key,
    this.latitude,
    this.longitude,
    this.restaurantName,
    this.onAppleMapSelected,
    this.onGoogleMapSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    return Container(
      padding: const EdgeInsets.only(
        top: 20,
        left: 10,
        right: 10,
        bottom: 10,
      ),
      decoration: const ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isIOS)
            _buildOption(
              title: 'Apple Map',
              onTap: () async {
                Navigator.pop(context);
                if (onAppleMapSelected != null) {
                  onAppleMapSelected!();
                } else if (latitude != null && longitude != null) {
                  await _launchAppleMaps();
                }
              },
            ),
          _buildOption(
            title: 'Google Map',
            onTap: () async {
              Navigator.pop(context);
              if (onGoogleMapSelected != null) {
                onGoogleMapSelected!();
              } else if (latitude != null && longitude != null) {
                await _launchGoogleMaps();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _launchAppleMaps() async {
    final name = restaurantName ?? 'Restaurant';
    final url = 'http://maps.apple.com/?q=${Uri.encodeComponent(name)}&ll=$latitude,$longitude';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchGoogleMaps() async {
    final name = restaurantName ?? 'Restaurant';
    final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(name)}&center=$latitude,$longitude';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildOption({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFF5F5F5),
              width: 1,
            ),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              height: 1.43,
              letterSpacing: 0.10,
            ),
          ),
        ),
      ),
    );
  }
}