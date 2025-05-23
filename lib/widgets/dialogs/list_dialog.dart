import 'package:flutter/material.dart';

class ListDialog extends StatefulWidget {
  final VoidCallback? onDislikeRestaurant;
  final VoidCallback? onDislikeCuisine;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  const ListDialog({
    super.key,
    this.onDislikeRestaurant,
    this.onDislikeCuisine,
    this.onCancel,
    this.onConfirm,
  });

  @override
  State<ListDialog> createState() => _ListDialogState();
}

class _ListDialogState extends State<ListDialog> {
  bool _isRestaurantSelected = false;
  bool _isCuisineSelected = false;

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
          const Text(
            'A dialog is a type of modal window that appears in front of app content to provide critical information, or prompt for a decision to be made.',
            style: TextStyle(
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
          icon: 'R',
          title: 'Dislike this restaurant',
          isSelected: _isRestaurantSelected,
          onTap: () {
            setState(() {
              _isRestaurantSelected = !_isRestaurantSelected;
            });
            widget.onDislikeRestaurant?.call();
          },
        ),
        _buildOption(
          icon: 'C',
          title: 'Dislike this cuisine',
          isSelected: _isCuisineSelected,
          onTap: () {
            setState(() {
              _isCuisineSelected = !_isCuisineSelected;
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
                child: Text(
                  icon,
                  style: const TextStyle(
                    color: Color(0xFF4F378A),
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                    height: 1.50,
                    letterSpacing: 0.15,
                  ),
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