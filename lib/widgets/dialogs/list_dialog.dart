import 'package:flutter/material.dart';
import '../../repositories/user_preference_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListDialog extends StatefulWidget {
  final VoidCallback? onLikeRestaurant;
  final VoidCallback? onDislikeRestaurant;
  final VoidCallback? onLikeCuisine;
  final VoidCallback? onDislikeCuisine;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final bool initialRestaurantLiked;
  final bool initialRestaurantDisliked;
  final bool initialCuisineLiked;
  final bool initialCuisineDisliked;
  final String description;

  const ListDialog({
    super.key,
    this.onLikeRestaurant,
    this.onDislikeRestaurant,
    this.onLikeCuisine,
    this.onDislikeCuisine,
    this.onCancel,
    this.onConfirm,
    this.initialRestaurantLiked = false,
    this.initialRestaurantDisliked = false,
    this.initialCuisineLiked = false,
    this.initialCuisineDisliked = false,
    this.description = '',
  });

  @override
  State<ListDialog> createState() => _ListDialogState();
}

class _ListDialogState extends State<ListDialog> {
  late bool _isRestaurantLiked;
  late bool _isRestaurantDisliked;
  late bool _isCuisineLiked;
  late bool _isCuisineDisliked;

  @override
  void initState() {
    super.initState();
    _isRestaurantLiked = widget.initialRestaurantLiked;
    _isRestaurantDisliked = widget.initialRestaurantDisliked;
    _isCuisineLiked = widget.initialCuisineLiked;
    _isCuisineDisliked = widget.initialCuisineDisliked;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: 560,
        ),
        child: SizedBox(
          width: 333,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildOptions(),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Action',
            style: TextStyle(
              color: Color(0xFF1D1B20),
              fontSize: 24,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.description.isNotEmpty
                ? widget.description
                : 'A dialog is a type of modal window that appears in front of app content to provide critical information, or prompt for a decision to be made.',
            style: const TextStyle(
              color: Color(0xFF49454F),
              fontSize: 14,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
              height: 1.43,
              letterSpacing: 0.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Column(
      children: [
        _buildOption(
          icon: 'Icons.favorite',
          title: 'Like this restaurant',
          isSelected: _isRestaurantLiked,
          onTap: () {
            setState(() {
              _isRestaurantLiked = !_isRestaurantLiked;
              if (_isRestaurantLiked) {
                _isRestaurantDisliked = false; // 互斥：如果喜欢就不能不喜欢
              }
            });
            widget.onLikeRestaurant?.call();
          },
        ),
        _buildOption(
          icon: 'Icons.favorite_border',
          title: 'Dislike this restaurant',
          isSelected: _isRestaurantDisliked,
          onTap: () {
            setState(() {
              _isRestaurantDisliked = !_isRestaurantDisliked;
              if (_isRestaurantDisliked) {
                _isRestaurantLiked = false; // 互斥：如果不喜欢就不能喜欢
              }
            });
            widget.onDislikeRestaurant?.call();
          },
        ),
        _buildOption(
          icon: 'Icons.restaurant',
          title: 'Like this cuisine',
          isSelected: _isCuisineLiked,
          onTap: () {
            setState(() {
              _isCuisineLiked = !_isCuisineLiked;
              if (_isCuisineLiked) {
                _isCuisineDisliked = false; // 互斥：如果喜欢就不能不喜欢
              }
            });
            widget.onLikeCuisine?.call();
          },
        ),
        _buildOption(
          icon: 'Icons.no_meals',
          title: 'Dislike this cuisine',
          isSelected: _isCuisineDisliked,
          onTap: () {
            setState(() {
              _isCuisineDisliked = !_isCuisineDisliked;
              if (_isCuisineDisliked) {
                _isCuisineLiked = false; // 互斥：如果不喜欢就不能喜欢
              }
            });
            widget.onDislikeCuisine?.call();
          },
        ),
      ],
    );
  }

  Widget _buildOption({
    required String icon,
    required String title,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFCAC4D0),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Center(
                child: Icon(
                  icon == 'Icons.favorite' ? Icons.favorite :
                  icon == 'Icons.favorite_border' ? Icons.favorite_border :
                  icon == 'Icons.restaurant' ? Icons.restaurant :
                  icon == 'Icons.no_meals' ? Icons.no_meals :
                  Icons.circle,
                  size: 16,
                  color: const Color(0xFF4F378A),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1D1B20),
                  fontSize: 16,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  height: 1.50,
                  letterSpacing: 0.50,
                ),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: ShapeDecoration(
                color: isSelected ? const Color(0xFFE95322) : const Color(0xFFF5F5F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: isSelected
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  )
                : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: 24,
        left: 16,
        right: 24,
        bottom: 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onCancel?.call();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
                height: 1.43,
                letterSpacing: 0.10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onConfirm?.call();
            },
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
                height: 1.43,
                letterSpacing: 0.10,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 